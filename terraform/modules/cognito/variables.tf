variable "user_pool_name" {
  description = "Name of the Cognito User Pool"
  type        = string
}

variable "app_client_name" {
  description = "Name of the User Pool App Client"
  type        = string
}

variable "domain_prefix" {
  description = "Hosted UI domain prefix"
  type        = string
}

variable "callback_urls" {
  description = "OAuth callback URLs"
  type        = list(string)
}

variable "logout_urls" {
  description = "OAuth logout URLs"
  type        = list(string)
}

variable "pre_token_generation_lambda_arn" {
  description = "ARN of the Pre Token Generation Lambda"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}