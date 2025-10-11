#!/bin/bash

# Quick script to upload index.html to S3 and test auto-invalidation
# Usage: ./upload-webapp.sh

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get S3 bucket name from Terraform output
cd "$(dirname "$0")/terraform"

if [ ! -f "terraform.tfstate" ]; then
    print_error "Terraform state not found. Please run './deploy.sh' first."
    exit 1
fi

BUCKET_NAME=$(terraform output -raw s3_bucket_name 2>/dev/null)
DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null)

if [ -z "$BUCKET_NAME" ]; then
    print_error "Could not get S3 bucket name from Terraform output."
    exit 1
fi

cd ..

# Check if index.html exists
if [ ! -f "webapp/index.html" ]; then
    print_error "webapp/index.html not found in webapp directory."
    exit 1
fi

print_status "Uploading webapp/index.html to S3 bucket: $BUCKET_NAME"

# Upload index.html to S3 root
aws s3 cp webapp/index.html "s3://$BUCKET_NAME/index.html" \
    --content-type "text/html" \
    --cache-control "max-age=300"

print_success "webapp/index.html uploaded successfully!"

print_status "S3 event should trigger CloudFront invalidation automatically..."
print_status "CloudFront Distribution ID: $DISTRIBUTION_ID"

echo ""
print_status "Check CloudWatch logs to see invalidation in action:"
echo "aws logs tail /aws/lambda/kingslanding-cloudfront-invalidation --follow"

echo ""
print_success "🏰 Main webapp deployed! Your site should update within 1-2 minutes."