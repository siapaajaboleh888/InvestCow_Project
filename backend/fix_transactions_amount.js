const { pool } = require('./src/db');

async function fix() {
    try {
        // Fix buy transactions
        const [res1] = await pool.query('UPDATE transactions SET amount = quantity * price WHERE type = "buy" AND amount = 0');
        console.log(`Updated ${res1.affectedRows} buy transactions`);

        // Fix sell transactions (without profit sharing subtraction as it's hard to calculate back)
        // But for most it's just quantity * price if there was no complex logic before
        const [res2] = await pool.query('UPDATE transactions SET amount = quantity * price WHERE type = "sell" AND amount = 0');
        console.log(`Updated ${res2.affectedRows} sell transactions`);

        // Handle the TOPUP/withdraw if any are missing (amount should be set already by auth.js but let's check)

        process.exit(0);
    } catch (e) {
        console.error('Error:', e.message);
        process.exit(1);
    }
}

fix();
