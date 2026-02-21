
const { pool } = require('./src/db');

async function getAdminDetails() {
    try {
        const [rows] = await pool.query('SELECT id, email, role, display_name FROM users WHERE id = 8');
        console.log(JSON.stringify(rows, null, 2));
        process.exit(0);
    } catch (e) {
        process.exit(1);
    }
}
getAdminDetails();
