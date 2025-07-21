  // lambda_code/index.mjs

  // Import AWS SDK v3 clients
  import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
  import { 
      DynamoDBDocumentClient, 
      PutCommand, 
      ScanCommand, 
      GetCommand,
      UpdateCommand,
      DeleteCommand
  } from "@aws-sdk/lib-dynamodb";
  import { randomUUID } from "crypto";

  // Initialize the DynamoDB Document Client
  const client = new DynamoDBClient({});
  const docClient = DynamoDBDocumentClient.from(client);

  // Retrieve the table name from environment variables
  const tableName = process.env.DYNAMODB_TABLE_NAME;

  /**
  * The main handler for the Lambda function.
  * It routes requests based on the HTTP method and the resource path.
  * @param {object} event - The event object from API Gateway.
  * @returns {object} A response object for API Gateway.
  */
  export const handler = async (event) => {
      console.log("Received event:", JSON.stringify(event, null, 2));

      if (!tableName) {
          return createResponse(500, { message: "Internal server error: Configuration missing." });
      }

      // Destructure properties from the API Gateway event object
      const { httpMethod, resource, pathParameters, body } = event;
      const userId = pathParameters?.userId;

      // --- Request Routing ---

      // Route for general /users collection
      if (resource === "/users") {
          if (httpMethod === "POST") return await createUser(body);
          if (httpMethod === "GET") return await getAllUsers();
      }
      
      // Route for specific /users/{userId} item
      if (resource === "/users/{userId}") {
          if (!userId) {
              return createResponse(400, { message: "User ID is missing in the path." });
          }
          if (httpMethod === "GET") return await getUserById(userId);
          if (httpMethod === "PATCH") return await updateUser(userId, body);
          if (httpMethod === "DELETE") return await deleteUser(userId);
      }

      // Fallback for any unhandled routes
      return createResponse(404, { message: `Method ${httpMethod} on resource ${resource} not found.` });
  };

  // --- Handler Functions for Each CRUD Operation ---

  /**
  * Creates a new user item in DynamoDB.
  * Triggered by: POST /users
  */
  const createUser = async (body) => {
      let requestBody;
      try {
          requestBody = JSON.parse(body);
      } catch (e) {
          return createResponse(400, { message: "Invalid JSON format in request body." });
      }

      const item = {
          userId: randomUUID(),
          ...requestBody,
          createdAt: new Date().toISOString(),
      };

      const command = new PutCommand({ TableName: tableName, Item: item });
      // Use the helper to execute and create a response
      return await executeDbCommand(command, 201, { message: "User created successfully.", userId: item.userId });
  };

  /**
  * Retrieves all user items from DynamoDB.
  * Triggered by: GET /users
  */
  const getAllUsers = async () => {
      // Note: A production app should handle pagination for Scan operations.
      const command = new ScanCommand({ TableName: tableName });
      return await executeDbCommand(command, 200);
  };

  /**
  * Retrieves a single user item by its ID.
  * Triggered by: GET /users/{userId}
  */
//   const getUserById = async (userId) => {
//       const command = new GetCommand({ TableName: tableName, Key: { userId } });
//       const result = await executeDbCommand(command, 200);
      
//       // After getting the result, check if the user was actually found
//       if (result.statusCode === 200 && !JSON.parse(result.body).Item) {
//           return createResponse(404, { message: "User not found." });
//       }
//       return result;
//   };


const getUserById = async (userId) => {
    // Define the command to get a specific item
    const command = new GetCommand({ 
        TableName: tableName, 
        Key: { userId } 
    });

    try {
        // Send the command and get the result directly
        const { Item } = await docClient.send(command);

        // Check if the Item property exists in the result
        if (Item) {
            // If the item was found, return it with a 200 OK status
            return createResponse(200, Item);
        } else {
            // If the item was not found, return a 404 Not Found status
            return createResponse(404, { message: "User not found." });
        }
    } catch (error) {
        // Handle any potential database errors
        console.error("DynamoDB error:", error);
        return createResponse(500, { message: `Failed to execute database operation: ${error.name}` });
    }
};

  /**
  * Updates an existing user's attributes.
  * Triggered by: PATCH /users/{userId}
  */
  const updateUser = async (userId, body) => {
      let requestBody;
      try {
          requestBody = JSON.parse(body);
      } catch (e) {
          return createResponse(400, { message: "Invalid JSON format in request body." });
      }

      const updateKeys = Object.keys(requestBody);
      if (updateKeys.length === 0) {
          return createResponse(400, { message: "Update payload is empty." });
      }

      // Dynamically build the UpdateExpression and related values
      const updateExpression = "set " + updateKeys.map(k => `#${k} = :${k}`).join(", ");
      const expressionAttributeNames = updateKeys.reduce((acc, k) => ({ ...acc, [`#${k}`]: k }), {});
      const expressionAttributeValues = updateKeys.reduce((acc, k) => ({ ...acc, [`:${k}`]: requestBody[k] }), {});

      const command = new UpdateCommand({
          TableName: tableName,
          Key: { userId },
          UpdateExpression: updateExpression,
          ExpressionAttributeNames: expressionAttributeNames,
          ExpressionAttributeValues: expressionAttributeValues,
          ReturnValues: "ALL_NEW", // Returns the item as it appears after the update
      });

      return await executeDbCommand(command, 200);
  };

  /**
  * Deletes a user item from DynamoDB.
  * Triggered by: DELETE /users/{userId}
  */
  const deleteUser = async (userId) => {
      const command = new DeleteCommand({ TableName: tableName, Key: { userId } });
      return await executeDbCommand(command, 200, { message: "User deleted successfully." });
  };


  // --- Utility Functions ---

  /**
  * A helper function to create a consistent API Gateway response object.
  */
  const createResponse = (statusCode, body) => ({
      statusCode,
      headers: { 
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*" // Enables CORS for browser-based clients
      },
      body: JSON.stringify(body),
  });

  /**
  * A helper function to execute a DynamoDB command and handle success/error responses.
  */
  const executeDbCommand = async (command, successCode, successMessage) => {
      try {
          const result = await docClient.send(command);
          // Consolidate the response body based on different command outputs
          const body = successMessage || result.Items || result.Item || result.Attributes || {};
          return createResponse(successCode, body);
      } catch (error) {
          console.error("DynamoDB error:", error);
          return createResponse(500, { message: `Failed to execute database operation: ${error.name}` });
      }
  };
