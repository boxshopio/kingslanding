# Note: Cognito resources are commented out since you mentioned existing Cognito setup
# Uncomment and modify these if you want Terraform to manage Cognito as well

# # Cognito User Pool
# resource "aws_cognito_user_pool" "main" {
#   name = "kingslanding-users"

#   alias_attributes = ["email"]
#   auto_verified_attributes = ["email"]

#   password_policy {
#     minimum_length    = 8
#     require_lowercase = true
#     require_numbers   = true
#     require_symbols   = true
#     require_uppercase = true
#   }

#   verification_message_template {
#     default_email_option = "CONFIRM_WITH_CODE"
#     email_subject = "Your King's Landing verification code"
#     email_message = "Your verification code is {####}"
#   }

#   schema {
#     attribute_data_type      = "String"
#     developer_only_attribute = false
#     mutable                  = true
#     name                     = "email"
#     required                 = true

#     string_attribute_constraints {
#       min_length = 1
#       max_length = 256
#     }
#   }
# }

# # Cognito User Pool Client
# resource "aws_cognito_user_pool_client" "main" {
#   name         = "kingslanding-client"
#   user_pool_id = aws_cognito_user_pool.main.id

#   generate_secret                      = false
#   prevent_user_existence_errors        = "ENABLED"
#   enable_token_revocation              = true
#   enable_propagate_additional_user_context_data = false

#   explicit_auth_flows = [
#     "ALLOW_USER_SRP_AUTH",
#     "ALLOW_REFRESH_TOKEN_AUTH"
#   ]

#   supported_identity_providers = ["COGNITO"]

#   callback_urls = [
#     "https://${var.domain_name}"
#   ]

#   logout_urls = [
#     "https://${var.domain_name}"
#   ]
# }

# # Cognito Identity Pool
# resource "aws_cognito_identity_pool" "main" {
#   identity_pool_name               = "kingslanding_identity_pool"
#   allow_unauthenticated_identities = false

#   cognito_identity_providers {
#     client_id               = aws_cognito_user_pool_client.main.id
#     provider_name           = aws_cognito_user_pool.main.endpoint
#     server_side_token_check = false
#   }
# }

# # IAM role for authenticated users
# resource "aws_iam_role" "authenticated" {
#   name = "Cognito_${aws_cognito_identity_pool.main.identity_pool_name}Auth_Role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Federated = "cognito-identity.amazonaws.com"
#         }
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Condition = {
#           StringEquals = {
#             "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
#           }
#           "ForAnyValue:StringLike" = {
#             "cognito-identity.amazonaws.com:amr" = "authenticated"
#           }
#         }
#       }
#     ]
#   })
# }

# # IAM policy for authenticated users to call API Gateway
# resource "aws_iam_role_policy" "authenticated" {
#   name = "authenticated_policy"
#   role = aws_iam_role.authenticated.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "execute-api:Invoke"
#         ]
#         Resource = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
#       }
#     ]
#   })
# }

# # Cognito Identity Pool Role Attachment
# resource "aws_cognito_identity_pool_roles_attachment" "main" {
#   identity_pool_id = aws_cognito_identity_pool.main.id

#   roles = {
#     "authenticated" = aws_iam_role.authenticated.arn
#   }
# }