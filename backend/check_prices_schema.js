const { pool } = require('./src/db');

async function checkPrices() {
    try {
        const [rows] = await pool.query('DESCRIBE product_prices');
        console.log('--- PRODUCT_PRICES TABLE COLUMNS ---');
        rows.forEach(r => {
            console.log(`${r.Field}: ${r.Type} (${r.Null === 'YES' ? 'NULL' : 'NOT NULL'})`);
        });
        process.exit(0);
    } catch (e) {
        console.error('❌ Error describing product_prices:', e.message);
        process.exit(1);
    }
}

checkPrices();
