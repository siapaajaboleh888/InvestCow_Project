const { pool } = require('./src/db');

async function check() {
    try {
        const [rows] = await pool.query('DESCRIBE transactions');
        console.log(JSON.stringify(rows, null, 2));
        process.exit(0);
    } catch (e) {
        console.error('Error:', e.message);
        process.exit(1);
    }
}

check();
