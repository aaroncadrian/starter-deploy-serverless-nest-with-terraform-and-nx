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

#region IAM for Lambda

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.app_name}.${var.environment_name}.lambda-policy"

  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid    = "Stmt1652579297004"
        Action = [
          "dynamodb:Query",
          "dynamodb:GetItem",
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.primary_table.arn
      }
    ]
  })
}


resource "aws_iam_role" "lambda_role" {
  name = "${var.app_name}.${var.environment_name}.lambda-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })
}

#endregion
