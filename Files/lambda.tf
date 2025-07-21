# lambda.tf

# -----------------------------------------------------------------------------
# DATA SOURCE: ARCHIVE FILE
# This data source zips the Lambda function code from the 'lambda_code' directory.
# Terraform will handle the packaging process automatically.
# -----------------------------------------------------------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_code"
  output_path = "${path.module}/lambda.zip"
}

# -----------------------------------------------------------------------------
# LAMBDA FUNCTION RESOURCE
# This resource creates the AWS Lambda function.
# -----------------------------------------------------------------------------
resource "aws_lambda_function" "data_handler_lambda" {
  # The function name is derived from the project_name variable.
  function_name    = "data-lambda-${random_pet.unique_name.id}"
  
  # The IAM role the function will assume.
  role          = aws_iam_role.lambda_exec_role.arn
  
  # The path to the zipped deployment package.
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  
  # The function's entry point. 'index.handler' means the 'handler' export
  # in the 'index.mjs' file.
  handler       = "index.handler"
  
  # The runtime environment for the function.
  runtime       = "nodejs20.x"
  
  # The amount of memory allocated to the function.
  memory_size   = 128
  
  # The maximum amount of time the function can run for.
  timeout       = 30

  # Environment variables passed to the Lambda function.
  # We pass the DynamoDB table name so the function knows where to store data.
  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.user_data_table.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attach,
    aws_dynamodb_table.user_data_table
  ]

  tags = {
    Project = "project-${random_pet.unique_name.id}"
  }
}

# -----------------------------------------------------------------------------
# CLOUDWATCH LOG GROUP
# This resource creates a log group for the Lambda function, which is essential
# for debugging and monitoring.
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.data_handler_lambda.function_name}"
  retention_in_days = 14 # Retain logs for 14 days.

  tags = {
    Project = "project-${random_pet.unique_name.id}"
  }
}
