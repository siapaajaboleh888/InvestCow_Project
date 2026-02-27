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

// In-memory cache untuk berita agar tidak spam API RSS & loading lebih cepat
let newsCache = {
    data: null,
    lastFetched: 0
};
const CACHE_DURATION = 30 * 60 * 1000; // 30 Menit

router.get('/', async (req, res) => {
    try {
        const now = Date.now();

        // Gunakan cache jika masih valid
        if (newsCache.data && (now - newsCache.lastFetched < CACHE_DURATION)) {
            console.log('📰 Serving news from cache');
            return res.json(newsCache.data);
        }

        console.log('📡 Fetching fresh news from RSS feeds...');
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
            const title = (article.title || '').toLowerCase();
            const snippet = (article.contentSnippet || '').toLowerCase();
            const fullContent = (article.content || '').toLowerCase();

            const combined = title + ' ' + snippet + ' ' + fullContent;

            // Harus ada keyword sapi/ternak
            const hasKeyword = KEYWORDS.some(kw => combined.includes(kw));
            // Tidak boleh ada keyword exclude (seperti unggas/ayam)
            const isExcluded = EXCLUDE.some(ex => combined.includes(ex));

            return hasKeyword && !isExcluded;
        });

        // Sort by date (descending)
        filteredNews.sort((a, b) => new Date(b.pubDate) - new Date(a.pubDate));

        const formattedNews = filteredNews.slice(0, 15).map((item, index) => {
            const pubDate = new Date(item.pubDate);
            const timeStr = pubDate.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }).replace(/:/g, '.');
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
                content: item.contentSnippet || item.content || 'Berita hari ini mengenai industri peternakan sapi nasional.',
                url: item.link
            };
        });

        // Fallback jika tidak ada berita spesifik sapi hari ini
        if (formattedNews.length === 0) {
            const today = new Date();
            const dynamicTime = today.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }).replace(/:/g, '.');
            const dynamicDate = today.toLocaleDateString('id-ID', { day: '2-digit', month: 'short' });

            formattedNews.push({
                id: 99,
                source: 'InvestCow Insight',
                sourceUrl: 'investcow.id',
                time: dynamicTime,
                date: dynamicDate,
                logo: 'I',
                logoColor: '#00CED1',
                title: 'Tren Investasi Ternak Sapi 2026: Proyeksi Kenaikan Harga Daging Global',
                content: 'Analisis pasar terbaru menunjukkan tren positif pada industri peternakan sapi di Indonesia dan Australia. Investasi pada aset biologis (sapi) menjadi pilihan diversifikasi yang menarik.',
                url: 'https://investcow.id/edu/tren-investasi-2026'
            });
        }

        // Update cache
        newsCache = {
            data: formattedNews,
            lastFetched: now
        };

        res.json(formattedNews);
    } catch (error) {
        console.error('Error News Route:', error);
        // Jika error tapi ada cache lama, tampilkan cache lama daripada error 500
        if (newsCache.data) {
            return res.json(newsCache.data);
        }
        res.status(500).json({ message: 'Internal Server Error' });
    }
});

module.exports = router;
