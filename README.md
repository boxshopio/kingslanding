# King's Landing HTML Uploader 🏰

A web-based HTML editor and uploader that allows users to create and deploy HTML pages instantly via CloudFront CDN.

## Features

- **Web-based HTML Editor**: Built-in CodeMirror editor with syntax highlighting
- **Instant Deployment**: Upload HTML files that are immediately available via CloudFront
- **Authentication**: Secure uploads using AWS Cognito
- **Auto-Invalidation**: Automatic CloudFront cache invalidation when files are updated
- **Infrastructure as Code**: Complete Terraform setup for reproducible deployments

## Architecture

```
User → Web App → Cognito Auth → API Gateway → S3 Upload Lambda → S3 Bucket
                                                                    ↓ (S3 Event)
                                                           Invalidation Lambda → CloudFront
```

### Components

- **S3 Bucket**: Stores website files and uploaded HTML pages
- **CloudFront**: Global CDN for fast content delivery  
- **Lambda Functions**:
  - S3 Upload Lambda: Handles file uploads via API Gateway
  - Invalidation Lambda: Automatically invalidates CloudFront cache on S3 changes
- **API Gateway**: REST API with Cognito authentication
- **Cognito**: User authentication and authorization

## Project Structure

```
kingslanding/
├── index.html              # Main web application
├── lambdas/               # Lambda function source code
│   ├── s3_upload.py       # S3 upload handler
│   └── invalidation.py    # CloudFront invalidation handler
├── terraform/             # Infrastructure as Code
│   ├── main.tf           # Main Terraform configuration
│   ├── s3.tf             # S3 bucket and notifications
│   ├── cloudfront.tf     # CloudFront distribution
│   ├── lambda.tf         # Lambda functions
│   ├── api_gateway.tf    # API Gateway
│   ├── iam.tf            # IAM roles and policies
│   └── ...
├── deploy.sh             # Unified deployment script
└── README.md            # This file
```

## Quick Start

### 1. Deploy Infrastructure

```bash
# Deploy AWS infrastructure
./deploy.sh infra

# Or just run (defaults to infra)
./deploy.sh
```

### 2. Configure terraform.tfvars

Before deployment, edit `terraform/terraform.tfvars`:

```hcl
domain_name = "your-domain.com"
certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/..."
aws_region = "us-east-1"
environment = "prod"
```

### 3. Deploy Webapp

```bash
# Deploy the main webapp
./deploy.sh webapp

# Or deploy everything at once
./deploy.sh all
```

## Event-Driven Cache Invalidation

The system uses S3 events to trigger CloudFront invalidation for both user uploads and webapp updates:

1. User uploads HTML file via web interface OR developer uploads webapp files
2. S3 Upload Lambda saves file to S3 bucket (`pages/` directory for user files, root for webapp)
3. S3 triggers event notification for any `.html` file
4. Invalidation Lambda receives event and creates CloudFront invalidation
   - For `index.html`: invalidates both `/index.html` and `/` (root path)
   - For other files: invalidates the specific file path
5. Updated content is immediately available globally

**Cost**: Free for < 1,000 invalidations/month, then $0.005 per path.

## Deployment Commands

```bash
# Deploy infrastructure only
./deploy.sh infra

# Deploy webapp only (requires infrastructure first)
./deploy.sh webapp

# Deploy everything
./deploy.sh all

# Show deployment plan only
./deploy.sh plan

# Destroy infrastructure
./deploy.sh destroy

# Show help
./deploy.sh help
```

## Development

### Local Testing

The Lambda functions can be tested locally:

```python
# Test S3 upload lambda
python lambdas/s3_upload.py

# Test CloudFront invalidation lambda
python lambdas/invalidation.py
```

### Configuration

#### Environment Variables

The Lambda functions use these environment variables (set by Terraform):

- `S3_BUCKET_NAME`: Target S3 bucket for uploads
- `CLOUDFRONT_DISTRIBUTION_ID`: CloudFront distribution to invalidate

#### Terraform Variables

See `terraform/terraform.tfvars.example` for all available configuration options.

## Security

- **IAM Roles**: Least-privilege access for all services
- **Cognito Authentication**: Secure user authentication
- **CORS**: Properly configured for domain restrictions
- **S3 Bucket Policy**: Access restricted to CloudFront OAI

## Monitoring

- **CloudWatch Logs**: All Lambda functions log to CloudWatch
- **API Gateway Logs**: Request/response logging available
- **CloudFront Logs**: Access logs can be enabled

## Cost Optimization

- **CloudFront**: PriceClass_100 (North America + Europe only)
- **Lambda**: Minimal memory allocation, short timeouts
- **S3**: No versioning to avoid additional storage costs
- **Invalidations**: Stay within 1,000/month free tier

## Troubleshooting

### Check Invalidation Lambda Logs

```bash
aws logs tail /aws/lambda/kingslanding-cloudfront-invalidation --follow
```

### Test S3 Event Trigger

```bash
# Upload a test file to trigger invalidation
aws s3 cp test.html s3://your-bucket/pages/test.html
```

### Verify CloudFront Distribution

```bash
# Get distribution details
aws cloudfront get-distribution --id YOUR_DISTRIBUTION_ID
```

## Infrastructure Details

The complete AWS infrastructure includes:

- **S3 Bucket**: With event notifications for CloudFront invalidation
- **CloudFront Distribution**: Optimized cache behaviors for uploaded content
- **Lambda Functions**: Both upload and invalidation functions with proper IAM roles
- **API Gateway**: Complete REST API setup with CORS and Cognito integration
- **Event-Driven Architecture**: S3 events automatically trigger cache invalidation

### Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform >= 1.0** installed
3. **SSL Certificate** in AWS Certificate Manager (us-east-1 region)
4. **Domain name** pointed to your AWS account

### Cost Analysis

**Monthly costs for typical usage:**
- **S3**: ~$1-5 (depending on storage and requests)
- **CloudFront**: ~$1-10 (depending on traffic)
- **Lambda**: ~$0-1 (likely free tier)
- **API Gateway**: ~$0-5 (depending on requests)
- **Route 53**: ~$0.50 (if using AWS DNS)

**Total**: ~$3-20/month for most use cases

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test
4. Submit a pull request

## License

This project is licensed under the MIT License.

---

Built with ❤️ for fast, secure HTML deployment.