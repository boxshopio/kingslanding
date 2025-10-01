import boto3
import json

s3 = boto3.client("s3")
bucket_name = "kingslanding.io"

def lambda_handler(event, context):
    # Parse JSON body from API Gateway
    try:
        body = event["body"]
        if isinstance(body, str):
            body = json.loads(event["body"])
    except json.JSONDecodeError:
        return {"statusCode": 400, "body": "Invalid JSON body"}

    filename = body.get("filename")
    html_content = body.get("html")
    key = f"pages/{filename}"

    try:
        s3.put_object(
            Bucket=bucket_name,
            Key=key,
            Body=html_content,
            ContentType="text/html",
        )
    except Exception as e:
        return {"statusCode": 500, "body": f"Upload failed: {str(e)}"}

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"message": f"File {filename} uploaded successfully to bucket {bucket_name} with key {key}"})
    }
