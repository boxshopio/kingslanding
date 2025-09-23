# King's Landing HTML Uploader

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