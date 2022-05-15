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

#region DynamoDB

resource "aws_dynamodb_table" "primary_table" {
  hash_key  = "pk"
  range_key = "sk"

  name = "${var.app_name}.${var.environment_name}"

  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }
}

#endregion
