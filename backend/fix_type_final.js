const { pool } = require('./src/db');

async function fixFinal() {
    try {
        console.log('🔧 Memperbaiki kolom type...');
        // Ubah ENUM menjadi VARCHAR agar bisa menampung 'TOPUP'
        await pool.query("ALTER TABLE transactions MODIFY COLUMN type VARCHAR(20) NOT NULL");
        console.log('✅ Kolom type berhasil diubah menjadi VARCHAR(20)');

        console.log('🚀 Database siap digunakan!');
        process.exit(0);
    } catch (e) {
        console.error('❌ Gagal:', e);
        process.exit(1);
    }
}

fixFinal();
