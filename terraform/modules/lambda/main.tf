resource "aws_cloudwatch_log_group" "this" {

  name = "/aws/lambda/${var.function_name}"

  retention_in_days = 30

  tags = var.tags
}

resource "aws_lambda_function" "this" {

  function_name = var.function_name

  role = var.role_arn

  runtime = var.runtime

  handler = var.handler

  filename         = var.deployment_package
  source_code_hash = filebase64sha256(var.deployment_package)

  memory_size = var.memory_size

  timeout = var.timeout

  architectures = [
    "arm64"
  ]

  environment {
    variables = var.environment_variables
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  depends_on = [
    aws_cloudwatch_log_group.this
  ]

  tags = var.tags
}