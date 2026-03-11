const { pool } = require('./src/db');

async function checkProducts() {
    try {
        const [rows] = await pool.query('DESCRIBE products');
        console.log('--- PRODUCTS TABLE COLUMNS (WITH TYPES) ---');
        rows.forEach(r => {
            console.log(`${r.Field}: ${r.Type} (${r.Null === 'YES' ? 'NULL' : 'NOT NULL'})`);
        });
        process.exit(0);
    } catch (e) {
        console.error('❌ Error describing products:', e.message);
        process.exit(1);
    }
}

checkProducts();
