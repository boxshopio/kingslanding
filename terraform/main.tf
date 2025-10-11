# Main Terraform configuration for King's Landing
# This file serves as the entry point and can include any additional resources

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Data source to get current AWS region
data "aws_region" "current" {}

# Local values for common tags and naming
locals {
  common_tags = {
    Project     = "kingslanding"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
  
  name_prefix = "kingslanding-${var.environment}"
}