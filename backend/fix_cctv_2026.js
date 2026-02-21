const { pool } = require('./src/db');

async function updateCctv() {
    console.log('🚀 Updating CCTV URLs with best known 2026 YouTube live streams...');
    try {
        // These are IDs known to have 24/7 or very frequent live streams
        const cowCams = [
            'youtube://1H_80v7OaA8', // Farm Sanctuary - Cow Pasture (Very Stable)
            'youtube://kY4M8O00rQ0', // Hemme Milch - KuhCam (Very Stable)
            'youtube://3_OndKnt6_E', // Explore.org - Barnyard (Often has cows)
            'youtube://Fm_Vl_EwI1M', // Winnie the Moo at Wildlife Sanctuary
            'youtube://SND3vS2NAs4'  // General Cow Cam / Cattle Feed
        ];

        const [products] = await pool.query('SELECT id, name FROM products');

        for (let i = 0; i < products.length; i++) {
            const streamUrl = cowCams[i % cowCams.length];
            await pool.query('UPDATE products SET cctv_url = :url WHERE id = :id', {
                url: streamUrl,
                id: products[i].id
            });
            console.log(`✅ ${products[i].name} -> ${streamUrl}`);
        }

        console.log('\n🌟 CCTV UPDATED SUCCESSFULLY!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Update failed:', error);
        process.exit(1);
    }
}

updateCctv();
