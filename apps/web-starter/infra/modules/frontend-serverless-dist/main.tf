# Source: https://www.milanvit.net/post/terraform-recipes-cloudfront-distribution-from-s3-bucket/

module "frontend_bucket" {
  source = "../frontend-s3-bucket"

  bucket_name    = var.bucket_name
  dist_directory = var.dist_directory
}

module "cf_s3_dist" {
  source    = "../cloudfront-s3-dist"
  s3_bucket = {
    id                          = module.frontend_bucket.bucket_id
    arn                         = module.frontend_bucket.bucket_arn
    bucket_regional_domain_name = module.frontend_bucket.bucket_regional_domain_name
  }
}
