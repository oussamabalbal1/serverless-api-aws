# iam.tf

# -----------------------------------------------------------------------------
# IAM ROLE FOR LAMBDA
# This IAM role grants the Lambda function permissions to run and access other
# AWS services.
# -----------------------------------------------------------------------------
resource "aws_iam_role" "lambda_exec_role" {
  name = "${random_pet.unique_name.id}-lambda-exec-role"

  # The assume_role_policy allows the Lambda service to assume this role.
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = "project-${random_pet.unique_name.id}"
  }
}

# -----------------------------------------------------------------------------
# IAM POLICY FOR LAMBDA
# This policy defines the specific permissions for the Lambda function.
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "lambda_policy" {
  name        = "${random_pet.unique_name.id}-lambda-policy"
  description = "Policy for Lambda function to access DynamoDB and CloudWatch Logs."

  # The policy document grants permissions.
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      # Permission for full CRUD operations on the DynamoDB table.
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.user_data_table.arn
      },
      # Permissions to create and write to CloudWatch Logs for logging.
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# IAM ROLE POLICY ATTACHMENT
# This resource attaches the policy to the Lambda execution role.
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
