const { pool } = require('./src/db');

async function update() {
    console.log('Adding market_sentiment to products table...');
    try {
        const [cols] = await pool.query('SHOW COLUMNS FROM products LIKE "market_sentiment"');
        if (cols.length === 0) {
            await pool.query('ALTER TABLE products ADD COLUMN market_sentiment TEXT NULL');
            console.log('Column market_sentiment added successfully.');
        } else {
            console.log('Column market_sentiment already exists.');
        }
        process.exit(0);
    } catch (e) {
        console.error('Update failed:', e);
        process.exit(1);
    }
}

update();
