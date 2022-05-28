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

module "frontend_dist" {
  source = "./modules/frontend-serverless-dist"

  bucket_name    = "${var.app_name}-${var.environment_name}"
  dist_directory = "${path.module}/../../../dist/apps/${var.app_name}"
}
