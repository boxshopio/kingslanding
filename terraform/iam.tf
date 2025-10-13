# IAM role for S3 upload Lambda function
resource "aws_iam_role" "upload_lambda" {
  name = "kingslanding-s3-uploader-role-pu9fqvvd"  # Match existing role name
  path = "/service-role/"  # Match existing path

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for S3 upload Lambda function
# Using least-privilege policy instead of overly permissive AmazonS3FullAccess
resource "aws_iam_role_policy" "upload_lambda" {
  name = "kingslanding-s3-upload-lambda-policy"
  role = aws_iam_role.upload_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.main.arn}/pages/*"
      }
    ]
  })
}

# IAM role for CloudFront invalidation Lambda function
resource "aws_iam_role" "cloudfront_invalidation_lambda" {
  name = "kingslanding-cloudfront-invalidation-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for CloudFront invalidation Lambda function
resource "aws_iam_role_policy" "cloudfront_invalidation_lambda" {
  name = "kingslanding-cloudfront-invalidation-lambda-policy"
  role = aws_iam_role.cloudfront_invalidation_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Resource = "*"
      }
    ]
  })
}