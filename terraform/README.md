# King's Landing Terraform Infrastructure

This directory contains the Terraform infrastructure code for the King's Landing HTML uploader application.

## Architecture Overview

The infrastructure includes:

- **S3 Bucket**: Stores the main website and uploaded HTML files
- **CloudFront Distribution**: CDN for fast global delivery
- **Lambda Functions**:
  - S3 Upload Lambda: Handles file uploads via API Gateway
  - CloudFront Invalidation Lambda: Triggered by S3 events to invalidate CloudFront cache
- **API Gateway**: REST API for file uploads with Cognito authentication
- **IAM Roles & Policies**: Least-privilege access for all services
- **S3 Event Notifications**: Triggers CloudFront invalidation on file uploads

## Event-Driven Invalidation Flow

```
User Upload → API Gateway → S3 Upload Lambda → S3 Bucket
                                              ↓ (S3 Event)
                                   CloudFront Invalidation Lambda → CloudFront
```

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform >= 1.0** installed
3. **SSL Certificate** in AWS Certificate Manager (us-east-1 region)
4. **Domain name** pointed to your AWS account

## Quick Start

1. **Clone and navigate to terraform directory**:
   ```bash
   cd terraform
   ```

2. **Copy and configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your actual values
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan
   ```

5. **Apply the infrastructure**:
   ```bash
   terraform apply
   ```

## Configuration

### Required Variables (terraform.tfvars)

```hcl
aws_region = "us-east-1"
environment = "prod"
domain_name = "your-domain.com"
certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/..."
```

### Optional Variables

```hcl
# If you have existing Cognito resources to import
cognito_user_pool_id = "us-east-1_XXXXXXXXX"
cognito_identity_pool_id = "us-east-1:12345678-1234-1234-1234-123456789012"

# If you have existing API Gateway to import
api_gateway_id = "abcdefghij"
```

## Post-Deployment Steps

1. **Upload your webapp** files from `webapp/` directory to the S3 bucket root
2. **Update DNS** to point your domain to the CloudFront distribution
3. **Test upload functionality** via the web interface
4. **Verify invalidation** by uploading a file and checking CloudFront

## File Structure

```
terraform/
├── main.tf              # Main configuration and locals
├── variables.tf         # Input variables
├── outputs.tf          # Output values
├── versions.tf         # Provider version constraints
├── s3.tf               # S3 bucket and notifications
├── cloudfront.tf       # CloudFront distribution
├── lambda.tf           # Lambda functions
├── api_gateway.tf      # API Gateway configuration
├── iam.tf              # IAM roles and policies
├── cognito.tf          # Cognito resources (commented)
└── terraform.tfvars.example  # Example variables file
```

## Important Notes

### CloudFront Invalidation Costs
- First 1,000 invalidation paths per month: **FREE**
- Additional paths: $0.005 per path
- At < 100 invalidations/week, you'll stay within the free tier

### S3 Event Configuration
- Triggers on `.html` files in the `pages/` directory (user uploads)
- Triggers on `.html` files in the root directory (main webapp files like index.html)
- Uses `s3:ObjectCreated:*` events (PUT, POST, COPY)
- Lambda function always invalidates (KISS approach)
- Special handling: `index.html` invalidates both `/index.html` and `/` paths

### Lambda Functions
- **S3 Upload Lambda**: Runtime Python 3.11, 30s timeout
- **CloudFront Invalidation Lambda**: Runtime Python 3.11, 60s timeout
- Both have CloudWatch logs with 14-day retention

## Troubleshooting

### Common Issues

1. **Certificate not found**: Ensure SSL certificate is in us-east-1 region
2. **S3 bucket already exists**: S3 bucket names are globally unique
3. **Lambda deployment fails**: Check that source files exist in parent directory

### Debugging Invalidation

Check CloudWatch logs for the CloudFront invalidation Lambda:
```bash
aws logs tail /aws/lambda/kingslanding-cloudfront-invalidation --follow
```

### Verify S3 Events

Test S3 event configuration:
```bash
aws s3 cp test.html s3://your-bucket/pages/test.html
# Check if invalidation Lambda was triggered
```

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

⚠️ **Warning**: This will delete all resources including the S3 bucket and uploaded content.

## Security Considerations

- All IAM roles follow least-privilege principle
- Lambda functions can only access required resources
- S3 bucket policy restricts access to CloudFront OAI
- API Gateway uses Cognito for authentication

## Cost Optimization

- CloudFront uses PriceClass_100 (North America + Europe only)
- Lambda functions use minimal memory allocation
- CloudWatch logs have 14-day retention
- No S3 versioning to avoid storage costs