const express = require('express');
const router = express.Router();
const Parser = require('rss-parser');
const parser = new Parser();

// Konfigurasi Sumber Berita Real-time
const FEEDS = [
    { name: 'CNBC Indonesia', url: 'https://www.cnbcindonesia.com/investment/rss', logo: 'C', color: '#004785', urlLabel: 'cnbcindonesia.com' },
    { name: 'Detik Finance', url: 'https://finance.detik.com/rss', logo: 'D', color: '#2b3990', urlLabel: 'detik.com' },
    { name: 'Kontan Bisnis', url: 'https://www.kontan.co.id/rss', logo: 'K', color: '#ffcc00', urlLabel: 'kontan.co.id' },
    { name: 'Antara Ekonomi', url: 'https://www.antaranews.com/rss/ekonomi.xml', logo: 'A', color: '#ed1c24', urlLabel: 'antaranews.com' },
    { name: 'Republika', url: 'https://republika.co.id/rss/ekonomi/pertanian', logo: 'R', color: '#009245', urlLabel: 'republika.co.id' }
];

const KEYWORDS = ['sapi', 'lembu', 'ternak sapi', 'daging sapi', 'bovine', 'pakan sapi', 'penggemukan sapi', 'investasi ternak', 'livestock investment'];
const EXCLUDE = [
    'unggas', 'ayam', 'telur', 'bebek', 'ikan', 'padi', 'beras', 'minyak', 'sawit', 'ponsel', 'laptop', 'gadget', 'saham teknologi',
    'mobil', 'pickup', 'otomotif', 'kendaraan', 'cabai', 'bawang', 'sayur', 'buah', 'pupuk', 'cetak sawah', 'bendungan', 'irigasi'
];

router.get('/', async (req, res) => {
    try {
        let allArticles = [];

        const feedPromises = FEEDS.map(async (source) => {
            try {
                const feed = await parser.parseURL(source.url);
                return feed.items.map(item => ({
                    ...item,
                    sourceName: source.name,
                    sourceLogo: source.logo,
                    sourceColor: source.color,
                    sourceUrl: source.urlLabel
                }));
            } catch (err) {
                console.error(`Gagal ambil berita dari ${source.name}:`, err.message);
                return [];
            }
        });

        const results = await Promise.all(feedPromises);
        allArticles = results.flat();

        // Filter berita yang SANGAT RELEVAN saja
        const filteredNews = allArticles.filter(article => {
            const title = article.title.toLowerCase();
            const snippet = (article.contentSnippet || '').toLowerCase();
            const fullContent = (article.content || '').toLowerCase();

            const combined = title + ' ' + snippet + ' ' + fullContent;

            // Harus ada keyword sapi/ternak
            const hasKeyword = KEYWORDS.some(kw => combined.includes(kw));
            // Tidak boleh ada keyword exclude (seperti unggas/ayam)
            const isExcluded = EXCLUDE.some(ex => combined.includes(ex));

            return hasKeyword && !isExcluded;
        }).slice(0, 10);

        const formattedNews = filteredNews.map((item, index) => {
            const pubDate = new Date(item.pubDate);
            const timeStr = pubDate.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
            const dateStr = pubDate.toLocaleDateString('id-ID', { day: '2-digit', month: 'short' });

            return {
                id: index + 1,
                source: item.sourceName,
                sourceUrl: item.sourceUrl,
                time: timeStr,
                date: dateStr,
                logo: item.sourceLogo,
                logoColor: item.sourceColor,
                title: item.title,
                // Mengambil konten yang lebih panjang agar tidak "minim"
                content: item.contentSnippet || item.content || 'Berita hari ini mengenai industri peternakan sapi nasional.',
                url: item.link // Simpan URL asli untuk "Baca Selengkapnya"
            };
        });

        // Fallback jika tidak ada berita spesifik sapi hari ini (Agar tidak kosong)
        if (formattedNews.length === 0) {
            formattedNews.push({
                id: 99,
                source: 'InvestCow Insight',
                sourceUrl: 'investcow.id',
                time: '08:00',
                date: 'Edisi Khusus',
                logo: 'I',
                logoColor: '#4CAF50',
                title: 'Analisis Strategis: Mengapa Investasi Sapi Tetap Menjadi Safe Haven di Tahun 2026',
                content: 'Dalam tengah fluktuasi pasar global, aset biologis seperti sapi menunjukkan ketahanan yang luar biasa. Permintaan daging sapi domestik yang terus meningkat di Indonesia, ditambah dengan program swasembada pangan nasional, menciptakan ekosistem investasi yang sangat menjanjikan dengan risiko yang terukur. \n\nTim analis InvestCow mencatat bahwa pertumbuhan bobot harian (ADG) sapi di klaster mitra kami tetap berada di angka 0.8kg - 1.2kg per hari, memastikan proyeksi imbal hasil bagi investor tetap stabil. Klik untuk mempelajari lebih lanjut tentang strategi diversifikasi portofolio melalui aset ternak.',
                url: 'https://investcow.id/edu/safe-haven-2026'
            });
        }

        res.json(formattedNews);
    } catch (error) {
        console.error('Error News Route:', error);
        res.status(500).json({ message: 'Internal Server Error' });
    }
});

module.exports = router;
