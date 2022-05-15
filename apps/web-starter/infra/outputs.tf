output "cloudfront_domain_name" {
  description = "The domain name to access the CloudFront distribution"
  value       = aws_cloudfront_distribution.site.domain_name
}
