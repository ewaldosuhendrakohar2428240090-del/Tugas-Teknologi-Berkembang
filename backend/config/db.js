const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'pet_care_db',
  port: parseInt(process.env.DB_PORT, 10) || 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

// Helper check connection
async function checkConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('✅ Connected to MySQL database:', process.env.DB_NAME || 'pet_care_db');
    connection.release();
    return true;
  } catch (err) {
    console.warn('⚠️ Warning: MySQL connection failed (' + err.message + ').');
    console.warn('💡 Pastikan Laragon/XAMPP MySQL berjalan dan file database/pet_care_db.sql sudah diimport.');
    return false;
  }
}

module.exports = { pool, checkConnection };
