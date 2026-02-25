import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'menu_page.dart';
import 'news_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();
  
  List<Map<String, dynamic>> _newsItems = [];
  bool _isLoadingNews = true;
  Timer? _refreshTimer;
  String _activeTab = 'Ikhtisar';
  
  int _totalOwnedCows = 0;
  double _totalInvestmentValue = 0.0;

  final List<Map<String, dynamic>> _cowPrices = [
    {
      'name': 'Sapi Madura',
      'price': 22450000,
      'change': '+1.78%',
      'up': true,
      'trend': [1.0, 1.2, 1.1, 1.4, 1.6, 1.5, 1.8],
    },
    {
      'name': 'Sapi Bali',
      'price': 19163600,
      'change': '-0.62%',
      'up': false,
      'trend': [1.8, 1.7, 1.8, 1.6, 1.5, 1.4, 1.3],
    },
    {
      'name': 'Sapi Brahman',
      'price': 25215400,
      'change': '+2.15%',
      'up': true,
      'trend': [1.2, 1.3, 1.2, 1.5, 1.7, 1.9, 2.1],
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchNews();
    _fetchPortfolioSummary();
    _startSimulation();
    
    // Auto refresh every 3 minutes for news and data
    _refreshTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      _fetchNews();
      _fetchPortfolioSummary();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPortfolioSummary() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final summaryUri = _apiClient.uri('/transactions/portfolio-summary');
      final res = await http.get(summaryUri, headers: _apiClient.jsonHeaders(token: token));
      
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        int total = 0;
        double value = 0.0;
        
        for (var item in data) {
          final qty = (double.tryParse(item['total_quantity'].toString()) ?? 0.0).toInt();
          total += qty;
          
          // Estimate value based on current simulated price if possible
          final ticker = item['symbol'].toString();
          final priceData = _cowPrices.firstWhere(
            (p) => p['name'].toString().contains(ticker) || ticker.contains(p['name'].toString()),
            orElse: () => {'price': 20000000}, // Default 20M fallback
          );
          value += qty * (priceData['price'] as int);
        }

        if (mounted) {
          setState(() {
            _totalOwnedCows = total;
            _totalInvestmentValue = value;
          });
        }
      }
    } catch (e) {
      debugPrint('Error sync portfolio on Home: $e');
    }
  }

  Future<void> _fetchNews() async {
    try {
      final res = await http.get(_apiClient.uri('/news'));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _newsItems = data.cast<Map<String, dynamic>>();
            _isLoadingNews = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetch news: $e');
      if (mounted) setState(() => _isLoadingNews = false);
    }
  }

  void _startSimulation() {
    // Simulate minor price changes every 10 seconds to feel "live"
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        for (var card in _cowPrices) {
          final double change = (0.5 - (DateTime.now().millisecond % 100) / 100.0) * 10000;
          card['price'] = (card['price'] as int) + change.toInt();
          // Update trend
          card['trend'].removeAt(0);
          card['trend'].add(1.0 + (change / 1000000));
          card['up'] = change >= 0;
          card['change'] = '${change >= 0 ? '+' : ''}${(change / card['price'] * 100).toStringAsFixed(2)}%';
        }
      });
    });
  }

  String _formatCurrency(int val) {
    return val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  final Color _premiumBlack = const Color(0xFF121212);
  final Color _accentGreen = const Color(0xFF00C853);
  final Color _accentRed = const Color(0xFFFF1744);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('InvestCow', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Tooltip(
            message: 'Menu InvestCow',
            child: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MenuPage())),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs Section
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['Ikhtisar', 'Harga Sapi', 'Pakan', 'Edukasi'].map((tab) {
                  bool isSelected = tab == _activeTab;
                  return GestureDetector(
                    onTap: () => setState(() => _activeTab = tab),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Conditional Content based on Tab
            if (_activeTab == 'Ikhtisar') ...[
              // Premium Portfolio Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _premiumBlack,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Est. Nilai Investasi', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(
                        _formatCurrency(_totalInvestmentValue.toInt()),
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: _accentGreen.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                            child: Text('▲ +12.5%', style: TextStyle(color: _accentGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          const Text('Bulan ini', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Dashboard Market Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _buildInfoCard('Pasar', 'Stabil', Icons.trending_up, Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInfoCard('Unit', '$_totalOwnedCows Ekor', Icons.pets, Colors.blue)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Harga Unggulan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              _buildPriceScroll(limit: 3),
            ]
 else if (_activeTab == 'Harga Sapi') ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Analisis Harga Pasar Hari Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Full price cards in Harga Sapi
              _buildPriceScroll(limit: null),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange[100]!)),
                  child: const Row(
                    children: [
                      Icon(Icons.tips_and_updates, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tip: Sapi Madura sedang mengalami lonjakan permintaan akibat persiapan stok lokal.',
                          style: TextStyle(fontSize: 12, color: Colors.brown),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (_activeTab == 'Pakan')
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informasi Pakan Nutrisi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildKnowledgeCard(
                      'Konsentrat Protein Tinggi (A1)',
                      'Diformulasikan khusus untuk fase penggemukan (fattening) 3-4 bulan dengan ADG optimal.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewsDetailPage(news: {
                              'title': 'Spesifikasi Konsentrat A1: Protokol Penggemukan',
                              'source': 'Nutrisi InvestCow',
                              'logo': 'P',
                              'logoColor': '#FF9800',
                              'date': '2026',
                              'time': 'Nutrisi',
                              'content': 'Konsentrat A1 adalah formula premium yang dikembangkan tim dokter hewan InvestCow untuk mencapai target Average Daily Gain (ADG) minimal 1.0kg per hari.\n\nKomposisi Utama:\n• Jagung Giling Grade A (45%): Sumber energi utama untuk energi gerak dan penambahan bobot.\n• Bungkil Kedelai & Kopra: Sumber protein bypass (protein tak terurai di rumen) untuk pembentukan otot.\n• Dedak Padi Halus: Meningkatkan palatabilitas (nafsu makan).\n• Molases & Probiotik: Membantu metabolisme pencernaan di lambung sapi agar penyerapan nutrisi maksimal.\n\nAturan Pakai:\nDiberikan 2-3% dari berat badan sapi per hari, dibagi menjadi dua sesi (pagi dan sore), dikombinasikan dengan silage rumput odot sebagai serat kasarnya.',
                            }),
                          ),
                        );
                      },
                    ),
                    _buildKnowledgeCard(
                      'Mineral Block & Vitamins',
                      'Suplemen esensial untuk menjaga imunitas, keseimbangan elektrolit, dan kekuatan tulang.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewsDetailPage(news: {
                              'title': 'Manajemen Suplemen: Mineral & Imunitas',
                              'source': 'Kesehatan InvestCow',
                              'logo': 'V',
                              'logoColor': '#2196F3',
                              'date': '2026',
                              'time': 'Nutrisi',
                              'content': 'Selain pakan utama, sapi membutuhkan mikro-nutrisi untuk menjaga performa biologisnya tetap stabil di berbagai kondisi cuaca.\n\nManfaat Mineral Block:\n1. Pencegahan Defisiensi: Menghindari kram otot (tetany) dan kelumpuhan mendadak.\n2. Optimalisasi Tulang: Phosphorus dan Kalsium yang cukup menjamin kerangka sapi tetap kuat menopang penambahan bobot yang cepat (fattening).\n3. Tingkatkan Nafsu Makan: Kandungan Sodium merangsang produksi saliva dan nafsu makan sapi tetap tinggi.\n\nVitamin Esensial (A, D, E & B-Complex):\n• Vitamin A: Menjaga integritas jaringan mukosa dan penglihatan.\n• Vitamin E & SE: Bertindak sebagai antioksidan kuat untuk menekan level stres sapi akibat panas (Heat Stress).\n\nSistem di kandang mitra kami menggunakan "Self-Selective Mineral Block" yang digantung di dekat tempat minum, sehingga sapi bisa mengonsumsi sendiri sesuai kebutuhan tubuhnya.',
                            }),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

            if (_activeTab == 'Edukasi')
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Katalog Investasi Edu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildKnowledgeCard(
                      'Mitigasi Risiko Ternak',
                      'Strategi perlindungan aset melalui asuransi ternak dan protokol kesehatan mandiri.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewsDetailPage(news: {
                              'title': 'Panduan Mitigasi Risiko Investasi Ternak',
                              'source': 'InvestCow Edu',
                              'logo': 'E',
                              'logoColor': '#FF9800',
                              'date': '2026',
                              'time': 'Edukasi',
                              'content': 'InvestCow menerapkan 3 lapis perlindungan:\n\n1. Asuransi Ternak (Jasindo): Proteksi kematian akibat penyakit atau kecelakaan.\n2. Protokol Biosecurity: Sterilisasi kandang tiap 48 jam dan monitoring CCTV AI.\n3. Dana Cadangan Likuid: 5% dari tiap investasi dialokasikan untuk penanganan darurat medik hewan.\n\nDengan sistem ini, risiko kerugian modal dapat ditekan hingga di bawah 2% per siklus.',
                            }),
                          ),
                        );
                      },
                    ),
                    _buildKnowledgeCard(
                      'Proyeksi ROI 2026',
                      'Estimasi imbal hasil berdasarkan portofolio aktif Anda saat ini.',
                      onTap: () {
                        final estProfit = _totalOwnedCows * 4250000; // Est profit per cow/year
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewsDetailPage(news: {
                              'title': 'Analisis Proyeksi ROI Portofolio',
                              'source': 'Analis InvestCow',
                              'logo': 'A',
                              'logoColor': '#4CAF50',
                              'date': 'Target 2026',
                              'time': 'Proyeksi',
                              'content': 'Berdasarkan kepemilikan Anda sebanyak $_totalOwnedCows ekor:\n\n• Estimasi Capital Gain: Rp ${_formatCurrency(estProfit)}\n• Proyeksi ROI Tahunan: 18.5% - 22.1%\n• Estimasi Harga Jual Target: Rp ${_formatCurrency((_totalInvestmentValue * 1.2).toInt())}\n\n*Proyeksi ini dihitung berdasarkan rata-rata kenaikan harga daging nasional dan performa harian sapi (ADG) di kandang mitra kami.',
                            }),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            // News Flow Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: _fetchNews,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Aliran Berita >',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (_isLoadingNews)
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // News List
            if (_isLoadingNews && _newsItems.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: Text('Memuat berita real-time...', style: TextStyle(color: Colors.grey))),
              )
            else if (_newsItems.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: Text('Gagal mengambil berita.', style: TextStyle(color: Colors.grey))),
              )
            else
              ..._newsItems.map((news) {
                final colorStr = news['logoColor']?.toString() ?? '#2196F3';
                final Color logoColor = Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
                
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewsDetailPage(news: news),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: logoColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            news['logo'] ?? 'N',
                            style: TextStyle(color: logoColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${news['time']} · ${news['date']} · ${news['source']}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                news['title'],
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

            const Divider(thickness: 0.5),
            
            // Re-styled Existing Knowledge Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wawasan Peternakan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildKnowledgeCard(
                    '1. Dasar-dasar Peternakan Sapi',
                    'Kuasai manajemen pakan, sanitasi, dan nutrisi untuk memastikan pertumbuhan bobot sapi yang optimal.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewsDetailPage(news: {
                            'title': 'Dasar-dasar Peternakan Sapi Modern',
                            'source': 'Akademia InvestCow',
                            'logo': 'A',
                            'logoColor': '#2196F3',
                            'date': '2026',
                            'time': 'Edukasi',
                            'content': 'Peternakan sapi yang sukses dimulai dari manajemen harian yang disiplin. \n\nHal-hal mendasar yang wajib Anda pahami:\n\n1. Manajemen Pakan: Pemberian ransum hijauan (rumput gajah/odot) dikombinasikan dengan konsentrat protein 14-16% dengan rasio 60:40.\n\n2. Kebersihan Kandang: Sanitasi rutin minimal 2x sehari untuk mencegah penyakit kuku, mulut, dan lalat pembawa virus.\n\n3. Penimbangan Rutin: Sapi rutin ditimbang untuk memantau ADG (Average Daily Gain). Target InvestCow adalah 0.8 - 1.2 kg per hari.\n\n4. Pemberian Nutrisi: Penggunaan Mineral Block dan Vitamin B-Complex sangat penting untuk meningkatkan imunitas dan nafsu makan sapi terutama di musim penghujan.',
                          }),
                        ),
                      );
                    },
                  ),
                  _buildKnowledgeCard(
                    '2. Faktor Harga Sapi',
                    'Pelajari variabel penentu harga pasar mulai dari bobot, genetik, hingga tren musiman seperti Idul Adha.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewsDetailPage(news: {
                            'title': 'Analisis Faktor Penentu Harga Sapi',
                            'source': 'Pasar InvestCow',
                            'logo': 'P',
                            'logoColor': '#F44336',
                            'date': '2026',
                            'time': 'Edukasi',
                            'content': 'Harga sapi di pasar sangat dinamis dan dipengaruhi oleh kriteria fisik serta momentum waktu. \n\nKomponen Utama Penentu Harga:\n\n1. Bobot Badan (Live Weight): Ini adalah faktor paling dominan. Harga biasanya dihitung per kg berat hidup sesuai timbangan digital.\n\n2. Jenis Genetik: Sapi eksotis seperti Limousin, Simmental, dan Angus memiliki nilai jual lebih tinggi dibanding sapi lokal karena persentase daging (karkas) yang mencapai 50-60%.\n\n3. Usia & Kondisi Gigi (Poel): Ketentuan qurban mengharuskan sapi minimal poel 1 (gigi tetap sudah berganti). Sapi poel memiliki nilai pasar yang premium.\n\n4. Momentum Hari Raya: Menjelang Idul Adha, harga sapi biasanya melonjak 20-35% dari harga normal. InvestCow membantu mitra memanfaatkan momentum ini untuk maksimalisasi ROI.',
                          }),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKnowledgeCard(String title, String content, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                if (onTap != null) const Icon(Icons.chevron_right, size: 18, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 13, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPriceScroll({int? limit}) {
    final displayItems = limit == null ? _cowPrices : _cowPrices.take(limit).toList();
    return SizedBox(
      height: 120,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: displayItems.length,
        itemBuilder: (context, index) {
          final item = displayItems[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  '${_formatCurrency(item['price'])} IDR',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  item['change'],
                  style: TextStyle(
                    color: item['up'] ? _accentGreen : _accentRed,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 24,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: SparklinePainter(item['trend'] as List<double>, item['up'] ? _accentGreen : _accentRed),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Sparkline Painter for mini charts
class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final double dx = size.width / (data.length - 1);
    final double max = data.reduce((a, b) => a > b ? a : b);
    final double min = data.reduce((a, b) => a < b ? a : b);
    final double range = max - min == 0 ? 1 : max - min;

    for (int i = 0; i < data.length; i++) {
      final x = i * dx;
      final y = size.height - ((data[i] - min) / range * size.height);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class InvestCowIcon extends StatelessWidget {
  const InvestCowIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF00BCD4), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
            ),
          ),
          // Trend up line
          Icon(
            Icons.trending_up,
            color: Colors.white,
            size: 54,
          ),
          // Small dot accent (represents price point)
          Positioned(
            right: 34,
            top: 38,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Tooltip(
            message: 'Menu InvestCow',
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MenuPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
