
const { pool } = require('./src/db');

async function findAdmin() {
    try {
        const [rows] = await pool.query('SELECT * FROM users WHERE role = "admin" OR email LIKE "%admin%"');
        if (rows.length === 0) {
            console.log('No admin users found in database.');
        } else {
            console.log('Admin users found:');
            rows.forEach(user => {
                console.log(`ID: ${user.id} | Email: ${user.email} | Role: ${user.role}`);
            });
        }
        process.exit(0);
    } catch (e) {
        console.error('Error querying users:', e);
        process.exit(1);
    }
}

findAdmin();
