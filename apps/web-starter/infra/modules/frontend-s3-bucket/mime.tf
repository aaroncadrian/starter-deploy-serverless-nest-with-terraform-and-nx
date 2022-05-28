locals {
  # Source: https://engineering.statefarm.com/blog/terraform-s3-upload-with-mime/
  # Source: https://dev.to/aws-builders/build-a-static-website-using-s3-route-53-with-terraform-1ele
  mime_types = jsondecode(file("${path.module}/data/mime.json"))
}
