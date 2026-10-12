provider "aws" {
  region = "ap-southeast-1"

  default_tags {
    tags = {
      Project   = "airbnb-elt"
      ManagedBy = "terraform"
    }
  }
}

resource "aws_s3_bucket" "raw" {
  bucket        = "airbnb-sydney-raw-data"
  force_destroy = true
}