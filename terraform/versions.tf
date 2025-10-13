terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Lock to specific AWS account for security
  allowed_account_ids = ["457320695046"]

  default_tags {
    tags = {
      Project     = "kingslanding"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}