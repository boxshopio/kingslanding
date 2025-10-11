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
User → Web App → Cognito Auth → API Gateway → Upload Lambda → S3 Bucket
                                                               ↓ (S3 Event)
                                                          Invalidation Lambda → CloudFront
```

### Components

- **S3 Bucket**: Stores website files and uploaded HTML pages
- **CloudFront**: Global CDN for fast content delivery
- **Lambda Functions**:
  - Upload Lambda: Handles file uploads via API Gateway
  - Invalidation Lambda: Automatically invalidates CloudFront cache on S3 changes
- **API Gateway**: REST API with Cognito authentication
- **Cognito**: User authentication and authorization

## Quick Start

### 1. Deploy Infrastructure

```bash
# Make sure you have AWS CLI and Terraform installed
./deploy.sh
```

The deployment script will:
- Check prerequisites (Terraform, AWS CLI)
- Create `terraform.tfvars` from example (you'll need to edit it)
- Deploy all AWS infrastructure
- Provide next steps

### 2. Configure terraform.tfvars

Before deployment, edit `terraform/terraform.tfvars`:

```hcl
domain_name = "your-domain.com"
certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/..."
aws_region = "us-east-1"
environment = "prod"
```

### 3. Upload Main Website

After deployment, upload your webapp files to the S3 bucket root. CloudFront invalidation will be triggered automatically!

```bash
# Quick upload script (gets bucket name from Terraform)
./upload-webapp.sh
```

Or manually:
```bash
aws s3 cp webapp/index.html s3://your-bucket-name/index.html
```

## Event-Driven Cache Invalidation

The system uses S3 events to trigger CloudFront invalidation for both user uploads and webapp updates:

1. User uploads HTML file via web interface OR developer uploads webapp files
2. S3 Upload Lambda saves file to S3 bucket (`pages/` directory for user files, root for webapp)
3. S3 triggers event notification for any `.html` file
4. CloudFront Invalidation Lambda receives event and creates CloudFront invalidation
   - For `index.html`: invalidates both `/index.html` and `/` (root path)
   - For other files: invalidates the specific file path
5. Updated content is immediately available globally

**Cost**: Free for < 1,000 invalidations/month, then $0.005 per path.

## Development

### Local Testing

The Lambda functions can be tested locally from the `src/` directory:

```python
# Test S3 upload lambda
python src/s3_upload_lambda.py

# Test CloudFront invalidation lambda
python src/cloudfront_invalidation_lambda.py
```

### File Structure

```
├── webapp/                             # Web application files
│   └── index.html                     # Main web application
├── src/                                # Lambda function source code
│   ├── s3_upload_lambda.py            # S3 upload Lambda function
│   └── cloudfront_invalidation_lambda.py # CloudFront invalidation Lambda
├── terraform/                          # Infrastructure as Code
│   ├── main.tf                        # Main Terraform configuration
│   ├── s3.tf                          # S3 bucket and notifications
│   ├── cloudfront.tf                  # CloudFront distribution
│   ├── lambda.tf                      # Lambda functions
│   ├── api_gateway.tf                 # API Gateway
│   ├── iam.tf                         # IAM roles and policies
│   └── ...
├── deploy.sh                           # Infrastructure deployment script
├── upload-webapp.sh                    # Quick webapp upload script
└── README.md                          # This file
```

## Deployment Commands

```bash
# Deploy infrastructure
./deploy.sh deploy

# Show deployment plan only
./deploy.sh plan

# Destroy infrastructure
./deploy.sh destroy

# Show help
./deploy.sh help
```

## Configuration

### Environment Variables

The Lambda functions use these environment variables (set by Terraform):

- `S3_BUCKET_NAME`: Target S3 bucket for uploads
- `CLOUDFRONT_DISTRIBUTION_ID`: CloudFront distribution to invalidate

### Terraform Variables

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

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test
4. Submit a pull request

## License

This project is licensed under the MIT License.

---

Built with ❤️ for fast, secure HTML deployment.

A single page application for uploading HTML content to S3 through API Gateway with Cognito authentication.

## Features

- 🔐 **Secure Authentication** - AWS Cognito User Pool integration
- 📁 **File Upload** - Upload HTML content directly to S3
- 🌐 **API Gateway Integration** - Serverless backend processing
- ☁️ **CloudFront Ready** - Optimized for CloudFront distribution
- 📱 **Responsive Design** - Works on desktop and mobile devices
- ⚡ **Single Page App** - Self-contained HTML file

## Files

- `index.html` - Main application file (single page app)
- `lambda_function.py` - AWS Lambda function for API Gateway backend
- `SETUP.md` - Detailed configuration and deployment guide

## Quick Start

1. Configure AWS resources (Cognito, API Gateway, S3)
2. Update configuration in `index.html`
3. Deploy `index.html` to your S3 bucket
4. Deploy `lambda_function.py` to AWS Lambda
5. Access via CloudFront URL

See `SETUP.md` for detailed instructions.

## Architecture

```
[User] → [CloudFront] → [S3 (index.html)] → [Cognito Auth] → [API Gateway] → [Lambda] → [S3 Upload]
```

## Requirements

- AWS Cognito User Pool
- AWS API Gateway 
- AWS Lambda
- AWS S3 bucket (kingslanding.io)
- AWS CloudFront distribution

## Security

- All API endpoints secured with Cognito JWT tokens
- HTTPS-only communication
- Input validation and sanitization
- Proper CORS configuration