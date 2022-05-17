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

  role = aws_iam_role.lambda_exec.id

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


resource "aws_iam_role" "lambda_exec" {
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

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#endregion

#region Lambda Function

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../../../dist/apps/${var.app_name}/main.js"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "svc_function" {
  function_name = "${var.app_name}_${var.environment_name}"

  handler          = "main.handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role = aws_iam_role.lambda_exec.arn

  runtime = var.lambda_runtime

  environment {
    variables = {
      DYNAMO_TABLE_NAME = aws_dynamodb_table.primary_table.name
    }
  }
}

#endregion

#region API Gateway

resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.app_name}.${var.environment_name}.http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
  }
}

resource "aws_apigatewayv2_stage" "http_api_default" {
  api_id = aws_apigatewayv2_api.http_api.id

  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.http_api.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }
}

resource "aws_cloudwatch_log_group" "http_api" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.http_api.name}"

  retention_in_days = 30
}

#endregion

#region API Gateway Route/Integration

resource "aws_apigatewayv2_integration" "svc_function" {
  api_id = aws_apigatewayv2_api.http_api.id

  integration_uri    = aws_lambda_function.svc_function.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "svc_function" {
  api_id = aws_apigatewayv2_api.http_api.id

  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.svc_function.id}"
}

resource "aws_lambda_permission" "api_gw_svc_function" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.svc_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

#endregion
