# Webapp Assets

This directory is for webapp assets like:
- CSS files
- JavaScript files  
- Images
- Fonts
- Icons (favicon.ico)

These files can be uploaded to S3 and will be served via CloudFront.

## Example structure:
```
assets/
├── css/
│   └── styles.css
├── js/
│   └── app.js
├── images/
│   └── logo.png
└── favicon.ico
```

## Auto-invalidation

Currently, only `.html` files trigger automatic CloudFront invalidation. 
If you need invalidation for other asset types, you can:

1. Modify the S3 event filters in `terraform/s3.tf`
2. Upload assets manually and invalidate: `aws cloudfront create-invalidation --distribution-id XXX --paths "/assets/*"`
3. Use the upload script which will be enhanced for multi-file uploads in the future