# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "kingslanding.io"
  
  # Match existing configuration exactly
  username_attributes = ["email"]
  auto_verified_attributes = ["email"]
  deletion_protection = "ACTIVE"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
    temporary_password_validity_days = 7
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  username_configuration {
    case_sensitive = false
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Ignore changes to schema since standard attributes are managed by AWS
  lifecycle {
    ignore_changes = [schema]
  }

  tags = local.common_tags
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name         = "kingslanding.io"
  user_pool_id = aws_cognito_user_pool.main.id

  # Match existing configuration exactly
  refresh_token_validity = 5
  access_token_validity  = 60
  id_token_validity      = 60
  
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_AUTH", 
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  supported_identity_providers = ["COGNITO"]

  callback_urls = [
    "https://kingslanding.io",
    "https://render.kingslanding.io"
  ]

  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid", "phone", "profile"]
  allowed_oauth_flows_user_pool_client = true

  prevent_user_existence_errors        = "ENABLED"
  enable_token_revocation              = true
  enable_propagate_additional_user_context_data = false
  auth_session_validity                = 15
}

# Cognito Identity Pool
resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "kingslanding.io"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.main.id
    provider_name           = aws_cognito_user_pool.main.endpoint
    server_side_token_check = false
  }
}

# IAM role for authenticated users
resource "aws_iam_role" "authenticated" {
  name = "kingslanding.io-s3-access"
  path = "/service-role/"  # Match existing path

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach S3 Full Access policy
resource "aws_iam_role_policy_attachment" "authenticated_s3" {
  role       = aws_iam_role.authenticated.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Attach Cognito-specific policy
resource "aws_iam_role_policy_attachment" "authenticated_cognito" {
  role       = aws_iam_role.authenticated.name
  policy_arn = "arn:aws:iam::457320695046:policy/service-role/Cognito-authenticated-1758329833504"
}

# Cognito Identity Pool Role Attachment
resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id

  roles = {
    "authenticated" = aws_iam_role.authenticated.arn
  }
}