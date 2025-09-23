# Configuration Guide for King's Landing HTML Uploader

## Overview
This single page application provides a web interface for uploading HTML content to S3 through API Gateway, with Cognito authentication.

## Required AWS Resources

### 1. Cognito User Pool
- Create a Cognito User Pool in your AWS account
- Note the User Pool ID and Client ID
- Configure the Client ID to allow username/password authentication

### 2. API Gateway
- Create an API Gateway REST API
- Add a POST `/upload` endpoint
- Configure Cognito User Pool as an authorizer
- Ensure the Lambda function behind the endpoint can write to S3

### 3. S3 Bucket
- The bucket `kingslanding.io` should already exist
- Ensure proper CORS configuration for CloudFront

### 4. CloudFront Distribution
- Should already exist with S3 as origin
- Configure to serve `index.html` as the default root object

## Configuration Steps

1. **Update the CONFIG object in index.html:**
   ```javascript
   const CONFIG = {
       COGNITO_USER_POOL_ID: 'your-user-pool-id',
       COGNITO_CLIENT_ID: 'your-client-id', 
       COGNITO_REGION: 'your-region',
       API_GATEWAY_URL: 'https://your-api-id.execute-api.region.amazonaws.com/stage',
       S3_BUCKET: 'kingslanding.io',
       S3_REGION: 'your-s3-region'
   };
   ```

2. **Deploy the HTML file to S3:**
   ```bash
   aws s3 cp index.html s3://kingslanding.io/
   ```

3. **Invalidate CloudFront cache:**
   ```bash
   aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
   ```

## API Gateway Lambda Function

The API Gateway should proxy to a Lambda function that handles the S3 upload. Example Python function:

```python
import json
import boto3
import base64
from botocore.exceptions import ClientError

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    try:
        # Parse the request body
        body = json.loads(event['body'])
        filename = body['filename']
        content = body['content']
        bucket = body['bucket']
        
        # Upload to S3
        s3_client.put_object(
            Bucket=bucket,
            Key=filename,
            Body=content,
            ContentType='text/html'
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({
                'message': 'File uploaded successfully',
                'filename': filename
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,Authorization', 
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({
                'error': str(e)
            })
        }
```

## Security Considerations

1. **Cognito Configuration:**
   - Use strong password policies
   - Enable MFA if required
   - Configure appropriate token expiration times

2. **API Gateway:**
   - Enable Cognito authorization on all endpoints
   - Implement rate limiting
   - Add input validation

3. **S3 Bucket:**
   - Use least privilege IAM policies
   - Enable versioning for content protection
   - Configure appropriate CORS policies

## Testing

1. Create a test user in your Cognito User Pool
2. Access the application via CloudFront URL
3. Login with test credentials
4. Upload sample HTML content
5. Verify file appears in S3 bucket

## Troubleshooting

- **Login Issues:** Check Cognito User Pool ID and Client ID
- **Upload Issues:** Verify API Gateway URL and Lambda permissions
- **CORS Errors:** Check API Gateway CORS configuration
- **Authentication Errors:** Verify JWT token handling in Lambda function