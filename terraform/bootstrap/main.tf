provider "aws" {
    region = "ap-southeast-1"

    default_tags {
      tags = {
        Project = "airbnb-elt"
        ManagedBy = "terraform"
      }
    }
  
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "airbnb-bucket-tfstate"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "s3_bucket_versioning" {
  bucket = aws_s3_bucket.s3_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
  
}