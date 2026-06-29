variable "pipeline_name" {
  description = "CodePipeline name."
  type        = string
}

variable "service_role_arn" {
  description = "IAM role ARN for CodePipeline."
  type        = string
}

variable "artifact_bucket_name" {
  description = "S3 bucket for pipeline artifacts."
  type        = string
}

variable "codebuild_project_name" {
  description = "CodeBuild project name."
  type        = string
}

variable "github_owner" {
  description = "GitHub repository owner."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository name."
  type        = string
}

variable "github_branch" {
  description = "GitHub branch."
  type        = string
  default     = "main"
}

variable "github_connection_arn" {
  description = "ARN of the CodeStar Connections connection."
  type        = string
}