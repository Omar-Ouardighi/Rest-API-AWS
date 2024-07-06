provider "aws" {
    profile = "default"
  region = "eu-west-1"
}

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