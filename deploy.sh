#!/bin/bash

# Deployment script for King's Landing HTML Uploader
# This script helps deploy the application to S3 and CloudFront

set -e

# Configuration (update these values)
S3_BUCKET="kingslanding.io"
CLOUDFRONT_DISTRIBUTION_ID="E2I7CZOTSI0I5H"  # Add your CloudFront distribution ID
AWS_REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}King's Landing HTML Uploader - Deployment Script${NC}"
echo "=================================================="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "index.html" ]; then
    echo -e "${RED}Error: index.html not found. Please run this script from the project root.${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Validating HTML file...${NC}"
if command -v tidy &> /dev/null; then
    tidy -q -e index.html && echo -e "${GREEN}✓ HTML validation passed${NC}" || echo -e "${YELLOW}⚠ HTML validation warnings (continuing anyway)${NC}"
else
    echo -e "${YELLOW}⚠ HTML tidy not found, skipping validation${NC}"
fi

echo -e "${YELLOW}Step 2: Uploading to S3...${NC}"
aws s3 cp index.html s3://${S3_BUCKET}/ \
    --region ${AWS_REGION} \
    --content-type "text/html" \
    --cache-control "max-age=300" \
    --metadata "deployed-by=deployment-script,deployed-at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Successfully uploaded index.html to S3${NC}"
else
    echo -e "${RED}✗ Failed to upload to S3${NC}"
    exit 1
fi

# Optional: Upload Lambda function if it exists
if [ -f "lambda_function.py" ]; then
    echo -e "${YELLOW}Step 3: Lambda function found, creating deployment package...${NC}"
    
    # Create a temporary directory for the deployment package
    TEMP_DIR=$(mktemp -d)
    cp lambda_function.py ${TEMP_DIR}/
    
    # Create ZIP file
    cd ${TEMP_DIR}
    zip -r ../lambda-deployment.zip .
    cd - > /dev/null
    
    echo -e "${GREEN}✓ Lambda deployment package created: lambda-deployment.zip${NC}"
    echo -e "${YELLOW}  Note: You'll need to manually deploy this to your Lambda function${NC}"
    
    # Clean up
    rm -rf ${TEMP_DIR}
fi

# Invalidate CloudFront cache if distribution ID is provided
if [ -n "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
    echo -e "${YELLOW}Step 4: Invalidating CloudFront cache...${NC}"
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id ${CLOUDFRONT_DISTRIBUTION_ID} \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ CloudFront invalidation created: ${INVALIDATION_ID}${NC}"
        echo -e "${YELLOW}  Cache invalidation may take a few minutes to complete${NC}"
    else
        echo -e "${RED}✗ Failed to create CloudFront invalidation${NC}"
    fi
else
    echo -e "${YELLOW}Step 4: Skipping CloudFront invalidation (no distribution ID configured)${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Update the CONFIG section in index.html with your AWS resource IDs"
echo "2. Deploy the Lambda function if you haven't already"
echo "3. Test the application at your CloudFront URL"
echo ""
echo "Resources to configure:"
echo "- Cognito User Pool ID and Client ID"
echo "- API Gateway URL"
echo "- S3 bucket permissions"
echo ""
echo -e "${YELLOW}See SETUP.md for detailed configuration instructions${NC}"