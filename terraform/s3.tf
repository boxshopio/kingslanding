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

# S3 bucket lifecycle configuration for cleanup and cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  # Existing rule: Expire non-current versions for pages/ directory
  rule {
    id     = "expire-noncurrent-versions-for-pages"
    status = "Enabled"

    filter {
      prefix = "pages/"
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  # New rule: Clean up expired delete markers
  rule {
    id     = "delete-expired-delete-markers"
    status = "Enabled"

    filter {}

    expiration {
      expired_object_delete_marker = true
    }
  }

  # New rule: Abort incomplete multipart uploads after 7 days
  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # New rule: Expire non-current versions for all files (broader coverage)
  rule {
    id     = "expire-noncurrent-versions-global"
    status = "Enabled"

    # This applies to all objects in the bucket
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90  # Longer retention for non-pages content
    }
  }
}