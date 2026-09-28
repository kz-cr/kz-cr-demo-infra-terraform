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

# 4. Attach a Public Read Bucket Policy
resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.public_bucket.id

  # Explicit dependency ensures the block is removed BEFORE the policy is applied
  depends_on = [aws_s3_bucket_public_access_block.allow_public]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.public_bucket.arn}/*"
      }
    ]
  })
}
