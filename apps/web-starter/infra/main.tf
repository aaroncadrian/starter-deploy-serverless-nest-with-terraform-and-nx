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
  bucket_name    = "${var.app_name}-${var.environment_name}"
  dist_directory = "${path.module}/../../../dist/apps/${var.app_name}"

  # Source: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html
  caching_optimized_cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

  # Source: https://engineering.statefarm.com/blog/terraform-s3-upload-with-mime/
  # Source: https://dev.to/aws-builders/build-a-static-website-using-s3-route-53-with-terraform-1ele
  mime_types = {
    ".html" = "text/html"
    ".js"   = "application/javascript"
    ".css"  = "text/css"
    ".txt"  = "text/plain"
    ".ico"  = "image/x-icon"
  }
}

#region S3 Bucket

resource "aws_s3_bucket" "site" {
  bucket = local.bucket_name

  force_destroy = true
}

resource "aws_s3_bucket_acl" "site" {
  bucket = aws_s3_bucket.site.id

  acl = "private"
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object" "dist" {
  for_each     = fileset(local.dist_directory, "*")
  bucket       = aws_s3_bucket.site.id
  key          = each.value
  source       = "${local.dist_directory}/${each.value}"
  etag         = filemd5("${local.dist_directory}/${each.value}")
  content_type = lookup(local.mime_types, regex("\\.[^.]+$", "${local.dist_directory}/${each.value}"), null)
}

resource "aws_s3_bucket_policy" "read_site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.read_site_bucket.json
}

#endregion

#region CloudFront Distribution

resource "aws_cloudfront_origin_access_identity" "site" {
  comment = "Allows CloudFront to reach ${aws_s3_bucket.site.id}"
}

data "aws_iam_policy_document" "read_site_bucket" {
  version   = "2008-10-17"
  policy_id = "PolicyForCloudFrontPrivateContent"

  statement {
    sid       = "1"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.site.iam_arn]
    }
  }
}

resource "aws_cloudfront_distribution" "site" {
  enabled = true

  is_ipv6_enabled = true

  comment = "Terraform distribution for ${local.bucket_name}"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.site.bucket_regional_domain_name
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  origin {
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.site.bucket_regional_domain_name

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
    #    ssl_support_method             = "vip"
    #    minimum_protocol_version       = "TLSv1"
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
