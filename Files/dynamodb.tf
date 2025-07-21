# dynamodb.tf

# -----------------------------------------------------------------------------
# DYNAMODB TABLE RESOURCE
# This resource creates a DynamoDB table to store user data.
# -----------------------------------------------------------------------------
resource "aws_dynamodb_table" "user_data_table" {
  # The name of the table is constructed using the project_name variable.
  name         = "user-data-${random_pet.unique_name.id}"
  
  # Set billing mode to PROVISIONED to be eligible for the AWS Free Tier.
  billing_mode = "PROVISIONED"
  
  # Specify read and write capacity within the Free Tier limits (<= 25 each).
  read_capacity  = 5
  write_capacity = 5
  
  # Defines the primary key for the table.
  # 'userId' is the partition key.
  hash_key     = "userId"

  # Defines the attributes of the table. An attribute is a fundamental data element.
  # 'userId' is defined as a string type attribute.
  attribute {
    name = "userId"
    type = "S" # S stands for String
  }

  # Tags are key-value pairs that help you manage, identify, organize, search for,
  # and filter resources.
  tags = {
    Name        = "user-data-table"
    Project     = "project-${random_pet.unique_name.id}"
  }
}
