resource "aws_codebuild_project" "this" {

  name         = var.project_name
  service_role = var.service_role_arn

  build_timeout = 30

  artifacts {

    type = "CODEPIPELINE"
  }

  environment {

    compute_type = "BUILD_GENERAL1_SMALL"

    image = "aws/codebuild/standard:7.0"

    type = "LINUX_CONTAINER"

    image_pull_credentials_type = "CODEBUILD"

    privileged_mode = false

    environment_variable {

      name = "TF_VAR_notification_email"

      value = var.notification_email_parameter

      type = "PARAMETER_STORE"
    }   

    environment_variable {

      name = "TF_VAR_github_owner"

      value = var.github_owner_parameter

      type = "PARAMETER_STORE"
    }

    environment_variable {

      name = "TF_VAR_github_repository"

      value = var.github_repository_parameter

      type = "PARAMETER_STORE"
    }

    environment_variable {

      name = "TF_VAR_github_connection_arn"

      value = var.github_connection_arn_parameter

      type = "PARAMETER_STORE"
    }

    
    environment_variable {

      name = "TF_VAR_db_password"

      value = var.db_password_parameter

      type = "PARAMETER_STORE"
    }
  }

  source {

    type      = "CODEPIPELINE"

    buildspec = "buildspec.yml"
  }

  cache {

    type = "NO_CACHE"
  }

  logs_config {

    cloudwatch_logs {

      status = "ENABLED"
    }
  }

  encryption_key = "alias/aws/s3"
}