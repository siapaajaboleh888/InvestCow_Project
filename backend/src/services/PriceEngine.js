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
            // 1. Ambil semua produk aktif beserta data transparansi
            const [products] = await pool.query('SELECT * FROM products');

            for (const product of products) {
                const oldPrice = parseFloat(product.price);
                const targetPrice = product.target_price ? parseFloat(product.target_price) : null;

                // DATA TRANSPARANSI
                let currentWeight = parseFloat(product.current_weight || 300);
                const growthRate = parseFloat(product.daily_growth_rate || 0.01);
                let pricePerKg = parseFloat(product.price_per_kg || 65000);
                const healthScore = parseInt(product.health_score || 100);

                // 2. SIMULASI PERTUMBUHAN FISIK (Transparency Point)
                // Sapi tumbuh sedikit demi sedikit setiap tick. 
                // Pertumbuhan dipengaruhi oleh health_score (0-100)
                const actualGrowth = growthRate * (healthScore / 100);
                currentWeight += actualGrowth;

                // 3. SIMULASI HARGA PASAR (Volatility Point)
                // Harga per kg berfluktuasi ±0.1% per tick
                let marketChangePercent = (Math.random() * 0.2 - 0.1) / 100;

                // BIAS: Arahkan perlahan ke target_price jika diset admin (berbasis price per kg)
                if (targetPrice !== null) {
                    const currentCalculatedPrice = currentWeight * pricePerKg;
                    const diff = targetPrice - currentCalculatedPrice;
                    if (Math.abs(diff) > 100) {
                        const bias = (diff > 0 ? 0.001 : -0.001);
                        marketChangePercent += bias;
                    }
                }

                pricePerKg = pricePerKg * (1 + marketChangePercent);

                // 4. HITUNG HARGA AKHIR (Adil & Transparan)
                // Harga = Berat (kg) x Harga (Rp/kg)
                let newPrice = currentWeight * pricePerKg;

                // 5. Update data di database
                await pool.query(
                    'UPDATE products SET price = :newPrice, current_weight = :weight, price_per_kg = :ppk WHERE id = :id',
                    {
                        newPrice,
                        weight: currentWeight,
                        ppk: pricePerKg,
                        id: product.id
                    }
                );

                // 6. Catat ke riwayat harga (product_prices) untuk chart
                const high = Math.max(oldPrice, newPrice) * (1 + (Math.random() * 0.0005));
                const low = Math.min(oldPrice, newPrice) * (1 - (Math.random() * 0.00005));

                await pool.query(
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

                // 7. Emit ke semua klien
                if (this.io) {
                    this.io.emit('price-update', {
                        productId: product.id,
                        newPrice: newPrice,
                        currentWeight: currentWeight,
                        pricePerKg: pricePerKg,
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
