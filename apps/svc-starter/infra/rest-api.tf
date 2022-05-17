resource "aws_api_gateway_rest_api" "rest_api" {
  name        = "${var.app_name}.${var.environment_name}.rest-api"
  description = "An API for demonstrating CORS-enabled methods."
}

#region CloudWatch

resource "aws_cloudwatch_log_group" "rest_api" {
  name = "/aws/api_gw/${aws_api_gateway_rest_api.rest_api.name}"

  retention_in_days = 30
}

resource "aws_api_gateway_account" "rest_api" {
  cloudwatch_role_arn = aws_iam_role.rest_api_cloudwatch.arn
}

data "aws_iam_policy_document" "rest_api_cloudwatch" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["apigateway.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "rest_api_cloudwatch" {
  name               = "${var.app_name}.${var.environment_name}.api-gateway"
  assume_role_policy = data.aws_iam_policy_document.rest_api_cloudwatch.json
}

resource "aws_iam_role_policy_attachment" "rest_api_cloudwatch" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
  role       = aws_iam_role.rest_api_cloudwatch.name
}

#endregion

#region Stage


resource "aws_api_gateway_deployment" "default" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id

  triggers = {
    redeployment = sha1(jsonencode(["testing"]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "default" {
  deployment_id = aws_api_gateway_deployment.default.id
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  stage_name    = "default"

  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.rest_api.arn

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

#endregion

resource "aws_api_gateway_resource" "proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id

  path_part = "{proxy+}"
}

#region Service Function

resource "aws_api_gateway_method" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.proxy_resource.id

  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.proxy_resource.id
  http_method = aws_api_gateway_method.proxy.http_method

  type                    = "AWS_PROXY"
  integration_http_method = "POST"

  uri = aws_lambda_function.svc_function.invoke_arn
}

#endregion

#region CORS Method

resource "aws_api_gateway_method" "proxy_cors" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.proxy_resource.id

  http_method   = "OPTIONS"
  authorization = "NONE"
}


resource "aws_api_gateway_integration" "proxy_cors" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_method.proxy_cors.resource_id
  http_method = aws_api_gateway_method.proxy_cors.http_method

  type = "MOCK"

  depends_on = [aws_api_gateway_method.proxy_cors]
}

resource "aws_api_gateway_method_response" "proxy_cors" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_method.proxy_cors.resource_id
  http_method = aws_api_gateway_method.proxy_cors.http_method

  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [aws_api_gateway_method.proxy_cors]
}


resource "aws_api_gateway_integration_response" "proxy_cors" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_method.proxy_cors.resource_id
  http_method = aws_api_gateway_method.proxy_cors.http_method

  status_code = aws_api_gateway_method_response.proxy_cors.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_method_response.proxy_cors]
}

#endregion
