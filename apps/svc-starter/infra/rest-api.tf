resource "aws_api_gateway_rest_api" "rest_api" {
  name        = "${var.app_name}.${var.environment_name}.rest-api"
  description = "An API for demonstrating CORS-enabled methods."
}

#region Stage

resource "aws_api_gateway_deployment" "default" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id


  triggers = {
    redeployment = sha1(jsonencode(["testing22"]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_integration.proxy]
}

resource "aws_api_gateway_stage" "default" {
  deployment_id = aws_api_gateway_deployment.default.id
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  stage_name    = "default"
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
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  type                    = "AWS_PROXY"
  integration_http_method = "POST"

  uri = aws_lambda_function.svc_function.invoke_arn
}

resource "aws_lambda_permission" "proxy_function" {
  statement_id  = "AllowExecutionFromAPIGatewayProxy"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.svc_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*/*"
}

#endregion

#region CORS Method
#
#resource "aws_api_gateway_method" "proxy_cors" {
#  rest_api_id = aws_api_gateway_rest_api.rest_api.id
#  resource_id = aws_api_gateway_resource.proxy_resource.id
#
#  http_method   = "OPTIONS"
#  authorization = "NONE"
#}
#
#
#resource "aws_api_gateway_integration" "proxy_cors" {
#  rest_api_id = aws_api_gateway_rest_api.rest_api.id
#  resource_id = aws_api_gateway_method.proxy_cors.resource_id
#  http_method = aws_api_gateway_method.proxy_cors.http_method
#
#  type = "MOCK"
#
#  depends_on = [aws_api_gateway_method.proxy_cors]
#}
#
#resource "aws_api_gateway_method_response" "proxy_cors" {
#  rest_api_id = aws_api_gateway_rest_api.rest_api.id
#  resource_id = aws_api_gateway_method.proxy_cors.resource_id
#  http_method = aws_api_gateway_method.proxy_cors.http_method
#
#  status_code = "200"
#
#  response_models = {
#    "application/json" = "Empty"
#  }
#
#  response_parameters = {
#    "method.response.header.Access-Control-Allow-Headers" = true,
#    "method.response.header.Access-Control-Allow-Methods" = true,
#    "method.response.header.Access-Control-Allow-Origin"  = true
#  }
#
#  depends_on = [aws_api_gateway_method.proxy_cors]
#}
#
#
#resource "aws_api_gateway_integration_response" "proxy_cors" {
#  rest_api_id = aws_api_gateway_rest_api.rest_api.id
#  resource_id = aws_api_gateway_method.proxy_cors.resource_id
#  http_method = aws_api_gateway_method.proxy_cors.http_method
#
#  status_code = aws_api_gateway_method_response.proxy_cors.status_code
#
#  response_parameters = {
#    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
#    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
#    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
#  }
#
#  depends_on = [aws_api_gateway_method_response.proxy_cors]
#}

#endregion
