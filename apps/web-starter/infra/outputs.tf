output "cloudfront_domain_name" {
  description = "The domain name to access the CloudFront distribution"
  value       = module.frontend_dist.cloudfront_domain_name
}
