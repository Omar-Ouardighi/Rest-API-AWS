provider "aws" {
    profile = "default"
  region = "eu-west-1"
}

# Create the Lambda function
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda.py"
  output_path = "lambda_code.zip"
}

resource "aws_lambda_function" "my_lambda" {
    filename = data.archive_file.lambda.output_path
    function_name = "api-gw-lambda"
    role = aws_iam_role.iam_for_lambda.arn
    runtime = "python3.12"
    handler = "lambda.handler"

} 

# Create the DynamoDB table
resource "aws_dynamodb_table" "travel_destinations_table" {
  name           = "TravelDestinations"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "DestinationID"
  attribute {
    name = "DestinationID"
    type = "S"
  }
  tags = {
    name = "travel_destinations_table"
  }
}

locals {
  json_data = file("${path.module}/destinations.json")
  destinations = jsondecode(local.json_data)
}

# Populate the DynamoDB table
resource "aws_dynamodb_table_item" "destinations" {
  for_each = local.destinations
  table_name = aws_dynamodb_table.travel_destinations_table.name
  hash_key = aws_dynamodb_table.travel_destinations_table.hash_key
  item = jsonencode(each.value)
}
