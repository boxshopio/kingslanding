# S3 bucket for hosting static files and uploaded HTML
resource "aws_s3_bucket" "main" {
  bucket = var.domain_name
}

# S3 bucket versioning (disabled for simplicity as discussed)
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Disabled"
  }
}

# S3 bucket CORS configuration
resource "aws_s3_bucket_cors_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = [
      "https://${var.domain_name}",
      "https://*.${var.domain_name}"
    ]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 bucket policy for CloudFront access
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  
  depends_on = [aws_s3_bucket_public_access_block.main]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.main.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.main.arn}/*"
      }
    ]
  })
}

# S3 bucket notification for CloudFront invalidation
resource "aws_s3_bucket_notification" "main" {
  bucket = aws_s3_bucket.main.id

  # Invalidate uploaded HTML pages in pages/ directory
  lambda_function {
    lambda_function_arn = aws_lambda_function.cloudfront_invalidation.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "pages/"
    filter_suffix       = ".html"
  }

  # Invalidate main webapp files (index.html, etc.) at root
  lambda_function {
    lambda_function_arn = aws_lambda_function.cloudfront_invalidation.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".html"
  }

  depends_on = [aws_lambda_permission.s3_invoke_invalidation]
}