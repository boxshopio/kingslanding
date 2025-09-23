import json
import boto3
import base64
import logging
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize S3 client
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    """
    Lambda function to handle HTML file uploads to S3
    Expects POST requests with JSON body containing:
    - filename: name of the file to create
    - content: HTML content to upload
    - bucket: S3 bucket name
    """
    
    # Handle CORS preflight requests
    if event['httpMethod'] == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': ''
        }
    
    try:
        # Parse the request body
        body = json.loads(event['body'])
        filename = body.get('filename')
        content = body.get('content')
        bucket = body.get('bucket', 'kingslanding.io')
        
        # Validate required fields
        if not filename:
            raise ValueError("Filename is required")
        if not content:
            raise ValueError("Content is required")
        
        # Ensure filename has .html extension
        if not filename.endswith('.html'):
            filename += '.html'
        
        # Log the upload attempt
        logger.info(f"Uploading file {filename} to bucket {bucket}")
        
        # Upload to S3
        s3_client.put_object(
            Bucket=bucket,
            Key=filename,
            Body=content,
            ContentType='text/html',
            CacheControl='max-age=300'  # 5 minute cache
        )
        
        logger.info(f"Successfully uploaded {filename} to {bucket}")
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({
                'message': 'File uploaded successfully',
                'filename': filename,
                'bucket': bucket,
                'url': f"https://{bucket}/{filename}"
            })
        }
        
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in request body: {str(e)}")
        return {
            'statusCode': 400,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({
                'error': 'Invalid JSON in request body'
            })
        }
        
    except ValueError as e:
        logger.error(f"Validation error: {str(e)}")
        return {
            'statusCode': 400,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({
                'error': str(e)
            })
        }
        
    except ClientError as e:
        logger.error(f"AWS S3 error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({
                'error': 'Failed to upload file to S3'
            })
        }
        
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({
                'error': 'Internal server error'
            })
        }