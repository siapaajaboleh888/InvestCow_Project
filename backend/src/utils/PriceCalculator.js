/**
 * PriceCalculator - Logika perhitungan harga sapi yang terpisah dari database.
 * Digunakan untuk Unit Testing dalam pipeline DevOps CI/CD (Bab 4 & 5).
 */
class PriceCalculator {
    /**
     * Menghitung volatilitas pasar berdasarkan target price (jika ada).
     */
    static calculateMarketChange(currentCalculatedPrice, targetPrice) {
        // Volatilitas dasar ±0.1%
        let marketChangePercent = (Math.random() * 0.2 - 0.1) / 100;

        // Bias ke arah target price jika diset
        if (targetPrice !== null) {
            const diff = targetPrice - currentCalculatedPrice;
            if (Math.abs(diff) > 100) {
                const bias = (diff > 0 ? 0.001 : -0.001);
                marketChangePercent += bias;
            }
        }
        return marketChangePercent;
    }

    /**
     * Menghitung harga baru secara end-to-end.
     */
    static calculateNewPrice({
        currentWeight,
        growthRate,
        healthScore,
        pricePerKg,
        targetPrice = null
    }) {
        // 1. Hitung pertumbuhan berat (Transparency Point)
        const actualGrowth = growthRate * (healthScore / 100);
        const newWeight = currentWeight + actualGrowth;

        // 2. Hitung Dinamika Pasar
        const currentCalculatedPrice = currentWeight * pricePerKg;
        const marketChangePercent = this.calculateMarketChange(currentCalculatedPrice, targetPrice);

        // 3. Hitung harga per kg baru (Volatility Point)
        const newPricePerKg = pricePerKg * (1 + marketChangePercent);

        // 4. Hitung harga total (Adil & Transparan)
        const newPrice = newWeight * newPricePerKg;

        return {
            newWeight,
            newPricePerKg,
            newPrice,
            marketChangePercent
        };
    }
}

module.exports = PriceCalculator;
