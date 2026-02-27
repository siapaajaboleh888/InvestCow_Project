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
      'term': 'Ikhtisar',
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
      'desc': 'Rasio keuntungan atau kerugian yang dihasilkan dari investasi relatif terhadap jumlah modal yang diinvestasikan.',
      'icon': Icons.pie_chart_outline
    },
    {
      'term': 'ADG (Average Daily Gain)',
      'desc': 'Rata-rata pertambahan berat badan harian pada sapi dalam periode tertentu (biasanya gram/hari).',
      'icon': Icons.monitor_weight_outlined
    },
    {
      'term': 'Fattening (Penggemukan)',
      'desc': 'Program pemberian pakan intensif untuk meningkatkan bobot sapi secara cepat sebelum dipasarkan.',
      'icon': Icons.trending_up_outlined
    },
    {
      'term': 'Ticker Code',
      'desc': 'Kode unik identitas jenis sapi di pasar modal InvestCow (Contoh: MD-01 untuk Sapi Madura).',
      'icon': Icons.qr_code_outlined
    },
    {
      'term': 'Sentimen Pasar',
      'desc': 'Kondisi psikologis pasar yang mempengaruhi tren harga (Stabil, Bullish/Naik, atau Bearish/Turun).',
      'icon': Icons.psychology_outlined
    },
    {
      'term': 'Unit',
      'desc': 'Satuan kepemilikan aset di InvestCow. 1 Unit berarti kepemilikan atas 1 ekor sapi.',
      'icon': Icons.inventory_2_outlined
    },
    {
      'term': 'Konsentrat',
      'desc': 'Pakan padat nutrisi tinggi yang digunakan untuk mempercepat pertumbuhan berat badan sapi.',
      'icon': Icons.grass_outlined
    },
    {
      'term': 'Bagi Hasil (Profit Sharing)',
      'desc': 'Sistem distribusi keuntungan antara investor dan peternak. InvestCow menerapkan dua skema: (1) Skema Investasi: 70% Investor / 30% Peternak untuk investasi nominal. (2) Skema Kepemilikan Utuh: 90% Investor / 10% Peternak untuk pembelian sapi secara utuh (>= 1 ekor) sebagai biaya jasa pemeliharaan.',
      'icon': Icons.handshake_outlined
    },
  ];

  List<Map<String, dynamic>> _filteredTerms = [];

  @override
  void initState() {
    super.initState();
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
