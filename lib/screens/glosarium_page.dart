import 'package:flutter/material.dart';

class GlosariumPage extends StatefulWidget {
  const GlosariumPage({super.key});

  @override
  State<GlosariumPage> createState() => _GlosariumPageState();
}

class _GlosariumPageState extends State<GlosariumPage> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<Map<String, dynamic>> _allTerms = [
    {
      'term': 'Asuransi Ternak (Livestock Insurance)',
      'desc': 'Perlindungan bagi investor jika sapi mengalami kematian akibat penyakit, kecelakaan, atau bencana alam. Menjamin keamanan modal bibit investor.',
      'icon': Icons.security
    },
    {
      'term': 'Mitigasi Risiko',
      'desc': 'Langkah pencegahan kerugian, seperti vaksinasi, tim dokter hewan standby, dan pemilihan bibit unggul.',
      'icon': Icons.admin_panel_settings_outlined
    },
    {
      'term': 'Ikhtisar (Overview)',
      'desc': 'Ringkasan atau gambaran umum dari seluruh portofolio dan aktivitas investasi Anda secara cepat.',
      'icon': Icons.summarize_outlined
    },
    {
      'term': 'Total Est. Nilai Investasi',
      'desc': 'Estimasi nilai seluruh aset (sapi) yang Anda miliki jika diuangkan berdasarkan harga pasar saat ini.',
      'icon': Icons.account_balance_wallet_outlined
    },
    {
      'term': 'ROI (Return on Investment)',
      'desc': 'Rasio keuntungan atau kerugian (dalam persentase) yang dihasilkan dari investasi relatif terhadap jumlah modal yang diinvestasikan.',
      'icon': Icons.pie_chart_outline
    },
    {
      'term': 'ADG (Average Daily Gain)',
      'desc': 'Rata-rata pertambahan berat badan harian pada sapi dalam periode tertentu. Semakin tinggi ADG, semakin cepat nilai aset Anda bertambah.',
      'icon': Icons.monitor_weight_outlined
    },
    {
      'term': 'Fattening (Penggemukan)',
      'desc': 'Program pemberian pakan intensif untuk meningkatkan bobot sapi secara cepat sebelum dipasarkan.',
      'icon': Icons.trending_up_outlined
    },
    {
      'term': 'Ticker Code',
      'desc': 'Kode unik identitas jenis sapi di pasar InvestCow. Contoh: MADURA untuk Sapi Madura, PO-01 untuk Sapi Peranakan Ongole.',
      'icon': Icons.qr_code_outlined
    },
    {
      'term': 'Bullish',
      'desc': 'Istilah pasar ketika harga sapi sedang dalam tren naik yang optimis.',
      'icon': Icons.trending_up_rounded
    },
    {
      'term': 'Bearish',
      'desc': 'Istilah pasar ketika harga sapi sedang dalam tren turun atau pesimistis.',
      'icon': Icons.trending_down_rounded
    },
    {
      'term': 'Accumulation (Akumulasi)',
      'desc': 'Fase di mana investor cenderung mulai membeli kembali aset saat harga dianggap sudah murah atau stabil sebelum terjadi kenaikan.',
      'icon': Icons.add_business_outlined
    },
    {
      'term': 'Portfolio (Portofolio)',
      'desc': 'Kumpulan seluruh aset atau instrumen investasi yang dimiliki oleh seorang investor.',
      'icon': Icons.folder_shared_outlined
    },
    {
      'term': 'Diversifikasi',
      'desc': 'Strategi menyebar investasi pada berbagai jenis sapi (misal: Madura dan Brahman) untuk meminimalkan risiko.',
      'icon': Icons.diversity_3_outlined
    },
    {
      'term': 'Capital Gain',
      'desc': 'Keuntungan yang didapat dari selisih harga jual yang lebih tinggi dibandingkan dengan harga beli awal.',
      'icon': Icons.payments_outlined
    },
    {
      'term': 'Volatilitas',
      'desc': 'Tingkat fluktuasi atau naik-turunnya harga aset dalam periode waktu tertentu.',
      'icon': Icons.waves_outlined
    },
    {
      'term': 'Likuiditas',
      'desc': 'Seberapa cepat atau mudah sebuah aset investasi dapat dicairkan kembali menjadi uang tunai (saldo kas).',
      'icon': Icons.paid_outlined
    },
    {
      'term': 'Weighted Average Cost (WAC)',
      'desc': 'Perhitungan harga beli rata-rata tertimbang jika Anda melakukan pembelian sapi yang sama di harga yang berbeda-beda.',
      'icon': Icons.calculate_outlined
    },
    {
      'term': 'Unit',
      'desc': 'Satuan kepemilikan aset di InvestCow. 1 Unit berarti kepemilikan atas 1 ekor sapi secara utuh.',
      'icon': Icons.inventory_2_outlined
    },
    {
      'term': 'Konsentrat',
      'desc': 'Pakan padat nutrisi tinggi yang digunakan untuk mempercepat pertumbuhan berat badan sapi.',
      'icon': Icons.grass_outlined
    },
    {
      'term': 'Lindung Nilai (Hedge)',
      'desc': 'Strategi investasi untuk melindungi nilai kekayaan dari risiko kerugian akibat inflasi atau penurunan nilai mata uang.',
      'icon': Icons.shield_outlined
    },
    {
      'term': 'Live Stream',
      'desc': 'Siaran video langsung melalui kamera CCTV untuk memantau kondisi sapi dan aktivitas di kandang secara real-time.',
      'icon': Icons.videocam_outlined
    },
    {
      'term': 'Verifikasi',
      'desc': 'Proses pengecekan dan validasi secara berkala terhadap kondisi fisik sapi dan data peternak oleh tim InvestCow.',
      'icon': Icons.verified_outlined
    },
    {
      'term': 'Bagi Hasil (Profit Sharing)',
      'desc': 'Sistem distribusi keuntungan antara investor dan peternak. InvestCow menerapkan dua skema:\n• Skema Investasi (Fraksional): 70% Investor / 30% Peternak.\n• Skema Kepemilikan Utuh: 90% Investor / 10% Peternak.',
      'icon': Icons.handshake_outlined
    },
  ];

  List<Map<String, dynamic>> _filteredTerms = [];

  @override
  void initState() {
    super.initState();
    // Sort terms A-Z by term name
    _allTerms.sort((a, b) => a['term'].toString().toLowerCase().compareTo(b['term'].toString().toLowerCase()));
    _filteredTerms = _allTerms;
  }

  void _filterSearch(String query) {
    setState(() {
      _filteredTerms = _allTerms
          .where((item) =>
              item['term']!.toString().toLowerCase().contains(query.toLowerCase()) ||
              item['desc']!.toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Glosarium InvestCow', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Elegant Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _filterSearch,
              decoration: InputDecoration(
                hintText: 'Cari istilah investasi...',
                prefixIcon: const Icon(Icons.search, color: Colors.cyan),
                filled: true,
                fillColor: const Color(0xFFF1F3F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          Expanded(
            child: _filteredTerms.isEmpty
                ? const Center(child: Text('Istilah tidak ditemukan.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTerms.length,
                    itemBuilder: (context, index) {
                      final item = _filteredTerms[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.cyan.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(item['icon'] as IconData, color: Colors.cyan, size: 24),
                            ),
                            title: Text(
                              item['term']!.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                child: Text(
                                  item['desc']!.toString(),
                                  style: TextStyle(color: Colors.grey[600], height: 1.5, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
