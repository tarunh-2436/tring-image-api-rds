###############################################
# CloudFront
###############################################

output "frontend_url" {
  description = "CloudFront Distribution URL"

  value = "https://${module.cloudfront.distribution_domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"

  value = module.cloudfront.distribution_id
}

###############################################
# API Gateway
###############################################

output "api_endpoint" {
  description = "HTTP API Endpoint"

  value = module.api_gateway.api_endpoint
}

###############################################
# Cognito
###############################################

output "user_pool_id" {
  description = "Cognito User Pool ID"

  value = module.cognito.user_pool_id
}

output "user_pool_client_id" {
  description = "Cognito App Client ID"

  value = module.cognito.user_pool_client_id
}

output "cognito_domain" {
  description = "Cognito Hosted UI Domain"

  value = module.cognito.user_pool_domain
}

###############################################
# S3
###############################################

output "uploads_bucket_name" {
  description = "Uploads Bucket Name"

  value = module.uploads_bucket.bucket_name
}

###############################################
# Database
###############################################

output "database_endpoint" {
  description = "PostgreSQL Endpoint"

  value = module.database.endpoint
}

###############################################
# Redis
###############################################

output "redis_endpoint" {
  description = "Redis Primary Endpoint"

  value = module.redis.primary_endpoint
}

###############################################
# CI/CD
###############################################

output "codebuild_project_name" {

  value = module.codebuild.project_name
}

output "migration_lambda_name" {

  value = module.migration_lambda.function_name
}

output "codepipeline_name" {

  value = module.codepipeline.pipeline_name
}