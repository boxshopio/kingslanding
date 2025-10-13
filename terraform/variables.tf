variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "domain_name" {
  description = "Domain name for the application (e.g., kingslanding.io)"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for CloudFront (must be in us-east-1)"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "Existing Cognito User Pool ID"
  type        = string
  default     = ""
}

variable "cognito_identity_pool_id" {
  description = "Existing Cognito Identity Pool ID"
  type        = string
  default     = ""
}

variable "api_gateway_id" {
  description = "Existing API Gateway ID"
  type        = string
  default     = ""
}