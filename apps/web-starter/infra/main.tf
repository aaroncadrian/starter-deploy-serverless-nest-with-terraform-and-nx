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

module "frontend_bucket" {
  source = "./modules/frontend-s3-bucket"

  bucket_name    = "${var.app_name}-${var.environment_name}"
  dist_directory = "${path.module}/../../../dist/apps/${var.app_name}"
}

module "cf_s3_dist" {
  source    = "./modules/cloudfront-s3-dist"
  s3_bucket = {
    id                          = module.frontend_bucket.bucket_id
    arn                         = module.frontend_bucket.bucket_arn
    bucket_regional_domain_name = module.frontend_bucket.bucket_regional_domain_name
  }
}
