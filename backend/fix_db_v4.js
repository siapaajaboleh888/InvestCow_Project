const { pool } = require('./src/db');

async function fixDatabaseFinal() {
    console.log('🔧 Menyesuaikan struktur tabel transaksi...');
    try {
        // 1. Cek apakah kolom-kolom penting sudah ada
        const [cols] = await pool.query('SHOW COLUMNS FROM transactions');
        const columnNames = cols.map(c => c.Field);

        console.log('Kolom saat ini:', columnNames.join(', '));

        // Tambahkan product_id jika hilang
        if (!columnNames.includes('product_id')) {
            await pool.query('ALTER TABLE transactions ADD COLUMN product_id BIGINT UNSIGNED NULL AFTER user_id');
            console.log('✅ Berhasil menambahkan kolom product_id');
        }

        // Tambahkan amount jika hilang (penting untuk Top Up)
        if (!columnNames.includes('amount')) {
            await pool.query('ALTER TABLE transactions ADD COLUMN amount DECIMAL(20, 2) NOT NULL DEFAULT 0.0 AFTER type');
            console.log('✅ Berhasil menambahkan kolom amount');
        }

        // Pastikan portfolio_id boleh kosong (NULL) agar Top Up bisa masuk tanpa pilih portofolio
        await pool.query('ALTER TABLE transactions MODIFY COLUMN portfolio_id BIGINT UNSIGNED NULL');
        console.log('✅ Berhasil membolehkan portfolio_id menjadi NULL');

        console.log('\n🚀 DATABASE SELESAI DISESUAIKAN!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Gagal memperbaiki database:', error);
        process.exit(1);
    }
}

fixDatabaseFinal();
