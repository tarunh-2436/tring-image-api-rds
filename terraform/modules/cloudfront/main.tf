###############################################
# Origin Access Control
###############################################

resource "aws_cloudfront_origin_access_control" "this" {

  name = "${var.distribution_name}-oac"

  description = "Origin Access Control"

  origin_access_control_origin_type = "s3"

  signing_behavior = "always"

  signing_protocol = "sigv4"
}

###############################################
# CloudFront Distribution
###############################################

resource "aws_cloudfront_distribution" "this" {

  enabled = true

  default_root_object = var.default_root_object

  origin {

    domain_name = var.origin_domain_name

    origin_id = "s3-origin"

    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {

    target_origin_id = "s3-origin"

    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET",
      "HEAD"
    ]

    cached_methods = [
      "GET",
      "HEAD"
    ]

    compress = true

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

  }

  restrictions {

    geo_restriction {

      restriction_type = "none"
    }
  }

  viewer_certificate {

    cloudfront_default_certificate = true
  }

  http_version = "http2"

  is_ipv6_enabled = true

  tags = merge(
    var.tags,
    {
      Name = var.distribution_name
    }
  )
}