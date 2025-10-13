# S3 bucket for hosting static files and uploaded HTML
resource "aws_s3_bucket" "main" {
  bucket = var.domain_name
}

# S3 bucket versioning (matching existing enabled state)
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"  # Match existing configuration
  }
}

# S3 bucket public access block - Block all public access since bucket is behind CloudFront
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true 
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy for CloudFront access
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  
  depends_on = [aws_s3_bucket_public_access_block.main]

  policy = jsonencode({
    Version = "2008-10-17"
    Id      = "PolicyForCloudFrontPrivateContent"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.main.arn}/*"
        Condition = {
          ArnLike = {
            "AWS:SourceArn" = "arn:aws:cloudfront::457320695046:distribution/*"
          }
        }
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

  # Invalidate index.html at root (specific file to avoid overlap)
  lambda_function {
    lambda_function_arn = aws_lambda_function.cloudfront_invalidation.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "index.html"
  }

  depends_on = [aws_lambda_permission.s3_invoke_invalidation]
}