const express = require('express');
const router = express.Router();


// Simulated real news for cattle/livestock
// In a production app, you might use a News API or scrape an RSS feed.
router.get('/', async (req, res) => {
    try {
        // Current date for simulation
        const now = new Date();
        const dateStr = now.toLocaleDateString('id-ID', { day: 'numeric', month: 'short' });
        const timeStr = now.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });

        const news = [
            {
                id: 1,
                source: 'Kontan Ternak',
                sourceUrl: 'kontan.co.id',
                time: timeStr,
                date: dateStr,
                logo: 'K',
                title: 'Laju Kenaikan Harga Sapi Bakalan di Jawa Timur Mencapai 5 Persen Jelang Ramadhan',
                content: 'SURABAYA - Harga komoditas sapi bakalan di wilayah Jawa Timur tercatat mengalami kenaikan signifikan sebesar 5 persen dalam kurun waktu satu pekan terakhir. Kenaikan ini dipicu oleh tingginya prospek permintaan pasar menjelang bulan suci Ramadhan serta hari raya Idul Fitri mendatang. \n\nKetua Gabungan Peternak Sapi Potong Jawa Timur mengonfirmasi bahwa saat ini para pedagang dan investor mulai aktif menambah stok ternak guna mengantisipasi lonjakan konsumsi daging nasional. Selain faktor musiman, stabilitas pasokan pakan konsentrat juga menjadi faktor pendukung optimisme para peternak lokal dalam meningkatkan skala produksinya.',
                logoColor: '#2196F3',
            },
            {
                id: 2,
                source: 'Bursa Sapi',
                sourceUrl: 'bursasapi.com',
                time: '04.41',
                date: dateStr,
                logo: 'B',
                title: 'Australia dan Indonesia Jajaki Kerjasama Strategis Pengembangan Klaster Penggemukan Sapi',
                content: 'LAMPUNG - Pemerintah Australia melalui departemen perdagangan internasional sedang mendalami peluang kerjasama investasi dalam pengembangan teknologi penggemukan sapi (feedlot) di wilayah Lampung dan Nusa Tenggara Barat. Kerjasama ini bertujuan untuk mentransfer pengetahuan di bidang manajemen nutrisi pakan serta perbaikan mutu genetik ternak. \n\nDelegasi Australia menyatakan bahwa Indonesia tetap menjadi mitra strategis utama dalam rantai pasok daging sapi global. Dengan implementasi teknologi manajemen terbaru, diharapkan kapasitas produksi unit penggemukan di Indonesia dapat meningkat hingga 15-20 persen dalam dua tahun ke depan.',
                logoColor: '#FF9800',
            },
            {
                id: 3,
                source: 'Global Agri',
                sourceUrl: 'globalagriculture.org',
                time: '03.15',
                date: dateStr,
                logo: 'G',
                title: 'Cow Investment Overview: The Role of Bovine Assets in a Diversified Global Portfolio',
                content: 'LONDON - Global agricultural analysts highlight that livestock assets, particularly cattle, are increasingly becoming a fundamental component of institutional investment portfolios. In an era of economic volatility, bovine assets demonstrate a strong correlation with food security demands, making them a resilient hedge against inflation. \n\nThe latest report indicates that massive demand for premium protein sources in emerging markets is driving long-term valuation growth. Investors are increasingly utilizing digital platforms to access direct ownership models in cattle farming, which offers transparent monitoring and consistent biological growth yields.',
                logoColor: '#4CAF50',
            },
            {
                id: 4,
                source: 'Info Pangan',
                sourceUrl: 'infopangan.id',
                time: '02.10',
                date: dateStr,
                logo: 'I',
                title: 'Kementerian Pertanian Mengalokasikan Subsidi Bahan Baku Pakan Guna Menjaga Stabilitas Harga Daging',
                content: 'JAKARTA - Guna menekan biaya produksi di tingkat peternak rakyat, Kementerian Pertanian secara resmi meluncurkan program subsidi bahan baku pakan mandiri. Program ini berfokus pada penguatan kapasitas produksi pabrik pakan skala kecil di sentra-sentra peternakan nasional untuk mengurangi ketergantungan pada bahan baku impor. \n\nMenteri Pertanian menegaskan bahwa efisiensi biaya pakan merupakan kunci utama dalam mempertahankan daya saing daging sapi lokal di pasar domestik. Inisiatif ini juga diharapkan mampu menjaga margin keuntungan peternak agar tetap stabil di tengah fluktuasi harga komoditas jagung global.',
                logoColor: '#F44336',
            }
        ];

        return res.json(news);
    } catch (e) {
        console.error('News error:', e);
        return res.status(500).json({ message: 'Error fetching news' });
    }
});

module.exports = router;
