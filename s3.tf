# Shared bucket that stores canary run artifacts for every canary.
resource "aws_s3_bucket" "canary_output" {
  bucket        = var.artifact_bucket_name
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_ownership_controls" "canary_output" {
  bucket = aws_s3_bucket.canary_output.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "canary_output" {
  depends_on = [aws_s3_bucket_ownership_controls.canary_output]

  bucket = aws_s3_bucket.canary_output.id
  acl    = "private"
}
