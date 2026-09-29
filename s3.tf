# 1. Create the S3 Bucket
resource "aws_s3_bucket" "public_bucket" {
  bucket        = "${var.name}-s3-bucket"
  force_destroy = true
}

# 2. Disable S3 Block Public Access (Required to allow public policies/ACLs)
resource "aws_s3_bucket_public_access_block" "allow_public" {
  bucket = aws_s3_bucket.public_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 3. Configure Bucket Ownership Controls (Ensures Bucket Owner maintains access)
resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.public_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
