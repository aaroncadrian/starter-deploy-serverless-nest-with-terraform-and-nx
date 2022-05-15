# Output value definitions

output "primary_table_name" {
  description = "Name of the primary DynamoDB table."

  value = aws_dynamodb_table.primary_table.name
}

output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.svc_function.function_name
}

output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_apigatewayv2_stage.http_api_default.invoke_url
}
