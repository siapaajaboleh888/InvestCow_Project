const { pool } = require('./src/db');

async function cleanUpBreeds() {
    console.log('🧹 Menghapus Sapi Bali, Wagyu, dan Simmental dari database...');
    try {
        const [result] = await pool.query(`
            DELETE FROM products 
            WHERE name LIKE '%Bali%' 
               OR name LIKE '%Wagyu%' 
               OR name LIKE '%Simmental%' 
               OR name LIKE '%Simental%'
        `);

        console.log(`✅ Berhasil menghapus ${result.affectedRows} produk.`);
        process.exit(0);
    } catch (error) {
        console.error('❌ Gagal membersihkan database:', error);
        process.exit(1);
    }
}

cleanUpBreeds();
