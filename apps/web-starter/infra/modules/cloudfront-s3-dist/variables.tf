variable "s3_bucket" {
  type = object({
    id                          = string
    arn                         = string
    bucket_regional_domain_name = string
  })
}
