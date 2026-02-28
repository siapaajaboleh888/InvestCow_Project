const { pool } = require('./src/db');

async function fixLimousin() {
    console.log('🔄 Mengubah ID 16 ke Sapi Limousin...');
    try {
        const [result] = await pool.query(`
            UPDATE products 
            SET name = 'Sapi Limousin', 
                ticker_code = 'LIMO' 
            WHERE id = 16
        `);

        if (result.affectedRows > 0) {
            console.log(`✅ Berhasil memperbarui ID 16.`);
        } else {
            console.log('⚠️ ID 16 tidak ditemukan.');
        }

        process.exit(0);
    } catch (error) {
        console.error('❌ Gagal:', error);
        process.exit(1);
    }
}

fixLimousin();
