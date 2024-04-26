
#Creating a bucket
resource "aws_s3_bucket" "Static-Bucket" {
  bucket = "cdn-web-pro-23"
}

#creating Ownership control for the bucket
resource "aws_s3_bucket_ownership_controls" "Rule1" {
  bucket = aws_s3_bucket.Static-Bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# giving public access to the bucket

resource "aws_s3_bucket_public_access_block" "Rule2" {
  bucket                  = aws_s3_bucket.Static-Bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

#Access control list for the bucket 

resource "aws_s3_bucket_acl" "Rule3" {
  depends_on = [aws_s3_bucket_ownership_controls.Rule1]
  bucket     = aws_s3_bucket.Static-Bucket.id
  acl        = "public-read"
}

# making bucket policy for the bucket that's how able to seee the wesite perfectly 

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.Static-Bucket.id

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "AddPerm",
          "Effect" : "Allow",
          "Principal" : "*",
          "Action" : "s3:GetObject",
          "Resource" : "arn:aws:s3:::CDN-Web-Pro/*"
        }
      ]
    }
  )

}
#uploading the files into the bucket 
resource "aws_s3_object" "file" {
  for_each     = fileset(path.module, "Nerflix-website-main/**/*.{html,css,js}")
  bucket       = aws_s3_bucket.Static-Bucket.id
  key          = replace(each.value, "/^Nerflix-website-main//", "")
  source       = each.value
  content_type = lookup(local.content_types, regex("\\.[^.]+$", each.value), null)
  etag         = filemd5(each.value)
  acl          = "public-read"

}

#enabling static website hosting for the bucket 

resource "aws_s3_bucket_website_configuration" "hosting" {
  bucket = aws_s3_bucket.Static-Bucket.id

  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}



# creating a CDN

resource "aws_cloudfront_distribution" "distribution" {
  enabled         = true
  is_ipv6_enabled = true

  origin {
    domain_name = aws_s3_bucket_website_configuration.hosting.website_endpoint
    origin_id   = aws_s3_bucket.Static-Bucket.bucket_regional_domain_name
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols = [
        "TLSv1.2",
      ]
    }

  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  default_cache_behavior {
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.Static-Bucket.bucket_regional_domain_name
  }


}

output "website_url" {
  description = "Website URL (HTTPS)"
  value       = aws_cloudfront_distribution.distribution.domain_name
}

output "s3_url" {
  description = "S3 hosting URL (HTTP)"
  value       = aws_s3_bucket_website_configuration.hosting.website_endpoint
}



