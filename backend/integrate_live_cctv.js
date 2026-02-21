const { pool } = require('./src/db');

async function updateToLiveStreams() {
    console.log('🚀 Menghubungkan InvestCow ke Live Farm API Streams...');
    try {
        // Working public HLS streams for demo/testing
        const liveStreams = [
            'https://viamotionhsi.netplus.ch/live/eds/animaux/browser-HLS8/animaux.m3u8', // Animals Live Feed
            'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8', // High Quality Demo
            'https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8' // Standard HLS Testing
        ];

        const [products] = await pool.query('SELECT id, name FROM products');

        console.log(`Ditemukan ${products.length} produk untuk dihubungkan.`);

        for (let i = 0; i < products.length; i++) {
            const streamUrl = liveStreams[i % liveStreams.length];
            await pool.query('UPDATE products SET cctv_url = :url WHERE id = :id', {
                url: streamUrl,
                id: products[i].id
            });
            console.log(`✅ ${products[i].name} terhubung ke: ${streamUrl}`);
        }

        console.log('\n🌟 SEMUA KANDANG BERHASIL TERINTEGRASI DENGAN LIVE API!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Gagal mengintegrasikan live stream:', error);
        process.exit(1);
    }
}

updateToLiveStreams();
