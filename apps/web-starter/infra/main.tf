# Source: https://www.milanvit.net/post/terraform-recipes-cloudfront-distribution-from-s3-bucket/

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region = var.aws_region
}

locals {
  # Source: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html
  caching_optimized_cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}

module "frontend_bucket" {
  source = "./modules/frontend-s3-bucket"

  bucket_name    = "${var.app_name}-${var.environment_name}"
  dist_directory = "${path.module}/../../../dist/apps/${var.app_name}"
}

#region CloudFront Distribution

resource "aws_s3_bucket_policy" "read_site" {
  bucket = module.frontend_bucket.bucket_id
  policy = data.aws_iam_policy_document.read_site_bucket.json
}

resource "aws_cloudfront_origin_access_identity" "site" {
  comment = "Allows CloudFront to reach ${module.frontend_bucket.bucket_id}"
}

data "aws_iam_policy_document" "read_site_bucket" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.frontend_bucket.bucket_arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.site.iam_arn]
    }
  }
}

resource "aws_cloudfront_distribution" "site" {
  enabled = true

  is_ipv6_enabled = true

  comment = "Terraform distribution for ${module.frontend_bucket.bucket_id}"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = module.frontend_bucket.bucket_regional_domain_name
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id = local.caching_optimized_cache_policy_id
  }

  origin {
    domain_name = module.frontend_bucket.bucket_regional_domain_name
    origin_id   = module.frontend_bucket.bucket_regional_domain_name

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

#endregion
