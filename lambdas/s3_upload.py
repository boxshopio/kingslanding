import boto3
import json
import re

s3 = boto3.client("s3")
bucket_name = "kingslanding.io"

# --- BoxShop Footer HTML ---
FOOTER_HTML = """
<footer>
  <p class="to-top">
    <a href="#" id="moveTop">↑ Move to Top</a>
  </p>
  <p>&copy; 2025 BoxShop, Inc. &middot; All rights reserved. Contact: hello@boxshop.io</p>
</footer>

<style>
  body {
    margin: 0;
    padding-bottom: 100px;
    font-family: Arial, sans-serif;
  }
  footer {
    position: fixed;
    bottom: 0;
    left: 0;
    width: 100%;
    background-color: #222;
    color: #ccc;
    text-align: center;
    padding: 1em 1em;
    font-size: 0.9rem;
    box-shadow: 0 -2px 8px rgba(0, 0, 0, 0.3);
  }
  footer a {
    color: #4da3ff;
    text-decoration: none;
    transition: color 0.2s ease;
  }
  footer a:hover {
    color: #fff;
    text-decoration: underline;
  }
  .to-top {
    margin: 0 0 0.3em 0;
  }
  #moveTop {
    font-weight: bold;
  }
</style>

<script>
  document.addEventListener("DOMContentLoaded", function() {
    var topLink = document.getElementById("moveTop");
    if (topLink) {
      topLink.addEventListener("click", function(e) {
        e.preventDefault();
        window.scrollTo({ top: 0, behavior: "smooth" });
      });
    }
  });
</script>
"""

def lambda_handler(event, context):
    # --- Start of Dynamic CORS Logic ---
    origin = event.get("headers", {}).get("origin")
    allowed_origin = None

    # Allow the base domain or any subdomain
    if origin:
        if origin.endswith(".kingslanding.io") or origin == "https://kingslanding.io":
            allowed_origin = origin

    if not allowed_origin:
        return {
            "statusCode": 403,
            "body": json.dumps({"message": "Forbidden: Origin not allowed"})
        }

    cors_headers = {
        'Access-Control-Allow-Origin': allowed_origin,
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'OPTIONS,PUT,POST',
        'Access-Control-Allow-Credentials': 'true'
    }

    if event.get("httpMethod") == "OPTIONS":
        return {
            "statusCode": 204,
            "headers": cors_headers,
            "body": ""
        }
    # --- End of Dynamic CORS Logic ---

    # Parse incoming JSON
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

    # --- 🧠 Footer Validation and Insertion ---
    lower_html = html_content.lower()
    footers = list(re.finditer(r'<footer.*?>.*?</footer>', html_content, flags=re.IGNORECASE | re.DOTALL))

    add_footer = False

    if footers:
        last_footer = footers[-1].group(0)
        if "boxshop" not in last_footer.lower():
            add_footer = True
            print(f"{filename}: last footer does NOT contain BoxShop — appending.")
        else:
            print(f"{filename}: last footer already contains BoxShop — skipping.")
    else:
        add_footer = True
        print(f"{filename}: no footer found — adding BoxShop footer.")

    if add_footer:
        if "</body>" in lower_html:
            body_close_index = lower_html.rfind("</body>")
            html_content = html_content[:body_close_index] + FOOTER_HTML + html_content[body_close_index:]
        else:
            html_content += FOOTER_HTML

    # --- Upload to S3 ---
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

    success_headers = cors_headers.copy()
    success_headers["Content-Type"] = "application/json"

    return {
        "statusCode": 200,
        "headers": success_headers,
        "body": json.dumps({
            "message": f"File '{filename}' uploaded successfully to bucket '{bucket_name}' with key '{key}'.",
            "footer_added": add_footer
        })
    }
