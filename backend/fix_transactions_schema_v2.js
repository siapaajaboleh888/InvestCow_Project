const { pool } = require('./src/db');

async function fixTransactions() {
    console.log('🔧 Fixing transactions table schema...');
    try {
        // 1. Ensure user_id exists and is nullable if not already handled
        try {
            await pool.query('ALTER TABLE transactions ADD COLUMN user_id BIGINT UNSIGNED NULL AFTER id');
            console.log('✅ Added user_id column.');
        } catch (e) {
            console.log('ℹ️ user_id column likely already exists.');
        }

        // 2. Ensure product_id is nullable (for TOPUP types)
        try {
            await pool.query('ALTER TABLE transactions MODIFY COLUMN product_id BIGINT UNSIGNED NULL');
            console.log('✅ Modified product_id to be nullable.');
        } catch (e) {
            console.log('ℹ️ product_id modification skipped or not needed.');
        }

        // 3. Ensure portfolio_id is nullable (for user-level transactions)
        try {
            await pool.query('ALTER TABLE transactions MODIFY COLUMN portfolio_id BIGINT UNSIGNED NULL');
            console.log('✅ Modified portfolio_id to be nullable.');
        } catch (e) {
            console.log('ℹ️ portfolio_id modification skipped or not needed.');
        }

        // 4. Update existing records to link to user_id via portfolio join (Repair data)
        await pool.query(`
            UPDATE transactions t 
            JOIN portfolios p ON t.portfolio_id = p.id 
            SET t.user_id = p.user_id 
            WHERE t.user_id IS NULL
        `);
        console.log('✅ Repaired user_id links for existing transactions.');

        console.log('🚀 Transactions schema is now fintech-ready.');
        process.exit(0);
    } catch (error) {
        console.error('❌ Schema fix failed:', error);
        process.exit(1);
    }
}

fixTransactions();
