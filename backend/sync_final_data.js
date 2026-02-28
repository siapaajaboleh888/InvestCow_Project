const { pool } = require('./src/db');

async function syncAllData() {
    console.log('🚀 Menyelaraskan data akhir (Madura, Brahman, Angus, Limousin, PO)...');
    try {
        // Brahman
        await pool.query("UPDATE products SET name = 'Sapi Brahman Premium', ticker_code = 'BRAH-P', cctv_url = 'youtube://inDzgZjCxmQ' WHERE id = 13");
        // Angus
        await pool.query("UPDATE products SET name = 'Sapi Angus Pedaging', ticker_code = 'ANGUS-P', cctv_url = 'youtube://dqcCOYtHtes' WHERE id = 14");
        // PO
        await pool.query("UPDATE products SET name = 'Sapi Peranakan Ongole (PO)', ticker_code = 'PO-01', cctv_url = 'youtube://inDzgZjCxmQ' WHERE id = 15");
        // Limousin
        await pool.query("UPDATE products SET name = 'Sapi Limousin', ticker_code = 'LIMO', cctv_url = 'youtube://dqcCOYtHtes' WHERE id = 16");
        // Madura
        await pool.query("UPDATE products SET name = 'Sapi Madura', ticker_code = 'MADURA', cctv_url = 'youtube://inDzgZjCxmQ' WHERE id = 17");

        console.log('✅ Semua data berhasil diselaraskan!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Gagal menyelaraskan data:', error);
        process.exit(1);
    }
}

syncAllData();
