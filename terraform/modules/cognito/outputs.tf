output "user_pool_id" {
  description = "User Pool ID"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "User Pool ARN"
  value       = aws_cognito_user_pool.this.arn
}

output "user_pool_client_id" {
  description = "User Pool Client ID"
  value       = aws_cognito_user_pool_client.this.id
}

output "user_pool_domain" {
  description = "Hosted UI domain"
  value       = aws_cognito_user_pool_domain.this.domain
}

output "issuer" {
  description = "JWT issuer URL"
  value       = aws_cognito_user_pool.this.endpoint
}