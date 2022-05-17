variable "aws_region" {
  description = "The AWS region you want to deploy to"
  type        = string
  default     = "us-west-2"
}

variable "app_name" {
  description = "The name of the app you want to deploy"
  type        = string
  default     = "svc-starter"
}

variable "environment_name" {
  description = "The name of the deployment environment for your app, such as `dev` or `prod`"
  type        = string
  default     = "poc"
}

variable "lambda_runtime" {
  description = "The lambda runtime"
  type        = string
  default     = "nodejs14.x"
}
