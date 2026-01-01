const { pool } = require('./src/db');

async function addTargetPrice() {
    try {
        const [cols] = await pool.query('SHOW COLUMNS FROM products');
        const colNames = cols.map(c => c.Field);

        if (!colNames.includes('target_price')) {
            console.log('Adding target_price to products...');
            await pool.query("ALTER TABLE products ADD COLUMN target_price DECIMAL(15, 2) DEFAULT NULL AFTER price");
        }

        console.log('Database updated: target_price column added.');
        process.exit(0);
    } catch (e) {
        console.error('Error adding target_price:', e);
        process.exit(1);
    }
}

addTargetPrice();
