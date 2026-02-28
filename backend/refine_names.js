const { pool } = require('./src/db');

async function fixNames() {
    console.log('🔄 Merapikan nama jenis sapi...');
    try {
        // Renaming to be more descriptive
        await pool.query("UPDATE products SET name = 'Sapi Peranakan Ongole (PO)' WHERE name = 'Sapi Peranakan Ongole'");

        console.log('✅ Nama sapi sudah diperbarui.');
        process.exit(0);
    } catch (error) {
        console.error('❌ Gagal:', error);
        process.exit(1);
    }
}

fixNames();
