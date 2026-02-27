const axios = require('axios');

const FEEDS = [
    { name: 'CNBC Indonesia', url: 'https://www.cnbcindonesia.com/investment/rss' },
    { name: 'Detik Finance', url: 'https://finance.detik.com/rss' },
    { name: 'Kontan Bisnis', url: 'https://www.kontan.co.id/rss' },
    { name: 'Antara Ekonomi', url: 'https://www.antaranews.com/rss/ekonomi.xml' },
    { name: 'Republika', url: 'https://republika.co.id/rss/ekonomi/pertanian' }
];

async function testFeeds() {
    for (const source of FEEDS) {
        try {
            console.log(`Testing ${source.name}...`);
            const res = await axios.get(source.url, { timeout: 5000, headers: { 'User-Agent': 'Mozilla/5.0' } });
            console.log(`✅ ${source.name}: Status ${res.status}`);
        } catch (e) {
            console.log(`❌ ${source.name}: Error ${e.message}`);
            if (e.response) {
                console.log(`   Status: ${e.response.status}`);
            }
        }
    }
}

testFeeds();
