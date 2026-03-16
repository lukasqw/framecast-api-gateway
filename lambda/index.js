const jwt = require("jsonwebtoken");

/**
 * Lambda Authorizer for API Gateway
 * Validates JWT tokens and returns IAM policy
 */
exports.handler = async (event) => {
  console.log("Authorizer event:", JSON.stringify(event, null, 2));
  console.log("Environment variables:", {
    JWT_SECRET: process.env.JWT_SECRET ? "SET" : "NOT SET",
  });

  const token = event.authorizationToken;
  const methodArn = event.methodArn;

  if (!token) {
    console.error("No authorization token provided");
    throw new Error("Unauthorized");
  }

  if (!methodArn) {
    console.error("No method ARN provided");
    throw new Error("Unauthorized");
  }

  console.log("Processing token:", token.substring(0, 20) + "...");

  try {
    // Remove 'Bearer ' prefix if present
    const tokenValue = token.startsWith("Bearer ") ? token.substring(7) : token;

    // Verify JWT token
    const decoded = jwt.verify(tokenValue, process.env.JWT_SECRET);

    console.log("Decoded token:", JSON.stringify(decoded, null, 2));

    // Extract user information from token
    const userId = decoded.user_id || decoded.sub;
    const userRole = decoded.role || "USER";
    const userEmail = decoded.email || "";

    // Generate IAM policy
    const policy = generatePolicy(userId, "Allow", methodArn, {
      userId: userId,
      role: userRole,
      email: userEmail,
    });

    console.log("Generated policy:", JSON.stringify(policy, null, 2));

    return policy;
  } catch (error) {
    console.error("Authorization error:", error);

    // Return explicit deny for invalid tokens
    if (error.name === "TokenExpiredError") {
      throw new Error("Token expired");
    } else if (error.name === "JsonWebTokenError") {
      throw new Error("Invalid token");
    }

    throw new Error("Unauthorized");
  }
};

/**
 * Generate IAM policy document
 */
function generatePolicy(principalId, effect, resource, context) {
  const authResponse = {
    principalId: principalId,
  };

  if (effect && resource) {
    const policyDocument = {
      Version: "2012-10-17",
      Statement: [
        {
          Action: "execute-api:Invoke",
          Effect: effect,
          Resource: resource,
        },
      ],
    };
    authResponse.policyDocument = policyDocument;
  }

  // Add context to pass to backend
  if (context) {
    authResponse.context = {
      userId: context.userId || "",
      role: context.role || "",
      email: context.email || "",
    };
  }

  return authResponse;
}
