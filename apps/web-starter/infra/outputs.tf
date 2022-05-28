output "cloudfront_domain_name" {
  description = "The domain name to access the CloudFront distribution"
  value       = module.cf_s3_dist.domain_name
}
