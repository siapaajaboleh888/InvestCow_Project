
const { pool } = require('./src/db');

async function setup() {
    try {
        console.log('🔄 Memperbarui metadata ROI untuk SEMUA jenis sapi...');

        // 1. Set bagi hasil 70% Investor / 30% Peternak sebagai standar untuk SEMUA produk
        // 2. Set target_price estimasi (~25% kenaikan) jika belum ada
        await pool.query(`
      UPDATE products 
      SET investor_share_ratio = 0.7000,
          target_price = COALESCE(target_price, price * 1.25)
    `);

        // 3. Khusus untuk sapi premium, kita berikan target spesifik sesuai pasar 2026
        await pool.query("UPDATE products SET target_price = 24000000 WHERE ticker_code = 'BRAHMAN'");
        await pool.query("UPDATE products SET target_price = 21000000 WHERE ticker_code = 'MADURA'");
        await pool.query("UPDATE products SET target_price = 18500000 WHERE ticker_code = 'BALI'");

        console.log('✅ Berhasil menyesuaikan semua jenis sapi dengan skema bagi hasil 70/30.');
        process.exit(0);
    } catch (e) {
        console.error('❌ Error updating products:', e);
        process.exit(1);
    }
}

setup();
