resource "aws_acm_certificate" "blue_report" {
  provider          = aws.acm_certificate
  domain_name       = "theblue.report"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "blue_report" {
  provider        = aws.acm_certificate
  certificate_arn = aws_acm_certificate.blue_report.arn
}

resource "aws_cloudfront_origin_access_control" "blue_report" {
  name                              = "blue-report"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "blue_report" {
  aliases = ["theblue.report"]
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.blue_report.arn
    ssl_support_method  = "sni-only"
  }


  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.blue_report.id
    origin_id                = "s3-origin"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-origin"
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class  = "PriceClass_100"
  http_version = "http2and3"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  depends_on = [aws_acm_certificate_validation.blue_report]
}
