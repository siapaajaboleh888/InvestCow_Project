const { pool } = require('./src/db');

async function setup() {
    try {
        console.log('Creating health_requests table...');
        await pool.query(`
            CREATE TABLE IF NOT EXISTS health_requests (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id BIGINT UNSIGNED NOT NULL,
                cow_name VARCHAR(100) NOT NULL,
                request_type VARCHAR(50) NOT NULL,
                description TEXT,
                status VARCHAR(20) DEFAULT 'pending',
                admin_note TEXT,
                handover_date DATETIME,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
        `);
        console.log('✅ health_requests table created or already exists.');
        process.exit(0);
    } catch (e) {
        console.error('❌ Error creating table:', e);
        process.exit(1);
    }
}

setup();
