const { pool } = require('./src/db');

async function update() {
    try {
        console.log('🔍 Checking database for transparency columns...');
        const [cols] = await pool.query('SHOW COLUMNS FROM products');
        const colNames = cols.map(c => c.Field);

        const missingCols = [];

        if (!colNames.includes('current_weight')) {
            await pool.query("ALTER TABLE products ADD COLUMN current_weight DECIMAL(10, 2) DEFAULT 300.00 AFTER prev_price");
            missingCols.push('current_weight');
        }
        if (!colNames.includes('price_per_kg')) {
            await pool.query("ALTER TABLE products ADD COLUMN price_per_kg DECIMAL(15, 2) DEFAULT 65000.00 AFTER current_weight");
            missingCols.push('price_per_kg');
        }
        if (!colNames.includes('daily_growth_rate')) {
            await pool.query("ALTER TABLE products ADD COLUMN daily_growth_rate DECIMAL(5, 4) DEFAULT 0.0100 AFTER price_per_kg");
            missingCols.push('daily_growth_rate');
        }
        if (!colNames.includes('health_score')) {
            await pool.query("ALTER TABLE products ADD COLUMN health_score INT DEFAULT 100 AFTER daily_growth_rate");
            missingCols.push('health_score');
        }
        if (!colNames.includes('market_sentiment')) {
            await pool.query("ALTER TABLE products ADD COLUMN market_sentiment VARCHAR(255) NULL AFTER health_score");
            missingCols.push('market_sentiment');
        }

        if (missingCols.length > 0) {
            console.log(`✅ Added missing columns: ${missingCols.join(', ')}`);
        } else {
            console.log('✨ Database is already up to date with transparency columns.');
        }

        process.exit(0);
    } catch (e) {
        console.error('❌ Error updating database:', e);
        process.exit(1);
    }
}

update();
