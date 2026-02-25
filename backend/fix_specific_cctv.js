const { pool } = require('./src/db');

async function fixSpecificCams() {
    console.log('🔧 Memperbaiki CCTV Sapi Madura dan Kandang Imou Real...');
    try {
        // We use IDs from working cams: 
        // Brahman (inDzgZjCxmQ) and Angus (dqcCOYtHtes)

        const updates = [
            { code: 'MADURA', url: 'youtube://inDzgZjCxmQ' },
            { code: 'IMOU-01', url: 'youtube://dqcCOYtHtes' }
        ];

        for (const up of updates) {
            await pool.query('UPDATE products SET cctv_url = :url WHERE ticker_code = :code', {
                url: up.url,
                code: up.code
            });
            console.log(`✅ ${up.code} diperbarui ke ${up.url}`);
        }

        console.log('\n🌟 CCTV BERHASIL DIPERBAIKI!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Gagal memperbarui:', error);
        process.exit(1);
    }
}

fixSpecificCams();
