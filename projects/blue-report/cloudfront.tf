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
    acm_certificate_arn      = aws_acm_certificate.blue_report.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
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
    cache_policy_id        = aws_cloudfront_cache_policy.blue_report.id
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class  = "PriceClass_100"
  http_version = "http2and3"

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  depends_on = [aws_acm_certificate_validation.blue_report]
}

resource "aws_cloudfront_cache_policy" "blue_report" {
  name        = "blue-report"
  default_ttl = 600
  max_ttl     = 900
  min_ttl     = 60

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}
