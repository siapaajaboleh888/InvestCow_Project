const { pool } = require('./src/db');

async function check() {
    try {
        const [transactions] = await pool.query('DESCRIBE transactions');
        console.log('--- TRANSACTIONS ---');
        console.log(JSON.stringify(transactions, null, 2));
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

check();
