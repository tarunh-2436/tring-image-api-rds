terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "tarun-terraform-state"
    key          = "image-processing-api-rds/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}

###############################################
# Local Values
###############################################

locals {

  tags = {

    Project = "Image Processing API"
  }
}

###############################################
# Networking
###############################################

module "networking" {

  source = "./modules/networking"

  vpc_name = "image-processing-vpc"

  vpc_cidr = "10.0.0.0/16"

  availability_zones = [
    "us-east-1a",
    "us-east-1b"
  ]

  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  private_subnet_cidrs = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]

  tags = local.tags
}

###############################################
# Lambda Security Group
###############################################

resource "aws_security_group" "lambda" {

  name = "image-processing-lambda"

  description = "Security Group for Lambda Functions"

  vpc_id = module.networking.vpc_id

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = merge(
    local.tags,
    {
      Name = "image-processing-lambda"
    }
  )
}

###############################################
# Database Security Group
###############################################

resource "aws_security_group" "database" {

  name = "image-processing-database"

  description = "Security Group for PostgreSQL"

  vpc_id = module.networking.vpc_id

  tags = merge(
    local.tags,
    {
      Name = "image-processing-database"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "database_lambda" {

  security_group_id = aws_security_group.database.id

  referenced_security_group_id = aws_security_group.lambda.id

  ip_protocol = "tcp"

  from_port = 5432

  to_port = 5432
}

###############################################
# Redis Security Group
###############################################

resource "aws_security_group" "redis" {

  name = "image-processing-redis"

  description = "Security Group for Redis"

  vpc_id = module.networking.vpc_id

  tags = merge(
    local.tags,
    {
      Name = "image-processing-redis"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "redis_lambda" {

  security_group_id = aws_security_group.redis.id

  referenced_security_group_id = aws_security_group.lambda.id

  ip_protocol = "tcp"

  from_port = 6379

  to_port = 6379
}

###############################################
# Website Bucket
###############################################

module "website_bucket" {

  source = "./modules/s3"

  bucket_name = "image-processing-website"

  tags = local.tags
}

###############################################
# CloudFront
###############################################

module "cloudfront" {

  source = "./modules/cloudfront"

  distribution_name = "image-processing"

  origin_domain_name = module.website_bucket.regional_domain_name

  tags = local.tags
}

###############################################
# Website Bucket Policy
###############################################

data "aws_iam_policy_document" "website_bucket" {

  statement {

    effect = "Allow"

    principals {

      type = "Service"

      identifiers = [
        "cloudfront.amazonaws.com"
      ]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${module.website_bucket.bucket_arn}/*"
    ]

    condition {

      test = "StringEquals"

      variable = "AWS:SourceArn"

      values = [
        module.cloudfront.distribution_arn
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "website" {

  bucket = module.website_bucket.bucket_id

  policy = data.aws_iam_policy_document.website_bucket.json
}

###############################################
# Upload Bucket
###############################################

module "uploads_bucket" {

  source = "./modules/s3"

  bucket_name = "image-processing-uploads"

  tags = local.tags
}

###############################################
# Upload Bucket CORS
###############################################

resource "aws_s3_bucket_cors_configuration" "uploads" {

  bucket = module.uploads_bucket.bucket_id

  cors_rule {

    allowed_headers = [
      "*"
    ]

    allowed_methods = [
      "GET",
      "PUT",
      "HEAD"
    ]

    allowed_origins = [
      "https://${module.cloudfront.distribution_domain_name}"
    ]

    expose_headers = [
      "ETag"
    ]

    max_age_seconds = 3000
  }
}

###############################################
# Upload Bucket Lifecycle
###############################################

resource "aws_s3_bucket_lifecycle_configuration" "uploads" {

  bucket = module.uploads_bucket.bucket_id

  rule {

    id = "uploads-lifecycle"

    status = "Enabled"

    noncurrent_version_expiration {

      noncurrent_days = 30
    }
  }
}

###############################################
# Processing Queue
###############################################

module "processing_queue" {

  source = "./modules/sqs"

  queue_name = "image-processing-queue"

  tags = local.tags
}

###############################################
# Queue Policy
###############################################

data "aws_iam_policy_document" "processing_queue" {

  statement {

    effect = "Allow"

    principals {

      type = "Service"

      identifiers = [
        "s3.amazonaws.com"
      ]
    }

    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      module.processing_queue.queue_arn
    ]

    condition {

      test = "ArnEquals"

      variable = "aws:SourceArn"

      values = [
        module.uploads_bucket.bucket_arn
      ]
    }
  }
}

resource "aws_sqs_queue_policy" "processing_queue" {

  queue_url = module.processing_queue.queue_url

  policy = data.aws_iam_policy_document.processing_queue.json
}

###############################################
# Upload Bucket Notification
###############################################

resource "aws_s3_bucket_notification" "uploads" {

  bucket = module.uploads_bucket.bucket_id

  queue {

    queue_arn = module.processing_queue.queue_arn

    events = [
      "s3:ObjectCreated:*"
    ]
  }

  depends_on = [
    aws_sqs_queue_policy.processing_queue
  ]
}

###############################################
# PostgreSQL
###############################################

module "database" {

  source = "./modules/rds"

  identifier = "image-processing-db"

  database_name = "imageprocessing"

  username = var.db_username

  password = var.db_password

  subnet_ids = module.networking.private_subnet_ids

  security_group_ids = [
    aws_security_group.database.id
  ]

  tags = local.tags
}

###############################################
# Redis
###############################################

module "redis" {

  source = "./modules/redis"

  identifier = "image-processing-redis"

  subnet_ids = module.networking.private_subnet_ids

  security_group_ids = [
    aws_security_group.redis.id
  ]

  tags = local.tags
}

###############################################
# Pre Token IAM Role
###############################################

data "aws_iam_policy_document" "lambda_assume_role" {

  statement {

    effect = "Allow"

    principals {

      type = "Service"

      identifiers = [
        "lambda.amazonaws.com"
      ]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "pre_token" {

  name = "image-processing-pre-token-role"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "pre_token_logs" {

  role = aws_iam_role.pre_token.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "pre_token_vpc" {

  role = aws_iam_role.pre_token.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

###############################################
# Pre Token Lambda
###############################################

module "pre_token_lambda" {

  source = "./modules/lambda"

  function_name = "image-processing-pre-token"

  source_path = "../lambda/pre_token_generation"

  handler = "lambda_function.lambda_handler"

  role_arn = aws_iam_role.pre_token.arn

  subnet_ids = module.networking.private_subnet_ids

  security_group_ids = [
    aws_security_group.lambda.id
  ]

  environment_variables = {}

  tags = local.tags
}

###############################################
# Cognito
###############################################

module "cognito" {

  source = "./modules/cognito"

  user_pool_name = "image-processing-users"

  app_client_name = "image-processing-client"

  domain_prefix = "image-processing-api"

  callback_urls = [
    "https://${module.cloudfront.distribution_domain_name}"
  ]

  logout_urls = [
    "https://${module.cloudfront.distribution_domain_name}"
  ]

  pre_token_generation_lambda_arn = module.pre_token_lambda.function_arn

  tags = local.tags
}

###############################################
# Cognito Groups
###############################################

resource "aws_cognito_user_group" "admins" {

  name = "admins"

  user_pool_id = module.cognito.user_pool_id

  description = "Application administrators"
}

###############################################
# Notification Topic
###############################################

module "notification_topic" {

  source = "./modules/sns"

  topic_name = "image-processing-notifications"

  tags = local.tags
}

###############################################
# API Service IAM
###############################################

resource "aws_iam_role" "api" {

  name = "image-processing-api-role"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "api_logs" {

  role = aws_iam_role.api.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "api_vpc" {

  role = aws_iam_role.api.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "api_s3" {

  statement {

    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "${module.uploads_bucket.bucket_arn}/*"
    ]
  }

  statement {

    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      module.uploads_bucket.bucket_arn
    ]
  }
}

resource "aws_iam_policy" "api_s3" {

  name = "image-processing-api-s3"

  policy = data.aws_iam_policy_document.api_s3.json
}

resource "aws_iam_role_policy_attachment" "api_s3" {

  role = aws_iam_role.api.name

  policy_arn = aws_iam_policy.api_s3.arn
}

###############################################
# API Service
###############################################

module "api_lambda" {

  source = "./modules/lambda"

  function_name = "image-processing-api"

  source_path = "../lambda/api"

  handler = "lambda_function.lambda_handler"

  role_arn = aws_iam_role.api.arn

  subnet_ids = module.networking.private_subnet_ids

  security_group_ids = [
    aws_security_group.lambda.id
  ]

  environment_variables = {

    DB_HOST = module.database.endpoint

    DB_NAME = "imageprocessing"

    DB_USER = var.db_username

    DB_PASSWORD = var.db_password

    REDIS_HOST = module.redis.primary_endpoint

    UPLOAD_BUCKET = module.uploads_bucket.bucket_name
  }

  tags = local.tags
}

###############################################
# Processor Service IAM
###############################################

resource "aws_iam_role" "processor" {

  name = "image-processing-processor-role"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "processor_logs" {

  role = aws_iam_role.processor.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "processor_vpc" {

  role = aws_iam_role.processor.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

###############################################
# Processor S3 Policy
###############################################

data "aws_iam_policy_document" "processor_s3" {

  statement {

    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${module.uploads_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "processor_s3" {

  name = "image-processing-processor-s3"

  policy = data.aws_iam_policy_document.processor_s3.json
}

resource "aws_iam_role_policy_attachment" "processor_s3" {

  role = aws_iam_role.processor.name

  policy_arn = aws_iam_policy.processor_s3.arn
}

###############################################
# Processor SNS Policy
###############################################

data "aws_iam_policy_document" "processor_sns" {

  statement {

    effect = "Allow"

    actions = [
      "sns:Publish"
    ]

    resources = [
      module.notification_topic.topic_arn
    ]
  }
}

resource "aws_iam_policy" "processor_sns" {

  name = "image-processing-processor-sns"

  policy = data.aws_iam_policy_document.processor_sns.json
}

resource "aws_iam_role_policy_attachment" "processor_sns" {

  role = aws_iam_role.processor.name

  policy_arn = aws_iam_policy.processor_sns.arn
}

###############################################
# Processor Service
###############################################

module "processor_lambda" {

  source = "./modules/lambda"

  function_name = "image-processing-processor"

  source_path = "../lambda/processor"

  handler = "lambda_function.lambda_handler"

  role_arn = aws_iam_role.processor.arn

  subnet_ids = module.networking.private_subnet_ids

  security_group_ids = [
    aws_security_group.lambda.id
  ]

  environment_variables = {

    DB_HOST = module.database.endpoint

    DB_NAME = "imageprocessing"

    DB_USER = var.db_username

    DB_PASSWORD = var.db_password

    REDIS_HOST = module.redis.primary_endpoint

    UPLOAD_BUCKET = module.uploads_bucket.bucket_name

    TOPIC_ARN = module.notification_topic.topic_arn
  }

  tags = local.tags
}

###############################################
# SQS Event Source Mapping
###############################################

resource "aws_lambda_event_source_mapping" "processor" {

  event_source_arn = module.processing_queue.queue_arn

  function_name = module.processor_lambda.function_arn

  batch_size = 1

  enabled = true
}

###############################################
# API Gateway
###############################################

module "api_gateway" {

  source = "./modules/api_gateway"

  api_name = "image-processing-api"

  tags = local.tags
}

###############################################
# JWT Authorizer
###############################################

resource "aws_apigatewayv2_authorizer" "jwt" {

  api_id = module.api_gateway.api_id

  name = "cognito-authorizer"

  authorizer_type = "JWT"

  identity_sources = [
    "$request.header.Authorization"
  ]

  jwt_configuration {

    audience = [
      module.cognito.user_pool_client_id
    ]

    issuer = "https://cognito-idp.${var.aws_region}.amazonaws.com/${module.cognito.user_pool_id}"
  }
}

###############################################
# API Lambda Integration
###############################################

resource "aws_apigatewayv2_integration" "api" {

  api_id = module.api_gateway.api_id

  integration_type = "AWS_PROXY"

  integration_uri = module.api_lambda.invoke_arn

  integration_method = "POST"

  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "create_image" {

  api_id = module.api_gateway.api_id

  route_key = "POST /images"

  target = "integrations/${aws_apigatewayv2_integration.api.id}"

  authorization_type = "JWT"

  authorizer_id = aws_apigatewayv2_authorizer.jwt.id
}

resource "aws_apigatewayv2_route" "list_images" {

  api_id = module.api_gateway.api_id

  route_key = "GET /images"

  target = "integrations/${aws_apigatewayv2_integration.api.id}"

  authorization_type = "JWT"

  authorizer_id = aws_apigatewayv2_authorizer.jwt.id
}

resource "aws_apigatewayv2_route" "get_image" {

  api_id = module.api_gateway.api_id

  route_key = "GET /images/{imageId}"

  target = "integrations/${aws_apigatewayv2_integration.api.id}"

  authorization_type = "JWT"

  authorizer_id = aws_apigatewayv2_authorizer.jwt.id
}

###############################################
# API Lambda Permission
###############################################

resource "aws_lambda_permission" "api_gateway" {

  statement_id = "AllowExecutionFromAPIGateway"

  action = "lambda:InvokeFunction"

  function_name = module.api_lambda.function_name

  principal = "apigateway.amazonaws.com"

  source_arn = "${module.api_gateway.execution_arn}/*/*"
}

###############################################
# Database Migration IAM
###############################################

resource "aws_iam_role" "migration" {

  name = "image-processing-migration-role"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "migration_logs" {

  role = aws_iam_role.migration.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "migration_vpc" {

  role = aws_iam_role.migration.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

###############################################
# Database Migration Lambda
###############################################

module "migration_lambda" {

  source = "./modules/lambda"

  function_name = "image-processing-migration"

  source_path = "../lambda/migration"

  handler = "lambda_function.lambda_handler"

  role_arn = aws_iam_role.migration.arn

  subnet_ids = module.networking.private_subnet_ids

  security_group_ids = [
    aws_security_group.lambda.id
  ]

  environment_variables = {

    DB_HOST = module.database.endpoint

    DB_NAME = "imageprocessing"

    DB_USER = var.db_username

    DB_PASSWORD = var.db_password
  }

  tags = local.tags
}

###############################################
# Application Deployment
###############################################

resource "aws_s3_object" "index" {

  bucket = module.website_bucket.bucket_name

  key = "index.html"

  source = "${path.module}/../website/index.html"

  content_type = "text/html"

  etag = filemd5("${path.module}/../website/index.html")
}

resource "aws_s3_object" "styles" {

  bucket = module.website_bucket.bucket_name

  key = "styles.css"

  source = "${path.module}/../website/styles.css"

  content_type = "text/css"

  etag = filemd5("${path.module}/../website/styles.css")
}

resource "aws_s3_object" "scripts" {

  bucket = module.website_bucket.bucket_name

  key = "scripts.js"

  source = "${path.module}/../website/scripts.js"

  content_type = "application/javascript"

  etag = filemd5("${path.module}/../website/scripts.js")
}

resource "aws_s3_object" "config" {

  bucket = module.website_bucket.bucket_name

  key = "config.js"

  content = templatefile("${path.module}/../website/config.js.tpl", {

    region         = var.aws_region
    api_url        = module.api_gateway.api_endpoint
    user_pool_id   = module.cognito.user_pool_id
    client_id      = module.cognito.user_pool_client_id
    cognito_domain = module.cognito.user_pool_domain
    cloudfront_url = module.cloudfront.distribution_domain_name
  })

  content_type = "application/javascript"
}

resource "aws_sns_topic_subscription" "email" {

  topic_arn = module.notification_topic.topic_arn

  protocol = "email"

  endpoint = var.notification_email
}