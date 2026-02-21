const { pool } = require('./src/db');

async function updateToRealCowCams() {
    console.log('🚀 Mengintegrasikan Real YouTube Cow Cams ke InvestCow...');
    try {
        // Real YouTube IDs for live cow/farm cams
        const cowCams = [
            'kY4M8O00rQ0', // Hemme Milch KuhCam (Very stable)
            '1H_80v7OaA8', // Farm Sanctuary Cow Cam
            'UC-2KSeUU5SMCX6XLRD-AEvw' // Explore.org Nature (Often has cows)
        ];

        const [products] = await pool.query('SELECT id, name FROM products');

        for (let i = 0; i < products.length; i++) {
            // We'll prefix with 'youtube://' so the Flutter app knows how to play it
            const youtubeId = cowCams[i % cowCams.length];
            const streamUrl = `youtube://${youtubeId}`;

            await pool.query('UPDATE products SET cctv_url = :url WHERE id = :id', {
                url: streamUrl,
                id: products[i].id
            });
            console.log(`✅ ${products[i].name} terhubung ke YouTube ID: ${youtubeId}`);
        }

        console.log('\n🌟 REAL COW CAMS BERHASIL TERINTEGRASI!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Gagal mengintegrasikan:', error);
        process.exit(1);
    }
}

updateToRealCowCams();
