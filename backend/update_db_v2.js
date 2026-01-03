const { pool } = require('./src/db');

async function update() {
    try {
        console.log('Updating database...');

        // Add balance to users table if not exists
        const [userCols] = await pool.query('DESCRIBE users');
        const hasBalance = userCols.some(c => c.Field === 'balance');
        if (!hasBalance) {
            await pool.query('ALTER TABLE users ADD COLUMN balance DECIMAL(15, 2) DEFAULT 0.00');
            console.log('Added balance column to users table');
        } else {
            console.log('balance column already exists in users table');
        }

        // Add a route to get user info in auth.js later

        console.log('Database updated successfully');
        process.exit(0);
    } catch (e) {
        console.error('Update failed:', e);
        process.exit(1);
    }
}

update();
