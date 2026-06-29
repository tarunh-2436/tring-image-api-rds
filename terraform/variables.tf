variable "db_password" {
  type      = string
  sensitive = true
}

variable "notification_email" {
  type = string
}

###############################################
# CI/CD
###############################################

variable "github_owner" {

  description = "GitHub repository owner."

  type = string
}

variable "github_repository" {

  description = "GitHub repository name."

  type = string
}

variable "github_connection_arn" {

  description = "CodeStar Connection ARN."

  type = string
}