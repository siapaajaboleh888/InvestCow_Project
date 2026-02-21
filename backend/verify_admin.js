
const bcrypt = require('bcryptjs');
const { pool } = require('./src/db');

async function verifyAdmin() {
    try {
        const [rows] = await pool.query('SELECT password_hash FROM users WHERE email = "admin@investcow.com"');
        if (rows.length === 0) {
            console.log('Admin not found');
            process.exit(0);
        }
        const hash = rows[0].password_hash;
        const passwords = ['admin1234', 'admin123', 'password', 'investcow', '123456'];

        for (const pw of passwords) {
            const match = await bcrypt.compare(pw, hash);
            if (match) {
                console.log(`FOUND! Password is: ${pw}`);
                process.exit(0);
            }
        }
        console.log('Admin password not in common list.');
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}
verifyAdmin();
