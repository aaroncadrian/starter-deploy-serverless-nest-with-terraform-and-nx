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
  bucket_name    = "${var.app_name}.${var.environment_name}"
  dist_directory = "${path.module}/../../../dist/apps/${var.app_name}"
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

resource "aws_s3_bucket_object" "dist" {
  for_each = fileset(local.dist_directory, "*")
  bucket   = aws_s3_bucket.site.id
  key      = each.value
  source   = "${local.dist_directory}/${each.value}"
  etag     = filemd5("${local.dist_directory}/${each.value}")
}

#endregion
