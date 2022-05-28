resource "aws_s3_bucket_policy" "read_site" {
  bucket = var.s3_bucket.id
  policy = data.aws_iam_policy_document.read_site_bucket.json
}

resource "aws_cloudfront_origin_access_identity" "site" {
  comment = "Allows CloudFront to reach ${var.s3_bucket.id}"
}

data "aws_iam_policy_document" "read_site_bucket" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${var.s3_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.site.iam_arn]
    }
  }
}

resource "aws_cloudfront_distribution" "site" {
  enabled = true

  is_ipv6_enabled = true

  comment = "Terraform distribution for ${var.s3_bucket.id}"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = var.s3_bucket.bucket_regional_domain_name
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id = local.caching_optimized_cache_policy_id
  }

  origin {
    domain_name = var.s3_bucket.bucket_regional_domain_name
    origin_id   = var.s3_bucket.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.site.cloudfront_access_identity_path
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }
}
