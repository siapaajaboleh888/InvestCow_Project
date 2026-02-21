const { pool } = require('./src/db');

async function updateCctv() {
    console.log('🚀 Updating CCTV with FRESH LIVE YouTube streams...');
    try {
        const liveIds = ["inDzgZjCxmQ", "dqcCOYtHtes", "dKFwk3MDu74", "Rqv8G0fE9bc", "gbaLDcOhqI8"];

        const [products] = await pool.query('SELECT id, name FROM products');

        for (let i = 0; i < products.length; i++) {
            const youtubeId = liveIds[i % liveIds.length];
            const streamUrl = `youtube://${youtubeId}`;

            await pool.query('UPDATE products SET cctv_url = :url WHERE id = :id', {
                url: streamUrl,
                id: products[i].id
            });
            console.log(`✅ ${products[i].name} -> ${youtubeId}`);
        }

        console.log('\n🌟 FRESH CCTV UPDATED!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Update failed:', error);
        process.exit(1);
    }
}

updateCctv();
