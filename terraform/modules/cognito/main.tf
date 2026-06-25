resource "aws_cognito_user_pool" "this" {

  name = var.user_pool_name

  username_attributes = [
    "email"
  ]

  auto_verified_attributes = [
    "email"
  ]

  password_policy {

    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true

    temporary_password_validity_days = 7
  }

  verification_message_template {

    default_email_option = "CONFIRM_WITH_CODE"
  }

  admin_create_user_config {

    allow_admin_create_user_only = false
  }

  lambda_config {

    pre_token_generation = var.pre_token_generation_lambda_arn
  }

  mfa_configuration = "OFF"

  deletion_protection = "ACTIVE"

  tags = var.tags
}

resource "aws_cognito_user_pool_client" "this" {

  name = var.app_client_name

  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  supported_identity_providers = [
    "COGNITO"
  ]

  allowed_oauth_flows = [
    "code"
  ]

  allowed_oauth_scopes = [
    "openid",
    "email",
    "profile"
  ]

  allowed_oauth_flows_user_pool_client = true

  callback_urls = var.callback_urls

  logout_urls = var.logout_urls
}

resource "aws_cognito_user_pool_domain" "this" {

  domain = var.domain_prefix

  user_pool_id = aws_cognito_user_pool.this.id
}