const { pool } = require('./src/db');

async function setup() {
    try {
        await pool.query(`
      CREATE TABLE IF NOT EXISTS product_prices (
        id INT AUTO_INCREMENT PRIMARY KEY,
        product_id BIGINT UNSIGNED NOT NULL,
        price_open DECIMAL(15, 2),
        price_high DECIMAL(15, 2),
        price_low DECIMAL(15, 2),
        price_close DECIMAL(15, 2),
        volume INT DEFAULT 0,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);
        console.log('product_prices table created or already exists (no FK)');
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

setup();
