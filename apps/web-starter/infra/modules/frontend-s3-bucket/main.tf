resource "aws_s3_bucket" "site" {
  bucket = var.bucket_name

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
  for_each     = fileset(var.dist_directory, "*")
  bucket       = aws_s3_bucket.site.id
  key          = each.value
  source       = "${var.dist_directory}/${each.value}"
  etag         = filemd5("${var.dist_directory}/${each.value}")
  content_type = lookup(local.mime_types, regex("\\.[^.]+$", "${var.dist_directory}/${each.value}"), null)
}
