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

        // DEVOPS PHASE 5: MONITORING & OPERATION
        // Jalankan simulasi every 15 detik sebagai bagian dari continuous monitoring
        this.intervalId = setInterval(async () => {
            await this.simulatePrices();
        }, 15000);

        // DATABASE MAINTENANCE: Hapus data harga jadul (> 7 hari) setiap 1 jam
        // Agar database tidak bengkak saat sudah hosting
        this.pruneId = setInterval(async () => {
            await this.pruneOldData();
        }, 3600000);
    }

    stop() {
        if (this.intervalId) {
            clearInterval(this.intervalId);
            this.intervalId = null;
        }
        if (this.pruneId) {
            clearInterval(this.pruneId);
            this.pruneId = null;
        }
        this.isRunning = false;
        console.log('🛑 Price Engine stopped.');
    }

    async pruneOldData() {
        try {
            console.log('🧹 Cleaning up old price data...');
            // Hapus data yang lebih tua dari 7 hari
            const [result] = await pool.query(
                "DELETE FROM product_prices WHERE timestamp < DATE_SUB(NOW(), INTERVAL 7 DAY)"
            );
            if (result.affectedRows > 0) {
                console.log(`✅ Pruned ${result.affectedRows} old price records.`);
            }
        } catch (error) {
            console.error('❌ Data Pruning Error:', error);
        }
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

                const PriceCalculator = require('../utils/PriceCalculator');
                const result = PriceCalculator.calculateNewPrice({
                    currentWeight,
                    growthRate,
                    healthScore,
                    pricePerKg,
                    targetPrice
                });

                const newWeight = result.newWeight;
                const newPricePerKg = result.newPricePerKg;
                const newPrice = result.newPrice;

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
            // DEVOPS ERROR LOGGING: Memastikan sistem tetap terdata jika terjadi kegagalan
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
