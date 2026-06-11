require('dotenv').config();
const mysql = require('mysql2/promise');

const isProduction = process.env.NODE_ENV === 'production';
const useSSL = process.env.DB_USE_SSL === 'true';

const poolConfig = {
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'investcow',
  password: process.env.DB_PASSWORD || 'password',
  database: process.env.DB_NAME || 'investcow_app',
  waitForConnections: true,
  connectionLimit: isProduction ? 10 : 25,
  queueLimit: 50,
  namedPlaceholders: true,
  timezone: 'Z',
  connectTimeout: 30000,
};

// Aktifkan SSL jika diperlukan (untuk database cloud seperti FreeSQLDatabase, PlanetScale, dll)
if (useSSL) {
  poolConfig.ssl = { rejectUnauthorized: false };
}

const pool = mysql.createPool(poolConfig);

// Test koneksi saat startup
pool.getConnection()
  .then(conn => {
    console.log('✅ [DB] MySQL connected successfully to', process.env.DB_HOST);
    conn.release();
  })
  .catch(err => {
    console.error('❌ [DB] MySQL connection failed:', err.message);
    // Jangan exit process - biarkan server tetap jalan dan retry
  });

module.exports = { pool };
