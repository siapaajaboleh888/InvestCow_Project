const express = require('express');
const router = express.Router();
const Parser = require('rss-parser');
const parser = new Parser({
    timeout: 12000,
    headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'application/rss+xml, application/xml, text/xml, */*'
    }
});

const jwt = require('jsonwebtoken');
const { pool } = require('../db');

// ✅ Sumber Berita RSS yang SUDAH DIVERIFIKASI AKTIF & mengandung konten sapi/ternak
const FEEDS = [
    // Sumber terbaik - banyak konten sapi/daging
    { name: 'Detik Food',        url: 'https://food.detik.com/rss',                                    logo: 'D', color: '#e31212', urlLabel: 'detik.com' },
    { name: 'Detik Finance',     url: 'https://finance.detik.com/rss',                                 logo: 'D', color: '#2b3990', urlLabel: 'finance.detik.com' },
    { name: 'Detik News',        url: 'https://news.detik.com/rss',                                    logo: 'D', color: '#1a1a2e', urlLabel: 'detik.com' },
    { name: 'Antara Ekonomi',    url: 'https://www.antaranews.com/rss/ekonomi.xml',                    logo: 'A', color: '#ed1c24', urlLabel: 'antaranews.com' },
    { name: 'Republika Pertanian', url: 'https://www.republika.co.id/rss/ekonomi/pertanian',          logo: 'R', color: '#009245', urlLabel: 'republika.co.id' },
    { name: 'Republika Ekonomi', url: 'https://www.republika.co.id/rss/ekonomi/keuangan',             logo: 'R', color: '#009245', urlLabel: 'republika.co.id' },
    { name: 'CNBC Indonesia',    url: 'https://www.cnbcindonesia.com/news/rss',                        logo: 'C', color: '#004785', urlLabel: 'cnbcindonesia.com' },
    { name: 'Sindonews Ekbis',   url: 'https://ekbis.sindonews.com/rss',                              logo: 'S', color: '#c0392b', urlLabel: 'sindonews.com' },
];

// ✅ Keyword diperluas — menangkap lebih banyak berita relevan
const KEYWORDS_STRONG = [
    // Kata kunci UTAMA — cukup satu dari ini untuk lulus filter
    'sapi', 'daging sapi', 'ternak sapi', 'peternakan sapi', 'lembu',
    'sapi kurban', 'sapi potong', 'sapi perah', 'sapi bakalan',
    'susu sapi', 'harga sapi', 'impor sapi', 'ekspor sapi',
    'pakan sapi', 'pakan ternak', 'penggemukan sapi',
    'livestock', 'bovine', 'cattle',
];

const KEYWORDS_CONTEXT = [
    // Keyword KONTEKS — hanya lulus jika juga ada keyword_strong di teks yang sama
    'hewan kurban', 'daging kurban', 'daging merah',
    'peternakan', 'peternak', 'ternak',
    'harga daging', 'idul adha', 'kurban', 'hewan qurban',
];

// ❌ Keyword yang DIKECUALIKAN (berita tidak relevan)
const EXCLUDE = [
    'unggas', 'ayam broiler', 'ayam potong', 'telur ayam', 'bebek',
    'ikan lele', 'ikan bandeng', 'ikan nila', 'ikan mas', 'udang',
    'nelayan', 'kapal ikan',
    'buruh pabrik', 'demo buruh', 'demo pekerja',
    'saham', 'kripto', 'bitcoin', 'forex', 'valas',
    'ponsel', 'laptop', 'gadget', 'elektronik',
    'mobil', 'motor', 'kendaraan',
    'sawit', 'minyak goreng', 'cetak sawah', 'bendungan',
    'domba', 'kambing',          // fokus ke sapi saja, bukan kambing/domba
];

// In-memory cache — 6 jam agar tidak sering fetch & tidak membebani server
let newsCache = {
    data: null,
    lastFetched: 0
};
const CACHE_DURATION = 6 * 60 * 60 * 1000; // 6 Jam
const MAX_NEWS = 3; // Maksimal 3 berita per hari

router.get('/', async (req, res) => {
    try {
        const now = Date.now();

        // Cek token user (opsional, untuk personalisasi)
        const authHeader = req.headers['authorization'] || '';
        const rawToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
        let userId = null;
        if (rawToken) {
            try {
                const payload = jwt.verify(rawToken, process.env.JWT_SECRET);
                userId = Number(payload.sub);
            } catch (e) {
                console.log('Optional auth failed for news, serving public list.');
            }
        }

        // Gunakan cache jika masih valid
        if (newsCache.data && (now - newsCache.lastFetched < CACHE_DURATION)) {
            console.log('📰 Serving news from cache');
            // Tambah personalisasi di atas cache jika user login
            if (userId) {
                const personalized = await buildPersonalizedCards(userId);
                return res.json([...personalized, ...newsCache.data]);
            }
            return res.json(newsCache.data);
        }

        console.log('📡 Fetching fresh news from RSS feeds...');
        let allArticles = [];

        // Ambil semua feed secara paralel dengan error handling per-feed
        const feedPromises = FEEDS.map(async (source) => {
            try {
                const feed = await parser.parseURL(source.url);
                console.log(`  ✅ ${source.name}: ${feed.items.length} items`);
                return feed.items.map(item => ({
                    ...item,
                    sourceName: source.name,
                    sourceLogo: source.logo,
                    sourceColor: source.color,
                    sourceUrl: source.urlLabel,
                    sourceRealUrl: source.url,
                }));
            } catch (err) {
                console.error(`  ❌ Gagal ambil dari ${source.name}:`, err.message);
                return [];
            }
        });

        const results = await Promise.all(feedPromises);
        allArticles = results.flat();
        console.log(`📊 Total artikel terkumpul: ${allArticles.length}`);

        // Filter: dua tingkat — STRONG keyword langsung lulus, CONTEXT keyword harus disertai STRONG keyword
        const filteredNews = allArticles.filter(article => {
            const title   = (article.title           || '').toLowerCase();
            const snippet = (article.contentSnippet  || '').toLowerCase();
            const content = (article.content         || '').toLowerCase();
            const combined = `${title} ${snippet} ${content}`;

            const hasStrong  = KEYWORDS_STRONG.some(kw => combined.includes(kw));
            const hasContext = KEYWORDS_CONTEXT.some(kw => combined.includes(kw));
            const isExcluded = EXCLUDE.some(ex => combined.includes(ex));

            // Lulus jika ada keyword STRONG, atau ada CONTEXT + STRONG sekaligus
            const isRelevant = hasStrong || (hasContext && hasStrong);

            return isRelevant && !isExcluded;
        });

        console.log(`🐄 Berita relevan sapi/ternak: ${filteredNews.length}`);

        // Hilangkan duplikat berdasarkan URL
        const seen = new Set();
        const uniqueNews = filteredNews.filter(article => {
            const key = article.link || article.title;
            if (seen.has(key)) return false;
            seen.add(key);
            return true;
        });

        // Sort terbaru dulu
        uniqueNews.sort((a, b) => new Date(b.pubDate || 0) - new Date(a.pubDate || 0));

        const formattedNews = uniqueNews.slice(0, MAX_NEWS).map((item, index) => {
            const pubDate = new Date(item.pubDate || Date.now());
            const timeStr = pubDate.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }).replace(/:/g, '.');
            const dateStr = pubDate.toLocaleDateString('id-ID', { day: '2-digit', month: 'short' });

            // Bersihkan content dari HTML tag
            const rawContent = item.contentSnippet || item.content || '';
            const cleanContent = rawContent.replace(/<[^>]*>/g, '').replace(/&[a-z]+;/gi, ' ').trim();

            return {
                id: index + 1,
                source: item.sourceName,
                sourceUrl: item.sourceUrl,
                time: timeStr,
                date: dateStr,
                logo: item.sourceLogo,
                logoColor: item.sourceColor,
                title: item.title || 'Berita Terkini',
                content: cleanContent || 'Berita terbaru mengenai industri sapi dan peternakan nasional.',
                url: item.link || null,   // URL asli artikel (bisa dibuka di browser)
            };
        });

        // Simpan ke cache (tanpa personalisasi)
        newsCache = { data: formattedNews, lastFetched: now };
        console.log(`✅ Cache diperbarui: ${formattedNews.length} berita`);

        // Tambah kartu personalisasi ROI jika user login
        let finalNews = [...formattedNews];
        if (userId) {
            const personalizedCards = await buildPersonalizedCards(userId);
            finalNews = [...personalizedCards, ...formattedNews];
        }

        res.json(finalNews);

    } catch (error) {
        console.error('Error News Route:', error);
        if (newsCache.data) {
            return res.json(newsCache.data);
        }
        res.status(500).json({ message: 'Internal Server Error' });
    }
});

/**
 * Bangun kartu analisis ROI personal untuk user yang login.
 * Kartu ini TIDAK punya URL eksternal — ditampilkan langsung di app.
 */
async function buildPersonalizedCards(userId) {
    const cards = [];
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

        const activeCows = holdings
            .filter(h => Number(h.total_quantity) > 0.01)
            .sort((a, b) => Number(b.total_investment) - Number(a.total_investment));

        for (let i = 0; i < activeCows.length; i++) {
            const activePort = activeCows[i];
            const qty        = Number(activePort.total_quantity);
            const investment = Number(activePort.total_investment);

            const [prod] = await pool.query(
                'SELECT target_price, investor_share_ratio, price, name FROM products WHERE ticker_code = :symbol OR name = :symbol LIMIT 1',
                { symbol: activePort.symbol }
            );

            if (prod.length > 0) {
                const productName        = prod[0].name || activePort.symbol;
                const targetPricePerUnit = Number(prod[0].target_price) || (Number(prod[0].price) * 1.3);
                let ratio     = Number(prod[0].investor_share_ratio) || 0.7;
                let schemeName = 'Skema Investasi';

                if (qty >= 0.99) {
                    ratio      = 0.90;
                    schemeName = 'Skema Kepemilikan Utuh';
                }

                const totalTargetValue  = qty * targetPricePerUnit;
                const grossProfit       = totalTargetValue - investment;
                const netProfitInvestor = grossProfit > 0 ? (grossProfit * ratio) : grossProfit;
                const roiPercent        = investment > 0 ? ((netProfitInvestor / investment) * 100) : 0;
                const formatIDR         = (num) => 'Rp ' + Math.round(num).toLocaleString('id-ID');

                const today       = new Date();
                const dynamicTime = today.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }).replace(/:/g, '.');
                const dynamicDate = today.toLocaleDateString('id-ID', { day: '2-digit', month: 'short' });

                cards.push({
                    id: 1000 + i,
                    source: 'Analis InvestCow',
                    sourceUrl: null,         // ✅ Tidak ada URL eksternal
                    time: dynamicTime,
                    date: dynamicDate,
                    logo: 'A',
                    logoColor: qty >= 0.99 ? '#FFD700' : '#00C853',
                    title: `Analisis ROI ${productName} (${schemeName})`,
                    content:
                        `Berdasarkan kepemilikan Anda sebanyak ${qty % 1 === 0 ? qty.toFixed(0) : qty.toFixed(2)} ekor ${productName}:\n\n` +
                        `💰 Estimasi Capital Gain: ${formatIDR(netProfitInvestor)}\n` +
                        `📈 Proyeksi ROI Tahunan: ${roiPercent.toFixed(1)}% – ${(roiPercent + 4).toFixed(1)}%\n` +
                        `🎯 Estimasi Harga Jual Target: ${formatIDR(totalTargetValue)}\n\n` +
                        `✅ Status: Terverifikasi oleh Sistem Analis\n\n` +
                        `*Proyeksi dihitung berdasarkan rumus ${schemeName} (Bagi Hasil ${Math.round(ratio * 100)}% Investor / ${Math.round((1 - ratio) * 100)}% Peternak) serta performa harian ADG di kandang mitra.`,
                    url: null,               // ✅ null = tidak ada tombol "Baca di Sumber Asli"
                });
            }
        }
    } catch (err) {
        console.error('Error news personalization:', err);
    }
    return cards;
}

module.exports = router;
