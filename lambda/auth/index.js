const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const { Pool } = require("pg");

// PostgreSQL connection pool (singleton pattern)
const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT, 10) || 5432,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  ssl: process.env.DB_SSL === "true" ? { rejectUnauthorized: false } : false,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

// Constants
const TOKEN_EXPIRATION = 24 * 60 * 60; // 24 hours in seconds
const CPF_LENGTH = 11;

/**
 * Lambda Function para Autenticação via CPF
 *
 * Rotas:
 * - POST /auth/login            → autentica usuários internos (USER, ADMIN, MECHANIC)
 * - POST /customers/auth/login  → autentica clientes (CUSTOMER)
 *
 * O tipo é derivado do path do evento — não é informado no body.
 */
exports.handler = async (event) => {
  console.log("Auth request received");

  try {
    // Derive entity type from the invoked path — no "type" field in body
    const resourcePath = event.resource || event.path || "";
    const entityType = resourcePath.startsWith("/customers/") ? "customer" : "user";

    // Parse and validate request body
    const body = parseRequestBody(event.body);
    const { cpf, password } = body;

    // Input validation
    const validationError = validateInput(cpf, password);
    if (validationError) {
      return validationError;
    }

    // Sanitize and validate CPF
    const cleanCPF = cleanCPFFormat(cpf);
    if (!isValidCPFFormat(cleanCPF)) {
      return errorResponse(400, "cpf inválido", "INVALID_CPF");
    }

    // Fetch entity from database
    const entity = await findEntityByCPF(cleanCPF, entityType);
    if (!entity) {
      return errorResponse(401, "credenciais inválidas", "INVALID_CREDENTIALS");
    }

    // Check if account is active
    if (entity.deleted_at) {
      return errorResponse(
        403,
        `${entityType === "customer" ? "cliente" : "usuário"} inativo`,
        "INACTIVE_ACCOUNT",
      );
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, entity.password);
    if (!isPasswordValid) {
      return errorResponse(401, "credenciais inválidas", "INVALID_CREDENTIALS");
    }

    // Generate JWT token
    const token = generateJWT(entity, entityType);

    // Return success response
    return successResponse({
      data: {
        token,
        user: buildUserResponse(entity, cleanCPF),
      },
    });
  } catch (error) {
    console.error("Authentication error:", error);
    return errorResponse(500, "erro interno no servidor", "INTERNAL_ERROR");
  }
};

/**
 * Parse request body safely
 */
function parseRequestBody(body) {
  try {
    return JSON.parse(body || "{}");
  } catch (error) {
    return {};
  }
}

/**
 * Validate input parameters
 */
function validateInput(cpf, password) {
  if (!cpf || !password) {
    return errorResponse(400, "cpf e senha são obrigatórios", "MISSING_FIELDS");
  }

  return null;
}

/**
 * Remove formatação do CPF (pontos e traços)
 */
function cleanCPFFormat(cpf) {
  return cpf.replace(/[.\-\s]/g, "");
}

/**
 * Valida formato do CPF (11 dígitos e dígitos verificadores)
 */
function isValidCPFFormat(cpf) {
  // Check if CPF has exactly 11 digits
  if (!/^\d{11}$/.test(cpf)) {
    return false;
  }

  // Check if all digits are the same (invalid CPF)
  if (/^(\d)\1{10}$/.test(cpf)) {
    return false;
  }

  // Validate check digits
  return validateCPFCheckDigits(cpf);
}

/**
 * Validate CPF check digits
 */
function validateCPFCheckDigits(cpf) {
  // First check digit
  let sum = 0;
  for (let i = 0; i < 9; i++) {
    sum += parseInt(cpf.charAt(i), 10) * (10 - i);
  }
  let remainder = (sum * 10) % 11;
  if (remainder === 10 || remainder === 11) remainder = 0;
  if (remainder !== parseInt(cpf.charAt(9), 10)) return false;

  // Second check digit
  sum = 0;
  for (let i = 0; i < 10; i++) {
    sum += parseInt(cpf.charAt(i), 10) * (11 - i);
  }
  remainder = (sum * 10) % 11;
  if (remainder === 10 || remainder === 11) remainder = 0;
  if (remainder !== parseInt(cpf.charAt(10), 10)) return false;

  return true;
}

/**
 * Fetch entity (customer or user) by CPF
 */
async function findEntityByCPF(cpf, type) {
  return type === "customer"
    ? await findCustomerByCPF(cpf)
    : await findUserByCPF(cpf);
}

/**
 * Busca cliente por CPF no banco de dados
 */
async function findCustomerByCPF(cpf) {
  const query = `
    SELECT 
      id, name, email, password, phone, 
      document, document_type, 
      created_at, updated_at, deleted_at
    FROM customers
    WHERE document = $1 AND document_type = 'CPF'
    LIMIT 1
  `;

  const result = await pool.query(query, [cpf]);
  return result.rows[0] || null;
}

/**
 * Busca usuário por CPF no banco de dados
 */
async function findUserByCPF(cpf) {
  const query = `
    SELECT 
      id, name, email, password, cpf, 
      role, description, 
      created_at, updated_at, deleted_at
    FROM users
    WHERE cpf = $1
    LIMIT 1
  `;

  const result = await pool.query(query, [cpf]);
  return result.rows[0] || null;
}

/**
 * Build user response object
 */
function buildUserResponse(entity, cpf) {
  return {
    id: entity.id,
    name: entity.name,
    cpf: cpf,
    email: entity.email,
    description: entity.description || "",
    role: entity.role || "CUSTOMER",
    created_at: entity.created_at || "",
    updated_at: entity.updated_at || "",
  };
}

/**
 * Gera token JWT
 */
function generateJWT(entity, type) {
  const now = Math.floor(Date.now() / 1000);

  const payload = {
    user_id: entity.id,
    sub: entity.id,
    email: entity.email,
    name: entity.name,
    cpf: entity.cpf || entity.document,
    role: entity.role || "CUSTOMER",
    type: type,
    iat: now,
    exp: now + TOKEN_EXPIRATION,
    iss: "oficina-tech",
    aud: "oficina-tech-api",
  };

  return jwt.sign(payload, process.env.JWT_SECRET, {
    algorithm: "HS256",
  });
}

/**
 * Build HTTP response headers
 */
function buildHeaders() {
  return {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,Authorization",
    "Access-Control-Allow-Methods": "POST,OPTIONS",
  };
}

/**
 * Retorna resposta de sucesso
 */
function successResponse(data) {
  return {
    statusCode: 200,
    headers: buildHeaders(),
    body: JSON.stringify(data),
  };
}

/**
 * Retorna resposta de erro no formato padronizado
 */
function errorResponse(statusCode, message, code = "INVALID_CREDENTIALS") {
  return {
    statusCode,
    headers: buildHeaders(),
    body: JSON.stringify({
      errors: [
        {
          code: code,
          message: message.toLowerCase(),
        },
      ],
    }),
  };
}
