const { pool } = require('./src/db');

async function optimize() {
    console.log('--- 🛡️ InvestCow DB Optimization started... ---');
    try {
        // 1. Optimize product_prices
        console.log('Adding indexes to product_prices...');
        await pool.query("ALTER TABLE product_prices ADD INDEX idx_product_ts (product_id, timestamp)");

        // 2. Optimize transactions
        console.log('Adding indexes to transactions...');
        await pool.query("ALTER TABLE transactions ADD INDEX idx_user_created (user_id, created_at)");
        await pool.query("ALTER TABLE transactions ADD INDEX idx_portfolio (portfolio_id)");

        // 3. Optimize products
        console.log('Adding indexes to products...');
        await pool.query("ALTER TABLE products ADD INDEX idx_price (price)");

        console.log('✅ [DB Optimization] Indexes added successfully.');

        // 4. Verification
        console.log('Verifying indexes in product_prices:');
        const [indexes] = await pool.query('SHOW INDEX FROM product_prices');
        console.table(indexes.map(idx => ({ Table: idx.Table, Column: idx.Column_name, Key_name: idx.Key_name })));

        process.exit(0);
    } catch (e) {
        if (e.code === 'ER_DUP_KEYNAME') {
            console.warn('⚠️ [DB Optimization] Indexes already exist. Skipping.');
            process.exit(0);
        } else {
            console.error('❌ [DB Optimization] Failed:', e.message);
            process.exit(1);
        }
    }
}

optimize();
