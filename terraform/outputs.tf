output "s3_bucket" {
  value = aws_s3_bucket.raw.bucket
}

output "postgres_host" {
  value = aws_db_instance.airbnb.address
}

output "postgres_password" {
  value     = random_password.db.result
  sensitive = true
}