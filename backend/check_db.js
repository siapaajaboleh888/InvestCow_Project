const { pool } = require('./src/db');

async function check() {
    try {
        const [rows] = await pool.query('SELECT * FROM products');
        console.log(JSON.stringify(rows, null, 2));
        process.exit(0);
    } catch (e) {
        console.error('Error connecting to DB:', e.message);
        process.exit(1);
    }
}

check();
