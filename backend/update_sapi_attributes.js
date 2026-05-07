const { pool } = require('./src/db');

async function updateDb() {
    try {
        console.log('Memeriksa kolom umur, bobot, dan kesehatan di tabel products...');
        
        // Add weight
        let [cols] = await pool.query('SHOW COLUMNS FROM products LIKE "weight"');
        if (cols.length === 0) {
            await pool.query('ALTER TABLE products ADD COLUMN weight INT NULL');
        }
        
        // Add health
        [cols] = await pool.query('SHOW COLUMNS FROM products LIKE "health"');
        if (cols.length === 0) {
            await pool.query('ALTER TABLE products ADD COLUMN health INT NULL');
        }

        // Add age
        [cols] = await pool.query('SHOW COLUMNS FROM products LIKE "age"');
        if (cols.length === 0) {
            await pool.query('ALTER TABLE products ADD COLUMN age INT NULL');
        }

        console.log('Kolom tersedia. Sedang memberikan nilai variatif (A, B, C) ke semua sapi...');

        // Ambil semua sapi
        const [products] = await pool.query('SELECT id, name FROM products');
        
        let countA = 0;
        let countB = 0;
        let countC = 0;

        for (let i = 0; i < products.length; i++) {
            const id = products[i].id;
            
            let weight, health, age;

            // Kita buat variasi paksa agar grade terbagi rata
            if (i % 3 === 0) {
                // Sapi Super / Premium (Target Grade A)
                weight = Math.floor(Math.random() * 100) + 450; // 450 - 550 kg
                health = Math.floor(Math.random() * 5) + 95;   // 95 - 99%
                age = Math.floor(Math.random() * 10) + 20;     // 20 - 30 bln
                countA++;
            } else if (i % 3 === 1) {
                // Sapi Menengah (Target Grade B)
                weight = Math.floor(Math.random() * 100) + 320; // 320 - 420 kg
                health = Math.floor(Math.random() * 10) + 85;   // 85 - 94%
                age = Math.floor(Math.random() * 15) + 12;      // 12 - 27 bln
                countB++;
            } else {
                // Sapi Biasa / Bakalan (Target Grade C)
                weight = Math.floor(Math.random() * 50) + 250;  // 250 - 300 kg
                health = Math.floor(Math.random() * 10) + 75;   // 75 - 84%
                age = Math.floor(Math.random() * 6) + 8;        // 8 - 14 bln
                countC++;
            }

            await pool.query(
                'UPDATE products SET weight = ?, health = ?, age = ? WHERE id = ?',
                [weight, health, age, id]
            );
        }

        console.log(`✅ Berhasil mengupdate ${products.length} ekor sapi!`);
        console.log(`Distribusi atribut diset untuk target: ~${countA} Grade A, ~${countB} Grade B, ~${countC} Grade C.`);
        process.exit(0);
    } catch (e) {
        console.error('❌ Gagal mengupdate:', e);
        process.exit(1);
    }
}

updateDb();
