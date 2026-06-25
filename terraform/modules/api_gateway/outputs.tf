output "api_id" {
  description = "HTTP API ID"
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "HTTP API endpoint"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "execution_arn" {
  description = "Execution ARN"
  value       = aws_apigatewayv2_api.this.execution_arn
}

output "stage_name" {
  description = "Stage name"
  value       = aws_apigatewayv2_stage.this.name
}

output "stage_invoke_url" {
  description = "Invoke URL"
  value       = aws_apigatewayv2_stage.this.invoke_url
}