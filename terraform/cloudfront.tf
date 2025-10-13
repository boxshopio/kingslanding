# Note: Using existing Origin Access Control (OAC) E17VJKP3PTXDEQ instead of OAI

# CloudFront distribution
resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name
    origin_id   = "kingslanding.io.s3.us-east-2.amazonaws.com-mesknce78yf"  # Match existing origin ID

    # Use Origin Access Control instead of OAI to match existing config
    origin_access_control_id = "E17VJKP3PTXDEQ"  # Match existing OAC ID
    
    connection_attempts = 3
    connection_timeout  = 10
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment            = "kingslanding.io"  # Match existing comment

  aliases = [var.domain_name]

  # Default cache behavior matching existing configuration exactly
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]  # Match existing allowed methods
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "kingslanding.io.s3.us-east-2.amazonaws.com-mesknce78yf"  # Match existing target
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    # Use cache policy ID to match existing configuration
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  price_class = "PriceClass_All"  # Match existing price class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:457320695046:certificate/112ffd17-448d-43ec-a14d-6f41da8dd3d9"  # Match existing cert
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name = "kingslanding.io"  # Match existing tag
  }
}