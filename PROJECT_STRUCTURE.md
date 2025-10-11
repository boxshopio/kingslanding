# King's Landing Project Structure

This document explains the organization of the King's Landing HTML uploader project.

## Directory Structure

```
kingslanding/
├── webapp/                 # Web Application Files
├── src/                    # Lambda Function Source Code  
├── terraform/              # Infrastructure as Code
├── deploy.sh              # Infrastructure deployment
├── upload-webapp.sh       # Webapp deployment
└── docs/                  # Project documentation
```

## Purpose of Each Directory

### `/webapp` - Web Application Files
Contains the frontend web application that users interact with:
- `index.html` - Main HTML editor interface
- `assets/` - Future CSS, JavaScript, images, fonts
- Static files that get deployed to S3 and served via CloudFront

### `/src` - Lambda Function Source Code
Contains AWS Lambda function implementations:
- `s3_upload_lambda.py` - Handles file uploads via API Gateway
- `cloudfront_invalidation_lambda.py` - Triggers cache invalidation on S3 events
- Pure Python source code, packaged by Terraform

### `/terraform` - Infrastructure as Code
Contains complete AWS infrastructure definitions:
- S3 bucket, CloudFront distribution, Lambda functions
- API Gateway, IAM roles, security policies
- Event-driven architecture configuration
- Deployment variables and outputs

## Development Workflow

1. **Edit webapp**: Modify files in `/webapp`
2. **Deploy webapp**: Run `./upload-webapp.sh` 
3. **Edit functions**: Modify Lambda code in `/src`
4. **Deploy infrastructure**: Run `./deploy.sh`
5. **Test**: Use web interface to upload HTML files

## Separation of Concerns

- **Frontend**: `/webapp` - User-facing application
- **Backend**: `/src` - Server-side processing logic  
- **Infrastructure**: `/terraform` - Cloud resource definitions
- **Deployment**: Root-level scripts for automation

This structure scales well as the project grows and makes it easy for new developers to understand the codebase organization.