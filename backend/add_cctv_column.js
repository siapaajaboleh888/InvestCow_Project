const { pool } = require('./src/db');

async function addCctvUrlColumn() {
    console.log('🔧 Menambahkan kolom cctv_url ke tabel products...');
    try {
        const [cols] = await pool.query('SHOW COLUMNS FROM products');
        const columnNames = cols.map(c => c.Field);

        if (!columnNames.includes('cctv_url')) {
            await pool.query('ALTER TABLE products ADD COLUMN cctv_url VARCHAR(255) DEFAULT NULL AFTER image_url');
            console.log('✅ Berhasil menambahkan kolom cctv_url');
        } else {
            console.log('ℹ️ Kolom cctv_url sudah ada');
        }

        // Update sample products with demo HLS streams
        console.log('📝 Mengupdate data produk dengan demo CCTV...');
        const demoStreams = [
            'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8',
            'https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-911d-4720-911b-df8f44354b59.m3u8',
            'https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8'
        ];

        const [products] = await pool.query('SELECT id FROM products');
        for (let i = 0; i < products.length; i++) {
            const streamUrl = demoStreams[i % demoStreams.length];
            await pool.query('UPDATE products SET cctv_url = :url WHERE id = :id', {
                url: streamUrl,
                id: products[i].id
            });
        }

        console.log('✅ Berhasil mengupdate demo CCTV streams');
        process.exit(0);
    } catch (error) {
        console.error('❌ Gagal mengupdate database:', error);
        process.exit(1);
    }
}

addCctvUrlColumn();
