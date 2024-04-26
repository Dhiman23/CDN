
#Creating a bucket
resource "aws_s3_bucket" "Static-Bucket" {
  bucket = "CDN-Web-Pro"
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


