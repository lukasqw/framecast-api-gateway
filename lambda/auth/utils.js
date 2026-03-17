/**
 * Utility functions for CPF authentication Lambda
 */

/**
 * Validates CPF format and check digits
 * @param {string} cpf - CPF string (numbers only)
 * @returns {boolean} - True if valid
 */
function isValidCPFFormat(cpf) {
  // Check if CPF has 11 digits
  if (!/^\d{11}$/.test(cpf)) {
    return false;
  }

  // Check for known invalid CPFs (all same digits)
  if (/^(\d)\1{10}$/.test(cpf)) {
    return false;
  }

  // Validate check digits
  let sum = 0;
  let remainder;

  // First check digit
  for (let i = 1; i <= 9; i++) {
    sum += parseInt(cpf.substring(i - 1, i)) * (11 - i);
  }
  remainder = (sum * 10) % 11;
  if (remainder === 10 || remainder === 11) remainder = 0;
  if (remainder !== parseInt(cpf.substring(9, 10))) return false;

  // Second check digit
  sum = 0;
  for (let i = 1; i <= 10; i++) {
    sum += parseInt(cpf.substring(i - 1, i)) * (12 - i);
  }
  remainder = (sum * 10) % 11;
  if (remainder === 10 || remainder === 11) remainder = 0;
  if (remainder !== parseInt(cpf.substring(10, 11))) return false;

  return true;
}

/**
 * Removes formatting from CPF
 * @param {string} cpf - CPF with or without formatting
 * @returns {string} - Clean CPF (numbers only)
 */
function cleanCPFFormat(cpf) {
  return cpf.replace(/[^\d]/g, "");
}

/**
 * Generates standardized error response
 * @param {number} statusCode - HTTP status code
 * @param {string} message - Error message
 * @param {object} details - Additional error details
 * @returns {object} - Lambda response object
 */
function errorResponse(statusCode, message, details = {}) {
  return {
    statusCode,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers":
        "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
      "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
    },
    body: JSON.stringify({
      error: true,
      message,
      timestamp: new Date().toISOString(),
      ...details,
    }),
  };
}

/**
 * Generates standardized success response
 * @param {object} data - Response data
 * @param {number} statusCode - HTTP status code (default: 200)
 * @returns {object} - Lambda response object
 */
function successResponse(data, statusCode = 200) {
  return {
    statusCode,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers":
        "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
      "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
    },
    body: JSON.stringify({
      success: true,
      data,
      timestamp: new Date().toISOString(),
    }),
  };
}

module.exports = {
  isValidCPFFormat,
  cleanCPFFormat,
  errorResponse,
  successResponse,
};
