resource "aws_codepipeline" "this" {

  name     = var.pipeline_name
  role_arn = var.service_role_arn

  pipeline_type = "V2"

  artifact_store {

    location = var.artifact_bucket_name

    type = "S3"
  }

  ####################################################
  # Source Stage
  ####################################################

  stage {

    name = "Source"

    action {

      name = "Source"

      category = "Source"

      owner = "AWS"

      provider = "CodeStarSourceConnection"

      version = "1"

      output_artifacts = ["source_output"]

      configuration = {

        ConnectionArn    = var.github_connection_arn
        FullRepositoryId = "${var.github_owner}/${var.github_repository}"
        BranchName       = var.github_branch
      }
    }
  }

  ####################################################
  # Build Stage
  ####################################################

  stage {

    name = "Build"

    action {

      name = "Build"

      category = "Build"

      owner = "AWS"

      provider = "CodeBuild"

      version = "1"

      input_artifacts = ["source_output"]

      configuration = {

        ProjectName = var.codebuild_project_name
      }
    }
  }
}