terraform {
  backend "s3" {
    bucket = "terra-bucket-23"
    key    = "CDN-Web-Pro/terraform.tfstate"
    region = "us-east-1"
  }
}