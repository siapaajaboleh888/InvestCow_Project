const { pool } = require('./src/db');

async function check() {
    try {
        const [products] = await pool.query('DESCRIBE products');
        const [transactions] = await pool.query('DESCRIBE transactions');
        const [portfolios] = await pool.query('DESCRIBE portfolios');
        const [product_prices] = await pool.query("SHOW TABLES LIKE 'product_prices'");

        console.log('--- PRODUCTS ---');
        console.log(JSON.stringify(products, null, 2));
        console.log('--- TRANSACTIONS ---');
        console.log(JSON.stringify(transactions, null, 2));
        console.log('--- PORTFOLIOS ---');
        console.log(JSON.stringify(portfolios, null, 2));
        console.log('--- PRODUCT_PRICES EXISTS? ---');
        console.log(JSON.stringify(product_prices, null, 2));

        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

check();
