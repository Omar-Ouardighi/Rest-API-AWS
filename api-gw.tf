resource "aws_api_gateway_rest_api" "api-gw" {
  name = "destination-api-gw"
  description = "API Gateway for travel destinations"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "destinations" {
  rest_api_id = aws_api_gateway_rest_api.api-gw.id
  parent_id = aws_api_gateway_rest_api.api-gw.root_resource_id
  path_part = "destinations"
}

resource "aws_api_gateway_method" "get_all_destinations" {
  rest_api_id = aws_api_gateway_rest_api.api-gw.id
  resource_id = aws_api_gateway_resource.destinations.id
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "GET_all_lambda_integration" {
    rest_api_id = aws_api_gateway_rest_api.api-gw.id
    resource_id = aws_api_gateway_resource.destinations.id
    http_method = aws_api_gateway_method.get_all_destinations.http_method
    integration_http_method = "POST"
    type = "AWS_PROXY"
    uri = aws_lambda_function.my_lambda.invoke_arn
  
}
resource "aws_api_gateway_method_response" "GET_all_method_response_200" {
    rest_api_id = aws_api_gateway_rest_api.api-gw.id
    resource_id = aws_api_gateway_resource.destinations.id
    http_method = aws_api_gateway_method.get_all_destinations.http_method
    status_code = "200"
    response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true,
    "method.response.header.Access-Control-Allow-Methods"     = true,
    "method.response.header.Access-Control-Allow-Origin"      = true,
    "method.response.header.Access-Control-Allow-Credentials" = true
  }

  
}
resource "aws_api_gateway_integration_response" "GET_all_integration_response" {
    rest_api_id = aws_api_gateway_rest_api.api-gw.id
    resource_id = aws_api_gateway_resource.destinations.id
    http_method = aws_api_gateway_method.get_all_destinations.http_method
    status_code = aws_api_gateway_method_response.GET_all_method_response_200.status_code
    depends_on = [aws_api_gateway_integration.GET_all_lambda_integration]
    response_templates = {
    "application/json" = <<EOF
    #set($inputRoot = $input.path('$.body'))
    {
      \"statusCode\": 200,
      \"body\": $inputRoot,
      \"headers\": {
        \"Content-Type\": \"application/json\"
      }
    }
    EOF
  }
}

resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api-gw.execution_arn}/*/*"
}


# Deployement
resource "aws_api_gateway_deployment" "api-gw-deployment" {
  depends_on = [aws_api_gateway_integration.GET_all_lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.api-gw.id
  stage_name = "dev"
}
