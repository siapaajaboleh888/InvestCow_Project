const PriceCalculator = require('./src/utils/PriceCalculator');

/**
 * DEVOPS UNIT TEST - Bab 5
 * Memastikan logika perhitungan harga tetap akurat tanpa perlu DB.
 */
function testCalculator() {
    console.log('🧪 Running PriceCalculator Unit Test...');

    const initialData = {
        currentWeight: 300,
        growthRate: 1, // 1 kg per hari
        healthScore: 100, // Sehat maksimal
        pricePerKg: 60000,
        targetPrice: 20000000 // Target tinggi agar ada bias naik
    };

    const result = PriceCalculator.calculateNewPrice(initialData);

    let failed = false;

    // Test 1: Berat harus bertambah
    if (result.newWeight <= initialData.currentWeight) {
        console.error('❌ Test 1 Failed: Weight did not increase');
        failed = true;
    } else {
        console.log('✅ Test 1 Passed: Weight increased correctly');
    }

    // Test 2: Harga total harus masuk akal (Berat x HargaPerKg)
    const expectedPrice = result.newWeight * result.newPricePerKg;
    if (Math.abs(result.newPrice - expectedPrice) > 0.01) {
        console.error('❌ Test 2 Failed: Final price calculation is incorrect');
        failed = true;
    } else {
        console.log('✅ Test 2 Passed: price calculation is accurate');
    }

    if (failed) {
        console.log('\n💥 DevOps Status: TEST FAILED');
        process.exit(1);
    } else {
        console.log('\n🚀 DevOps Status: ALL TESTS PASSED');
        process.exit(0);
    }
}

testCalculator();
