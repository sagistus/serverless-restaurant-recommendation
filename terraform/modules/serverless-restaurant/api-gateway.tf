resource "aws_api_gateway_rest_api" "restaurant_api" {
  name        = "RestaurantRecommendationAPI"
  description = "API for restaurant recommendations based on filters"
}

resource "aws_api_gateway_resource" "recommend" {
  rest_api_id = aws_api_gateway_rest_api.restaurant_api.id
  parent_id   = aws_api_gateway_rest_api.restaurant_api.root_resource_id
  path_part   = "recommend"
}

resource "aws_api_gateway_method" "recommend_get" {
  rest_api_id   = aws_api_gateway_rest_api.restaurant_api.id
  resource_id   = aws_api_gateway_resource.recommend.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.restaurant_api.id
  resource_id             = aws_api_gateway_resource.recommend.id
  http_method             = aws_api_gateway_method.recommend_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.restaurant_lambda.invoke_arn
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.restaurant_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.restaurant_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [aws_api_gateway_integration.lambda]
  rest_api_id = aws_api_gateway_rest_api.restaurant_api.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.restaurant_api.id
  stage_name    = var.environment == "prod" ? "prod" : "dev"
}

resource "aws_api_gateway_method_settings" "method_settings" {
  rest_api_id = aws_api_gateway_rest_api.restaurant_api.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = var.environment == "prod" ? true : false
    logging_level          = "INFO"
    throttling_burst_limit = var.environment == "prod" ? 500 : 50
    throttling_rate_limit  = var.environment == "prod" ? 200 : 20
  }
}

output "api_gateway_url" {
  value = "https://${aws_api_gateway_rest_api.restaurant_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/recommend"
}
