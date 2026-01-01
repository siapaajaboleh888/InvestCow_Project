const { pool } = require('../db');

/**
 * PriceEngine - Memasok simulasi pergerakan harga sapi secara real-time.
 * Menghasilkan volatilitas kecil agar chart terlihat "hidup".
 */
class PriceEngine {
    constructor(io) {
        this.io = io;
        this.intervalId = null;
        this.isRunning = false;
    }

    start() {
        if (this.isRunning) return;
        this.isRunning = true;
        console.log('🚀 Price Engine started...');

        // Jalankan simulasi setiap 15 detik
        this.intervalId = setInterval(async () => {
            await this.simulatePrices();
        }, 15000);
    }

    stop() {
        if (this.intervalId) {
            clearInterval(this.intervalId);
            this.intervalId = null;
        }
        this.isRunning = false;
        console.log('🛑 Price Engine stopped.');
    }

    async simulatePrices() {
        try {
            // 1. Ambil semua produk aktif
            const [products] = await pool.query('SELECT id, name, price, prev_price, target_price FROM products');

            for (const product of products) {
                const oldPrice = parseFloat(product.price);
                const targetPrice = product.target_price ? parseFloat(product.target_price) : null;

                // 2. Hitung perubahan harga
                // - Volatilitas dasar ±0.2%
                let changePercent = (Math.random() * 0.4 - 0.2) / 100;

                // BIAS: Arahkan perlahan ke target_price jika diset admin
                if (targetPrice !== null) {
                    const diff = targetPrice - oldPrice;
                    if (Math.abs(diff) > 100) { // Berikan dorongan jika selisih > Rp 100
                        const bias = (diff > 0 ? 0.0015 : -0.0015); // Dorongan 0.15% per tick
                        changePercent += bias;
                    }
                } else {
                    // Jika tidak ada target, bias sedikit naik (sapi tumbuh)
                    changePercent += 0.0001;
                }

                let newPrice = oldPrice * (1 + changePercent);

                // Pastikan harga tidak drop gila-gilaan (batas bawah Rp 1000)
                if (newPrice < 1000) newPrice = 1000;

                // 3. Update harga di tabel products
                await pool.query('UPDATE products SET price = :newPrice WHERE id = :id', {
                    newPrice,
                    id: product.id
                });

                // 4. Catat ke riwayat harga (product_prices) untuk chart
                // Gunakan format OHLC sederhana dari simulasi
                const high = Math.max(oldPrice, newPrice) * (1 + (Math.random() * 0.001));
                const low = Math.min(oldPrice, newPrice) * (1 - (Math.random() * 0.001));

                const [result] = await pool.query(
                    'INSERT INTO product_prices (product_id, price_open, price_high, price_low, price_close, volume) VALUES (:id, :open, :high, :low, :close, :volume)',
                    {
                        id: product.id,
                        open: oldPrice,
                        high: high,
                        low: low,
                        close: newPrice,
                        volume: Math.floor(Math.random() * 50) + 10
                    }
                );

                // 5. Emit ke semua klien yang terkoneksi via Socket.io
                if (this.io) {
                    this.io.emit('price-update', {
                        productId: product.id,
                        newPrice: newPrice,
                        timestamp: new Date().toISOString(),
                        candle: {
                            open: oldPrice,
                            high: high,
                            low: low,
                            close: newPrice,
                            timestamp: new Date().toISOString(),
                        }
                    });
                }
            }
        } catch (error) {
            console.error('❌ Price Engine Error:', error);
        }
    }
}

let instance = null;

module.exports = {
    init: (io) => {
        if (!instance) {
            instance = new PriceEngine(io);
            instance.start();
        }
        return instance;
    },
    getInstance: () => instance
};
