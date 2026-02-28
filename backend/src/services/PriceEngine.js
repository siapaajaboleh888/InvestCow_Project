const { pool } = require('../db');
const PriceCalculator = require('../utils/PriceCalculator');

/**
 * PriceEngine - Memasok simulasi pergerakan harga sapi secara real-time.
 * Menghasilkan volatilitas kecil agar chart terlihat "hidup".
 */
class PriceEngine {
    constructor(io) {
        this.io = io;
        this.intervalId = null;
        this.pruneId = null;
        this.isRunning = false;
    }

    start() {
        if (this.isRunning) return;
        this.isRunning = true;
        console.log('🚀 [Price Engine] Service initialized and starting...');

        // Jalankan simulasi every 15 detik
        this.intervalId = setInterval(async () => {
            await this.simulatePrices();
        }, 15000);

        // Hapus data harga jadul (> 7 hari) setiap 1 jam
        this.pruneId = setInterval(async () => {
            await this.pruneOldData();
        }, 3600000);

        // Run once on start
        this.simulatePrices().catch(err => console.error('Initial price simulation failed:', err));
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
        console.log('🛑 [Price Engine] Service stopped.');
    }

    async pruneOldData() {
        try {
            console.log('🧹 [Price Engine] Cleaning up legacy price data...');
            const [result] = await pool.query(
                "DELETE FROM product_prices WHERE timestamp < DATE_SUB(NOW(), INTERVAL 7 DAY)"
            );
            if (result.affectedRows > 0) {
                console.log(`✅ [Price Engine] Pruned ${result.affectedRows} old records to maintain DB performance.`);
            }
        } catch (error) {
            console.error('❌ [Price Engine] Data Pruning Error:', error);
        }
    }

    async simulatePrices() {
        const startTime = Date.now();
        try {
            const [products] = await pool.query('SELECT * FROM products');
            if (!products || products.length === 0) return;

            // Process all products in parallel for maximum throughput
            const updates = await Promise.all(products.map(async (product) => {
                try {
                    const oldPrice = parseFloat(product.price);
                    const targetPrice = product.target_price ? parseFloat(product.target_price) : null;
                    const currentWeight = parseFloat(product.current_weight || 300);
                    const growthRate = parseFloat(product.daily_growth_rate || 0.01);
                    const pricePerKg = parseFloat(product.price_per_kg || 65000);
                    const healthScore = parseInt(product.health_score || 100);

                    const result = PriceCalculator.calculateNewPrice({
                        currentWeight,
                        growthRate,
                        healthScore,
                        pricePerKg,
                        targetPrice
                    });

                    const { newWeight, newPricePerKg, newPrice } = result;

                    // Update product record
                    await pool.query(
                        'UPDATE products SET price = :newPrice, current_weight = :weight, price_per_kg = :ppk WHERE id = :id',
                        { newPrice, weight: newWeight, ppk: newPricePerKg, id: product.id }
                    );

                    // History tracking variables
                    const volatility = (Math.random() * 0.0005);
                    const high = Math.max(oldPrice, newPrice) * (1 + volatility);
                    const low = Math.min(oldPrice, newPrice) * (1 - (volatility / 2));

                    // Add to price history
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

                    return {
                        productId: product.id,
                        newPrice,
                        currentWeight: newWeight,
                        pricePerKg: newPricePerKg,
                        timestamp: new Date().toISOString(),
                        candle: { open: oldPrice, high, low, close: newPrice, timestamp: new Date().toISOString() }
                    };
                } catch (productError) {
                    console.error(`❌ [Price Engine] Failed updating product ${product.id}:`, productError);
                    return null;
                }
            }));

            // Filter out failures
            const successfulUpdates = updates.filter(u => u !== null);

            // Broadcast to connected investors
            if (this.io && successfulUpdates.length > 0) {
                this.io.emit('price-update-batch', successfulUpdates);
            }

            const duration = Date.now() - startTime;
            if (duration > 1500) {
                console.warn(`⚠️ [Price Engine] Simulation took ${duration}ms. Product count is: ${products.length}`);
            }

        } catch (error) {
            console.error('❌ [Price Engine] Critical Simulation Error:', error);
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
