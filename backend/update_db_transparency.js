const { pool } = require('./src/db');

async function update() {
    try {
        const [cols] = await pool.query('SHOW COLUMNS FROM products');
        const colNames = cols.map(c => c.Field);

        const additions = [
            { name: 'current_weight', type: 'DECIMAL(10, 2) DEFAULT 250.00' },
            { name: 'daily_growth_rate', type: 'DECIMAL(5, 3) DEFAULT 0.05' }, // kg per tick simulation
            { name: 'price_per_kg', type: 'DECIMAL(15, 2) DEFAULT 60000.00' },
            { name: 'health_score', type: 'INT DEFAULT 100' }
        ];

        for (const add of additions) {
            if (!colNames.includes(add.name)) {
                console.log(`Adding ${add.name} to products...`);
                await pool.query(`ALTER TABLE products ADD COLUMN ${add.name} ${add.type}`);
            }
        }

        // Initialize values for existing products
        await pool.query(`
            UPDATE products 
            SET current_weight = 300 + (id % 100), 
                daily_growth_rate = 0.01 + (id % 10) / 1000,
                price_per_kg = 65000 
            WHERE current_weight = 250.00
        `);

        console.log('Transparency columns added successfully!');
        process.exit(0);
    } catch (e) {
        console.error('Error updating database:', e);
        process.exit(1);
    }
}

update();
