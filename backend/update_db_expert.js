const { pool } = require('./src/db');

async function update() {
    try {
        // Add ticker_code and prev_price to products if they don't exist
        const [cols] = await pool.query('SHOW COLUMNS FROM products');
        const colNames = cols.map(c => c.Field);

        if (!colNames.includes('ticker_code')) {
            console.log('Adding ticker_code to products...');
            await pool.query("ALTER TABLE products ADD COLUMN ticker_code VARCHAR(10) AFTER name");
        }

        if (!colNames.includes('prev_price')) {
            console.log('Adding prev_price to products...');
            await pool.query("ALTER TABLE products ADD COLUMN prev_price DECIMAL(15, 2) DEFAULT 0 AFTER price");
        }

        // Ensure product_prices has proper indexes for speed (real-time charts need speed)
        console.log('Optimizing product_prices table...');
        await pool.query("ALTER TABLE product_prices MODIFY COLUMN product_id BIGINT UNSIGNED NOT NULL");

        // Add some default ticker codes for existing cows
        await pool.query("UPDATE products SET ticker_code = 'LIMO' WHERE name LIKE '%Limosin%' AND ticker_code IS NULL");
        await pool.query("UPDATE products SET ticker_code = 'SMNT' WHERE name LIKE '%Simental%' AND ticker_code IS NULL");
        await pool.query("UPDATE products SET ticker_code = 'BALI' WHERE name LIKE '%Bali%' AND ticker_code IS NULL");
        await pool.query("UPDATE products SET ticker_code = 'BRMN' WHERE name LIKE '%Brahman%' AND ticker_code IS NULL");
        await pool.query("UPDATE products SET ticker_code = 'COW' WHERE ticker_code IS NULL");

        // Initialize prev_price with current price if it's 0
        await pool.query("UPDATE products SET prev_price = price WHERE prev_price = 0 OR prev_price IS NULL");

        console.log('Database update complete!');
        process.exit(0);
    } catch (e) {
        console.error('Error updating database:', e);
        process.exit(1);
    }
}

update();
