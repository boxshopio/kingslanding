#!/bin/bash

# King's Landing Terraform Deployment Script
# This script helps deploy the infrastructure for the King's Landing HTML uploader

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if terraform is installed
check_terraform() {
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    print_success "Terraform is installed: $(terraform version | head -n1)"
}

# Check if AWS CLI is configured
check_aws() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "AWS CLI is configured: $(aws sts get-caller-identity --query 'Account' --output text)"
}

# Check if terraform.tfvars exists
check_tfvars() {
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Creating from example..."
        cp terraform.tfvars.example terraform.tfvars
        print_error "Please edit terraform.tfvars with your actual values before proceeding."
        print_status "Required values: domain_name, certificate_arn"
        exit 1
    fi
    print_success "terraform.tfvars found"
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    terraform init
    print_success "Terraform initialized"
}

# Plan Terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    print_success "Terraform plan created (saved as tfplan)"
}

# Apply Terraform deployment
apply_terraform() {
    print_status "Applying Terraform deployment..."
    terraform apply tfplan
    print_success "Terraform deployment completed!"
}

# Show outputs
show_outputs() {
    print_status "Deployment outputs:"
    echo ""
    terraform output
    echo ""
    print_success "Infrastructure deployed successfully! 🏰"
    echo ""
    print_status "Next steps:"
    echo "1. Upload your webapp files to the S3 bucket (will auto-invalidate CloudFront)"
    echo "   Run: ./upload-webapp.sh"
    echo "2. Point your domain DNS to the CloudFront distribution"
    echo "3. Test the upload functionality"
    echo ""
    print_status "Note: Any .html file uploads (including webapp/index.html) will automatically"
    echo "      trigger CloudFront invalidation for instant updates!"
}

# Main deployment function
deploy() {
    print_status "Starting King's Landing infrastructure deployment..."
    echo ""
    
    check_terraform
    check_aws
    
    # Change to terraform directory
    cd "$(dirname "$0")/terraform"
    
    check_tfvars
    init_terraform
    plan_terraform
    
    # Ask for confirmation
    echo ""
    print_warning "Review the plan above. Do you want to proceed with deployment? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        apply_terraform
        show_outputs
    else
        print_status "Deployment cancelled."
        rm -f tfplan
        exit 0
    fi
}

# Destroy function
destroy() {
    print_warning "This will destroy ALL infrastructure resources!"
    print_warning "This action is IRREVERSIBLE and will delete all uploaded content!"
    echo ""
    print_warning "Are you sure you want to destroy the infrastructure? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        cd "$(dirname "$0")/terraform"
        print_status "Destroying infrastructure..."
        terraform destroy
        print_success "Infrastructure destroyed."
    else
        print_status "Destroy cancelled."
        exit 0
    fi
}

# Show help
show_help() {
    echo "King's Landing Deployment Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  deploy    Deploy the infrastructure (default)"
    echo "  destroy   Destroy all infrastructure"
    echo "  plan      Show deployment plan without applying"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                # Deploy infrastructure"
    echo "  $0 deploy         # Deploy infrastructure"
    echo "  $0 plan           # Show plan only"
    echo "  $0 destroy        # Destroy infrastructure"
}

# Parse command line arguments
case "${1:-deploy}" in
    "deploy")
        deploy
        ;;
    "destroy")
        destroy
        ;;
    "plan")
        check_terraform
        check_aws
        cd "$(dirname "$0")/terraform"
        check_tfvars
        init_terraform
        plan_terraform
        print_status "Plan complete. Run '$0 deploy' to apply."
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac

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