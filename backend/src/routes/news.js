const express = require('express');
const router = express.Router();
const Parser = require('rss-parser');
const parser = new Parser();

const jwt = require('jsonwebtoken');
const { pool } = require('../db');

// Konfigurasi Sumber Berita Real-time
const FEEDS = [
    { name: 'CNBC Indonesia', url: 'https://www.cnbcindonesia.com/news/rss', logo: 'C', color: '#004785', urlLabel: 'cnbcindonesia.com' },
    { name: 'Detik Finance', url: 'https://finance.detik.com/rss', logo: 'D', color: '#2b3990', urlLabel: 'detik.com' },
    { name: 'Kontan Bisnis', url: 'https://www.kontan.co.id/rssbarugue/indeks/berita-bisnis', logo: 'K', color: '#ffcc00', urlLabel: 'kontan.co.id' },
    { name: 'Antara Ekonomi', url: 'https://www.antaranews.com/rss/ekonomi.xml', logo: 'A', color: '#ed1c24', urlLabel: 'antaranews.com' },
    { name: 'Republika', url: 'https://www.republika.co.id/rss/ekonomi/pertanian', logo: 'R', color: '#009245', urlLabel: 'republika.co.id' }
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

        // Check for optional token to personalize news
        const authHeader = req.headers['authorization'] || '';
        const tokenToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
        let userId = null;
        if (tokenToken) {
            try {
                const payload = jwt.verify(tokenToken, process.env.JWT_SECRET);
                userId = Number(payload.sub);
            } catch (e) {
                // Ignore invalid tokens for news feed
                console.log('Optional auth failed for news, serving public list.');
            }
        }


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

        // Prepare response data
        let finalNews = [...formattedNews];

        // Add Personalized ROI Analysis if user is logged in
        if (userId) {
            try {
                const [holdings] = await pool.query(`
                    SELECT t.symbol, 
                           SUM(CASE WHEN LOWER(t.type) = 'buy' THEN t.quantity ELSE -t.quantity END) as total_quantity,
                           SUM(CASE WHEN LOWER(t.type) = 'buy' THEN t.quantity * t.price ELSE -(t.quantity * t.price) END) as total_investment
                    FROM transactions t
                    JOIN portfolios p ON t.portfolio_id = p.id
                    WHERE p.user_id = :uid
                    GROUP BY t.symbol
                `, { uid: userId });

                // Filter owned cows
                const activeCows = holdings.filter(h => Number(h.total_quantity) > 0.01);

                // Urutkan berdasarkan investasi terbesar
                activeCows.sort((a, b) => Number(b.total_investment) - Number(a.total_investment));

                for (let i = 0; i < activeCows.length; i++) {
                    const activePort = activeCows[i];
                    const qty = Number(activePort.total_quantity);
                    const investment = Number(activePort.total_investment);

                    // 2. Ambil target price & ratio dari produk
                    const [prod] = await pool.query('SELECT target_price, investor_share_ratio, price, name FROM products WHERE ticker_code = :symbol OR name = :symbol LIMIT 1', { symbol: activePort.symbol });

                    if (prod.length > 0) {
                        const productName = prod[0].name || activePort.symbol;
                        const targetPricePerUnit = Number(prod[0].target_price) || (Number(prod[0].price) * 1.3);
                        // LOGIKA UI ROI:
                        // Jika >= 1 ekor, gunakan 90%
                        // Jika < 1 ekor, gunakan ratio dari DB (default 70%)
                        let ratio = Number(prod[0].investor_share_ratio) || 0.7;
                        let schemeName = "Skema Investasi";

                        if (qty >= 0.99) { // Using 0.99 for whole cow to avoid float issues
                            ratio = 0.90; // Fixed 90% for whole cow
                            schemeName = "Skema Kepemilikan Utuh";
                        }

                        const totalTargetValue = qty * targetPricePerUnit;
                        const grossProfit = totalTargetValue - investment;

                        const netProfitInvestor = grossProfit > 0 ? (grossProfit * ratio) : grossProfit;
                        const roiPercent = investment > 0 ? ((netProfitInvestor / investment) * 100) : 0;

                        const formatIDR = (num) => 'Rp ' + Math.round(num).toLocaleString('id-ID');

                        const today = new Date();
                        const dynamicTime = today.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }).replace(/:/g, '.');
                        const dynamicDate = today.toLocaleDateString('id-ID', { day: '2-digit', month: 'short' });

                        // Sisipkan di paling atas dengan ID unik
                        finalNews.unshift({
                            id: 1000 + i,
                            source: 'Analis InvestCow',
                            sourceUrl: 'investcow.id',
                            time: dynamicTime,
                            date: dynamicDate,
                            logo: 'A',
                            logoColor: qty >= 0.99 ? '#FFD700' : '#00C853', // Gold color for whole cow owner
                            title: `Analisis ROI ${productName} (${schemeName})`,
                            content: `Berdasarkan kepemilikan Anda sebanyak ${qty.toFixed(0)} ekor ${productName}:\n\n` +
                                `• Estimasi Capital Gain: ${formatIDR(netProfitInvestor)}\n` +
                                `• Proyeksi ROI Tahunan: ${roiPercent.toFixed(1)}% - ${(roiPercent + 4).toFixed(1)}%\n` +
                                `• Estimasi Harga Jual Target: ${formatIDR(totalTargetValue)}\n\n` +
                                `*Dihitung berdasarkan ${schemeName} (Profit Share ${Math.round(ratio * 100)}% Investor / ${Math.round((1 - ratio) * 100)}% Peternak).`,
                            url: 'https://investcow.id/analysis/roi'
                        });
                    }
                }
            } catch (err) {
                console.error('Error news personalization:', err);
            }
        }

        // Update cache (ONLY with non-personalized news)
        if (now - newsCache.lastFetched >= CACHE_DURATION || !newsCache.data) {
            newsCache = {
                data: formattedNews,
                lastFetched: now
            };
        }

        res.json(finalNews);
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
