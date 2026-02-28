const { pool } = require('./src/db');

async function fixImages() {
    console.log('🖼️ Merapikan foto sapi di database agar sesuai breed...');
    try {
        const mappings = [
            { breed: 'Sapi Brahman Premium', img: '/uploads/sapi_brahman_premium.jpg' },
            { breed: 'Sapi Angus Pedaging', img: '/uploads/sapi_angus_premium.jpg' },
            { breed: 'Sapi Peranakan Ongole (PO)', img: '/uploads/sapi_bali.jpg' }, // Existing local asset
            { breed: 'Sapi Limousin', img: '/uploads/sapi_limousin.jpg' },
            { breed: 'Sapi Madura', img: '/uploads/sapi_madura.jpg' }
        ];

        for (const m of mappings) {
            await pool.query('UPDATE products SET image_url = :img WHERE name = :breed', {
                img: m.img,
                breed: m.breed
            });
        }

        console.log('✅ Foto di database sudah disinkronkan!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Gagal:', error);
        process.exit(1);
    }
}

fixImages();
