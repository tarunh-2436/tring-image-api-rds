variable "project_name" {
  description = "CodeBuild project name."
  type        = string
}

variable "service_role_arn" {
  description = "IAM role ARN for CodeBuild."
  type        = string
}

variable "artifact_bucket_name" {
  description = "S3 bucket used for CodePipeline artifacts."
  type        = string
}

variable "notification_email_parameter" {

  type = string
}

variable "github_owner_parameter" {

  type = string
}

variable "github_repository_parameter" {

  type = string
}

variable "github_connection_arn_parameter" {

  type = string
}

variable "db_password_parameter" {

  type = string
}