# Archive the S3 upload Lambda function
data "archive_file" "upload_lambda_zip" {
  type        = "zip"
  source_file = "${path.root}/../src/s3_upload_lambda.py"
  output_path = "${path.module}/s3_upload_lambda.zip"
}

# Archive the CloudFront invalidation Lambda function
data "archive_file" "cloudfront_invalidation_lambda_zip" {
  type        = "zip"
  source_file = "${path.root}/../src/cloudfront_invalidation_lambda.py"
  output_path = "${path.module}/cloudfront_invalidation_lambda.zip"
}

# S3 upload Lambda function
resource "aws_lambda_function" "upload" {
  filename         = data.archive_file.upload_lambda_zip.output_path
  function_name    = "kingslanding-s3-upload"
  role            = aws_iam_role.upload_lambda.arn
  handler         = "s3_upload_lambda.lambda_handler"
  source_code_hash = data.archive_file.upload_lambda_zip.output_base64sha256
  runtime         = "python3.11"
  timeout         = 30

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.main.bucket
    }
  }

  depends_on = [
    aws_iam_role_policy.upload_lambda,
    aws_cloudwatch_log_group.upload_lambda,
  ]
}

# CloudFront invalidation Lambda function (new)
resource "aws_lambda_function" "cloudfront_invalidation" {
  filename         = data.archive_file.cloudfront_invalidation_lambda_zip.output_path
  function_name    = "kingslanding-cloudfront-invalidation"
  role            = aws_iam_role.cloudfront_invalidation_lambda.arn
  handler         = "cloudfront_invalidation_lambda.lambda_handler"
  source_code_hash = data.archive_file.cloudfront_invalidation_lambda_zip.output_base64sha256
  runtime         = "python3.11"
  timeout         = 60

  environment {
    variables = {
      CLOUDFRONT_DISTRIBUTION_ID = aws_cloudfront_distribution.main.id
    }
  }

  depends_on = [
    aws_iam_role_policy.cloudfront_invalidation_lambda,
    aws_cloudwatch_log_group.cloudfront_invalidation_lambda,
  ]
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "upload_lambda" {
  name              = "/aws/lambda/kingslanding-s3-upload"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "cloudfront_invalidation_lambda" {
  name              = "/aws/lambda/kingslanding-cloudfront-invalidation"
  retention_in_days = 14
}

# Lambda permission for S3 to invoke CloudFront invalidation function
resource "aws_lambda_permission" "s3_invoke_invalidation" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudfront_invalidation.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.main.arn
}

# Lambda permission for API Gateway to invoke upload function
resource "aws_lambda_permission" "api_gateway_invoke_upload" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}