const jwt = require("jsonwebtoken");
const { Pool } = require("pg");

// PostgreSQL connection pool
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  ssl: process.env.DB_SSL === "true" ? { rejectUnauthorized: false } : false,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

/**
 * Lambda Function para Autenticação via CPF
 *
 * Funcionalidades:
 * - Valida CPF do cliente ou usuário
 * - Consulta existência e status na base de dados
 * - Gera token JWT válido para consumo das APIs protegidas
 */
exports.handler = async (event) => {
  console.log("Auth request:", JSON.stringify(event, null, 2));

  try {
    const body = JSON.parse(event.body || "{}");
    const { cpf, password, type } = body;

    // Validação de entrada
    if (!cpf || !password) {
      return errorResponse(
        400,
        "cpf e senha são obrigatórios",
        "MISSING_FIELDS",
      );
    }

    if (!type || !["customer", "user"].includes(type)) {
      return errorResponse(
        400,
        "tipo deve ser 'customer' ou 'user'",
        "INVALID_TYPE",
      );
    }

    // Remove formatação do CPF
    const cleanCPF = cleanCPFFormat(cpf);

    // Valida formato do CPF
    if (!isValidCPFFormat(cleanCPF)) {
      return errorResponse(400, "cpf inválido", "INVALID_CPF");
    }

    // Busca no banco de dados
    let entity;
    if (type === "customer") {
      entity = await findCustomerByCPF(cleanCPF);
    } else {
      entity = await findUserByCPF(cleanCPF);
    }

    if (!entity) {
      return errorResponse(401, "invalid credentials", "INVALID_CREDENTIALS");
    }

    // Verifica se está ativo (não deletado)
    if (entity.deleted_at) {
      return errorResponse(
        403,
        `${type === "customer" ? "cliente" : "usuário"} inativo`,
        "INACTIVE_ACCOUNT",
      );
    }

    // Verifica senha (bcrypt hash comparison)
    const bcrypt = require("bcryptjs");
    const passwordMatch = await bcrypt.compare(password, entity.password);

    if (!passwordMatch) {
      return errorResponse(401, "invalid credentials", "INVALID_CREDENTIALS");
    }

    // Gera token JWT
    const token = generateJWT(entity, type);

    // Retorna sucesso com token no formato esperado
    return successResponse({
      data: {
        token,
        user: {
          id: entity.id,
          name: entity.name,
          cpf: cleanCPF,
          email: entity.email,
          description: entity.description || "",
          role: entity.role || "CUSTOMER",
          created_at: entity.created_at || "",
          updated_at: entity.updated_at || "",
        },
      },
    });
  } catch (error) {
    console.error("Authentication error:", error);
    return errorResponse(500, "erro interno no servidor", "INTERNAL_ERROR");
  }
};

/**
 * Remove formatação do CPF (pontos e traços)
 */
function cleanCPFFormat(cpf) {
  return cpf.replace(/[.\-]/g, "").trim();
}

/**
 * Valida formato do CPF (11 dígitos e dígitos verificadores)
 */
function isValidCPFFormat(cpf) {
  if (!/^\d{11}$/.test(cpf)) {
    return false;
  }

  // Verifica se todos os dígitos são iguais (CPF inválido)
  if (/^(\d)\1{10}$/.test(cpf)) {
    return false;
  }

  // Valida dígitos verificadores
  let sum = 0;
  let remainder;

  // Primeiro dígito verificador
  for (let i = 1; i <= 9; i++) {
    sum += parseInt(cpf.substring(i - 1, i)) * (11 - i);
  }
  remainder = (sum * 10) % 11;
  if (remainder === 10 || remainder === 11) remainder = 0;
  if (remainder !== parseInt(cpf.substring(9, 10))) return false;

  // Segundo dígito verificador
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
 * Busca cliente por CPF no banco de dados
 */
async function findCustomerByCPF(cpf) {
  const query = `
    SELECT id, name, email, password, phone, document, document_type, created_at, updated_at, deleted_at
    FROM customers
    WHERE document = $1 AND document_type = 'CPF'
    LIMIT 1
  `;

  const result = await pool.query(query, [cpf]);
  return result.rows.length > 0 ? result.rows[0] : null;
}

/**
 * Busca usuário por CPF no banco de dados
 */
async function findUserByCPF(cpf) {
  const query = `
    SELECT id, name, email, password, cpf, role, description, created_at, updated_at, deleted_at
    FROM users
    WHERE cpf = $1
    LIMIT 1
  `;

  const result = await pool.query(query, [cpf]);
  return result.rows.length > 0 ? result.rows[0] : null;
}

/**
 * Gera token JWT
 */
function generateJWT(entity, type) {
  const payload = {
    user_id: entity.id,
    sub: entity.id,
    email: entity.email,
    name: entity.name,
    cpf: entity.cpf || entity.document,
    role: entity.role || "CUSTOMER",
    type: type,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24, // 24 horas
  };

  return jwt.sign(payload, process.env.JWT_SECRET);
}

/**
 * Retorna resposta de sucesso
 */
function successResponse(data) {
  return {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "Content-Type,Authorization",
      "Access-Control-Allow-Methods": "POST,OPTIONS",
    },
    body: JSON.stringify(data),
  };
}

/**
 * Retorna resposta de erro no formato padronizado
 */
function errorResponse(statusCode, message, code = "INVALID_CREDENTIALS") {
  return {
    statusCode,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "Content-Type,Authorization",
      "Access-Control-Allow-Methods": "POST,OPTIONS",
    },
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
