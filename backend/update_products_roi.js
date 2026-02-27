
const { pool } = require('./src/db');

async function setup() {
    try {
        console.log('Updating product metadata for ROI analysis...');

        // Update Brahman Premium to have a target price of 24M and investor share of 70%
        // This will help in generating the analysis that matches the image.
        await pool.query(`
      UPDATE products 
      SET target_price = 24000000, 
          investor_share_ratio = 0.7000,
          description = 'Sapi Brahman Premium dengan kualitas karkas terbaik untuk industri retail.'
      WHERE ticker_code = 'BRAHMAN' OR name LIKE '%Brahman%'
    `);

        console.log('Product metadata updated.');
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

setup();
