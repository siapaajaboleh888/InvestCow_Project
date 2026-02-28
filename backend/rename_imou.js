const { pool } = require('./src/db');

async function renameImou() {
    console.log('🔄 Mengubah nama Sapi Imou ke Sapi Peranakan Ongole (PO)...');
    try {
        // Ticker Code: IMOU-01 -> PO-01
        // Name: Kandang Imou Real -> Sapi Peranakan Ongole

        const [result] = await pool.query(`
            UPDATE products 
            SET name = 'Sapi Peranakan Ongole', 
                ticker_code = 'PO-01' 
            WHERE ticker_code = 'IMOU-01' OR name LIKE '%Imou%'
        `);

        if (result.affectedRows > 0) {
            console.log(`✅ Berhasil mengubah ${result.affectedRows} produk.`);
        } else {
            console.log('ℹ️ Tidak ditemukan produk dengan nama Imou atau ticker IMOU-01.');
        }

        process.exit(0);
    } catch (error) {
        console.error('❌ Gagal mengubah nama:', error);
        process.exit(1);
    }
}

renameImou();
