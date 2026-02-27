import 'package:flutter/material.dart';

class GlosariumPage extends StatefulWidget {
  const GlosariumPage({super.key});

  @override
  State<GlosariumPage> createState() => _GlosariumPageState();
}

class _GlosariumPageState extends State<GlosariumPage> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<Map<String, String>> _allTerms = [
    {
      'term': 'Ikhtisar',
      'desc': 'Ringkasan atau gambaran umum dari seluruh portofolio dan aktivitas investasi Anda secara cepat.',
      'icon': '📊'
    },
    {
      'term': 'Total Est. Nilai Investasi',
      'desc': 'Estimasi nilai seluruh aset (sapi) yang Anda miliki jika diuangkan berdasarkan harga pasar saat ini.',
      'icon': '💰'
    },
    {
      'term': 'ADG (Average Daily Gain)',
      'desc': 'Rata-rata pertambahan berat badan harian pada sapi dalam periode tertentu (biasanya gram/hari).',
      'icon': '⚖️'
    },
    {
      'term': 'Fattening (Penggemukan)',
      'desc': 'Program pemberian pakan intensif untuk meningkatkan bobot sapi secara cepat sebelum dipasarkan.',
      'icon': '🐄'
    },
    {
      'term': 'Ticker Code',
      'desc': 'Kode unik identitas jenis sapi di pasar modal InvestCow (Contoh: MD-01 untuk Sapi Madura).',
      'icon': '🆔'
    },
    {
      'term': 'Sentimen Pasar',
      'desc': 'Kondisi psikologis pasar yang mempengaruhi tren harga (Stabil, Bullish/Naik, atau Bearish/Turun).',
      'icon': '📈'
    },
    {
      'term': 'Unit',
      'desc': 'Satuan kepemilikan aset di InvestCow. 1 Unit berarti kepemilikan atas 1 ekor sapi.',
      'icon': '🐾'
    },
    {
      'term': 'Konsentrat',
      'desc': 'Pakan padat nutrisi tinggi yang digunakan untuk mempercepat pertumbuhan berat badan sapi.',
      'icon': '🌾'
    },
  ];

  List<Map<String, String>> _filteredTerms = [];

  @override
  void initState() {
    super.initState();
    _filteredTerms = _allTerms;
  }

  void _filterSearch(String query) {
    setState(() {
      _filteredTerms = _allTerms
          .where((item) =>
              item['term']!.toLowerCase().contains(query.toLowerCase()) ||
              item['desc']!.toLowerCase().contains(query.toLowerCase()))
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
                              child: Text(item['icon']!, style: const TextStyle(fontSize: 20)),
                            ),
                            title: Text(
                              item['term']!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                child: Text(
                                  item['desc']!,
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
