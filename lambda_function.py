import boto3
import json

s3 = boto3.client("s3")
bucket_name = "kingslanding.io"

def lambda_handler(event, context):
    # --- Start of Dynamic CORS Logic ---
    origin = event.get("headers", {}).get("origin")
    allowed_origin = None

    # Define our allowed origins pattern
    if origin:
        # Allow the base domain or any subdomain
        if origin.endswith(".kingslanding.io") or origin == "https://kingslanding.io":
            allowed_origin = origin

    # If the origin is not allowed, deny the request.
    if not allowed_origin:
        return {
            "statusCode": 403,
            "body": json.dumps({"message": "Forbidden: Origin not allowed"})
        }

    # Base CORS headers for all responses
    cors_headers = {
        'Access-Control-Allow-Origin': allowed_origin,
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'OPTIONS,PUT,POST',
        'Access-Control-Allow-Credentials': 'true' # Often needed for complex requests
    }

    # Handle OPTIONS preflight request
    if event.get("httpMethod") == "OPTIONS":
        return {
            "statusCode": 204, # No Content
            "headers": cors_headers,
            "body": ""
        }
    # --- End of Dynamic CORS Logic ---

    # Your existing PUT logic follows...
    try:
        body = json.loads(event.get("body", "{}"))
    except (json.JSONDecodeError, TypeError):
        return {
            "statusCode": 400,
            "headers": cors_headers,
            "body": json.dumps({"message": "Invalid JSON body"})
        }

    filename = body.get("filename")
    html_content = body.get("html")
    
    if not filename or not html_content:
        return {
            "statusCode": 400,
            "headers": cors_headers,
            "body": json.dumps({"message": "Missing 'filename' or 'html' content in request body"})
        }

    key = f"pages/{filename}"

    try:
        s3.put_object(
            Bucket=bucket_name,
            Key=key,
            Body=html_content,
            ContentType="text/html",
        )
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": cors_headers,
            "body": json.dumps({"message": f"Upload failed: {str(e)}"})
        }

    # Add Content-Type for the final success response
    success_headers = cors_headers.copy()
    success_headers["Content-Type"] = "application/json"

    return {
        "statusCode": 200,
        "headers": success_headers,
        "body": json.dumps({"message": f"File {filename} uploaded successfully to bucket {bucket_name} with key {key}"})
    }