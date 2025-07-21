# api_gateway.tf

# -----------------------------------------------------------------------------
# API GATEWAY REST API
# -----------------------------------------------------------------------------
resource "aws_api_gateway_rest_api" "api" {
  name        = "${random_pet.unique_name.id}-api"
  description = "API for the serverless application"
  tags = {
    Project = "project-${random_pet.unique_name.id}"
  }
}

# -----------------------------------------------------------------------------
# API GATEWAY RESOURCE: /users
# -----------------------------------------------------------------------------
resource "aws_api_gateway_resource" "users_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "users"
}

# -----------------------------------------------------------------------------
# API GATEWAY RESOURCE: /users/{userId}
# This creates a resource with a path parameter to identify a specific user.
# -----------------------------------------------------------------------------
resource "aws_api_gateway_resource" "user_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.users_resource.id
  path_part   = "{userId}" # The curly braces indicate a path parameter
}


# =============================================================================
# METHODS & INTEGRATIONS for /users
# =============================================================================

# --- POST /users ---
resource "aws_api_gateway_method" "post_users_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.users_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_users_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.users_resource.id
  http_method             = aws_api_gateway_method.post_users_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.data_handler_lambda.invoke_arn
}

# --- GET /users ---
resource "aws_api_gateway_method" "get_users_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.users_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_users_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.users_resource.id
  http_method             = aws_api_gateway_method.get_users_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.data_handler_lambda.invoke_arn
}

# =============================================================================
# METHODS & INTEGRATIONS for /users/{userId}
# =============================================================================

# --- GET /users/{userId} ---
resource "aws_api_gateway_method" "get_user_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.user_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_user_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.user_resource.id
  http_method             = aws_api_gateway_method.get_user_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.data_handler_lambda.invoke_arn
}

# --- PATCH /users/{userId} ---
resource "aws_api_gateway_method" "patch_user_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.user_resource.id
  http_method   = "PATCH"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "patch_user_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.user_resource.id
  http_method             = aws_api_gateway_method.patch_user_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.data_handler_lambda.invoke_arn
}

# --- DELETE /users/{userId} ---
resource "aws_api_gateway_method" "delete_user_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.user_resource.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "delete_user_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.user_resource.id
  http_method             = aws_api_gateway_method.delete_user_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.data_handler_lambda.invoke_arn
}


# =============================================================================
# DEPLOYMENT & PERMISSIONS
# =============================================================================

# -----------------------------------------------------------------------------
# LAMBDA PERMISSION
# -----------------------------------------------------------------------------
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayToInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_handler_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

# -----------------------------------------------------------------------------
# API GATEWAY DEPLOYMENT
# -----------------------------------------------------------------------------
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.users_resource.id,
      aws_api_gateway_resource.user_resource.id,
      aws_api_gateway_method.post_users_method.id,
      aws_api_gateway_integration.post_users_integration.id,
      aws_api_gateway_method.get_users_method.id,
      aws_api_gateway_integration.get_users_integration.id,
      aws_api_gateway_method.get_user_method.id,
      aws_api_gateway_integration.get_user_integration.id,
      aws_api_gateway_method.patch_user_method.id,
      aws_api_gateway_integration.patch_user_integration.id,
      aws_api_gateway_method.delete_user_method.id,
      aws_api_gateway_integration.delete_user_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# API GATEWAY STAGE
# -----------------------------------------------------------------------------
resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "v1"
}
