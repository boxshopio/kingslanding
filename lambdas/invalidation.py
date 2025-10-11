import boto3
import json
import os
import time
from urllib.parse import unquote_plus

cloudfront = boto3.client('cloudfront')

def lambda_handler(event, context):
    """
    Lambda function triggered by S3 events to invalidate CloudFront cache
    when HTML files are uploaded to the pages/ directory.
    """
    distribution_id = os.environ.get('CLOUDFRONT_DISTRIBUTION_ID')
    
    if not distribution_id:
        print("ERROR: CLOUDFRONT_DISTRIBUTION_ID environment variable not set")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'CloudFront distribution ID not configured'})
        }
    
    invalidation_paths = []
    
    # Process each S3 event record
    for record in event['Records']:
        # Parse S3 event details
        bucket = record['s3']['bucket']['name']
        key = unquote_plus(record['s3']['object']['key'])
        event_name = record['eventName']
        
        print(f"Processing S3 event: {event_name} for object: {key} in bucket: {bucket}")
        
        # Create invalidation path (S3 key becomes CloudFront path)
        invalidation_path = f'/{key}'
        
        # Add special handling for root index.html
        if key == 'index.html':
            # Also invalidate the root path for the main webapp
            invalidation_paths.extend([invalidation_path, '/'])
            print(f"Main webapp detected - will invalidate both: {invalidation_path} and /")
        else:
            invalidation_paths.append(invalidation_path)
            print(f"Will invalidate CloudFront path: {invalidation_path}")
    
    # Remove duplicates while preserving order
    invalidation_paths = list(dict.fromkeys(invalidation_paths))
    
    if not invalidation_paths:
        print("No paths to invalidate")
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'No invalidation needed'})
        }
    
    try:
        # Create CloudFront invalidation
        # Use timestamp in caller reference to ensure uniqueness
        caller_reference = f"s3-event-{int(time.time())}-{len(invalidation_paths)}"
        
        response = cloudfront.create_invalidation(
            DistributionId=distribution_id,
            InvalidationBatch={
                'Paths': {
                    'Quantity': len(invalidation_paths),
                    'Items': invalidation_paths
                },
                'CallerReference': caller_reference
            }
        )
        
        invalidation_id = response['Invalidation']['Id']
        print(f"CloudFront invalidation created successfully: {invalidation_id}")
        print(f"Invalidated paths: {invalidation_paths}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Invalidation created successfully',
                'invalidation_id': invalidation_id,
                'paths': invalidation_paths
            })
        }
        
    except Exception as e:
        error_message = f"Failed to create CloudFront invalidation: {str(e)}"
        print(f"ERROR: {error_message}")
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': error_message,
                'paths': invalidation_paths
            })
        }