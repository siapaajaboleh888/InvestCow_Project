
const { pool } = require('./src/db');

async function listUsers() {
    try {
        const [rows] = await pool.query('SELECT id, email, role, display_name FROM users');
        console.log('--- USER LIST ---');
        rows.forEach(user => {
            console.log(`ID: ${user.id} | Email: ${user.email} | Role: ${user.role} | Name: ${user.display_name}`);
        });
        console.log('--- END ---');
        process.exit(0);
    } catch (e) {
        console.error('Error querying users:', e);
        process.exit(1);
    }
}

listUsers();
