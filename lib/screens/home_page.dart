import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'menu_page.dart';
import 'news_detail_page.dart';
import 'riwayat_page.dart';
import 'pasar_page.dart';
import 'glosarium_page.dart';
import 'cctv_page.dart';

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
  
  double _totalOwnedCows = 0.0;
  double _totalInvestmentValue = 0.0;
  List<Map<String, dynamic>> _portfolioHoldings = [];

  final List<Map<String, dynamic>> _cowPrices = [
    {
      'name': 'Sapi Madura',
      'price': 22450000,
      'change': '+1.78%',
      'up': true,
      'trend': [1.0, 1.2, 1.1, 1.4, 1.6, 1.5, 1.8],
      'image': '/uploads/sapi_madura.jpg',
    },
    {
      'name': 'Sapi Brahman Premium',
      'price': 25215400,
      'change': '+2.15%',
      'up': true,
      'trend': [1.2, 1.3, 1.2, 1.5, 1.7, 1.9, 2.1],
      'image': '/uploads/sapi_brahman_premium.jpg',
    },
    {
      'name': 'Sapi Angus Pedaging',
      'price': 38450000,
      'change': '+3.45%',
      'up': true,
      'trend': [2.0, 2.2, 2.5, 2.8, 3.1, 3.2, 3.5],
      'image': '/uploads/sapi_angus_premium.jpg',
    },
    {
      'name': 'Sapi Limousin',
      'price': 32150000,
      'change': '-1.20%',
      'up': false,
      'trend': [3.5, 3.4, 3.2, 3.1, 3.0, 2.9, 2.8],
      'image': '/uploads/sapi_limousin.jpg',
    },
    {
      'name': 'Sapi Peranakan Ongole (PO)',
      'price': 19970000,
      'change': '+0.45%',
      'up': true,
      'trend': [1.5, 1.6, 1.5, 1.7, 1.6, 1.8, 1.9],
      'image': '/uploads/sapi_bali.jpg',
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
        double totalUnits = 0.0;
        double value = 0.0;
        
        final List<Map<String, dynamic>> holdings = [];
        
        for (var item in data) {
          final qty = double.tryParse(item['total_quantity'].toString()) ?? 0.0;
          totalUnits += qty;
          
          final ticker = item['symbol'].toString();
          final priceData = _cowPrices.firstWhere(
            (p) => p['name'].toString().toLowerCase().contains(ticker.toLowerCase()) || 
                   ticker.toLowerCase().contains(p['name'].toString().toLowerCase()),
            orElse: () => {'price': 22450000}, // Use Madura as baseline default if fail
          );
          
          final currentVal = qty * (priceData['price'] as int);
          value += currentVal;

          holdings.add({
            'symbol': ticker,
            'quantity': qty,
            'currentValue': currentVal,
            'isWhole': qty >= 1.0,
          });
        }

        if (mounted) {
          setState(() {
            _totalOwnedCows = totalUnits;
            _totalInvestmentValue = value;
            _portfolioHoldings = holdings;
          });
        }
      }
    } catch (e) {
      debugPrint('Error sync portfolio on Home: $e');
    }
  }

  Future<void> _fetchNews() async {
    try {
      final token = await _authService.getToken();
      final res = await http.get(_apiClient.uri('/news'), headers: _apiClient.jsonHeaders(token: token));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            // Filter out ROI analysis news from main feed as requested
            _newsItems = data
                .cast<Map<String, dynamic>>()
                .where((news) => !news['title'].toString().contains('Analisis ROI'))
                .toList();
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

  String _formatCurrency(num val) {
    return 'Rp ' + val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  final Color _premiumBlack = const Color(0xFF121212);
  final Color _accentGreen = const Color(0xFF00C853);
  final Color _accentRed = const Color(0xFFFF1744);
  final Color _softGrey = const Color(0xFFF5F5F7);
  final Color _accentBlue = const Color(0xFF2196F3);

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
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MenuPage())),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00CED1), Color(0xFF008B8B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF008B8B).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2.5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/investcow.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: ['Ikhtisar', 'Harga Sapi', 'Pakan', 'Edukasi'].map((tab) {
                  bool isSelected = tab == _activeTab;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _activeTab = tab);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                          else
                            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
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
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_premiumBlack, const Color(0xFF333333)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Est. Nilai Investasi', style: TextStyle(color: Colors.white60, fontSize: 13, letterSpacing: 0.5)),
                          IconButton(
                            icon: Icon(Icons.account_balance_wallet_outlined, color: Colors.white.withOpacity(0.3), size: 20),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatPage())),
                            tooltip: 'Riwayat Transaksi',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatCurrency(_totalInvestmentValue.toInt()),
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.trending_up, color: _accentGreen, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              _totalInvestmentValue > 0 ? '+12.5%' : '+0.0%',
                              style: TextStyle(color: _accentGreen, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const Text('Bulan ini', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
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
                    Expanded(child: _buildInfoCard('Status Pasar', 'Stabil', Icons.analytics_outlined, Colors.green)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInfoCard('Total Unit', '${_totalOwnedCows % 1 == 0 ? _totalOwnedCows.toInt() : _totalOwnedCows.toStringAsFixed(2)} Ekor', Icons.pets_outlined, Colors.blue)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Analisis Pasar Hari Ini Block
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[900]!, Colors.blue[700]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => _showMarketTechnicalDetails(),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            const Text('Analisis Pasar Hari Ini', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                              child: const Text('ACCUMULATION', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMarketStat('Sentimen', 'Positif', Icons.trending_up, Colors.greenAccent, () => _showSentimentDetails()),
                            _buildMarketStat('Volatilitas', 'Stabil', Icons.waves, Colors.orangeAccent, () => _showVolatilityDetails()),
                            _buildMarketStat('Kepercayaan', '92%', Icons.verified_user, Colors.lightBlueAccent, () => _showConfidenceDetails()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 8),
                        const Text(
                          'Kesimpulan: Kondisi pasar sedang dalam fase akumulasi sehat. Fluktuasi harga mikro saat ini adalah wajar sebelum potensi kenaikan di periode berikutnya.',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Wawasan Cerdas Block
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                child: InkWell(
                  onTap: () => _showDetailedInsights(),
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.orange[100], shape: BoxShape.circle),
                            child: const Icon(Icons.psychology_outlined, color: Colors.orange),
                          ),
                          const SizedBox(width: 12),
                          const Text('Wawasan Cerdas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSmartInsight(
                        'Permintaan Nasional',
                        'Meningkatnya kebutuhan daging sapi menjelang hari besar nasional mengerek harga jual seluruh jenis sapi.',
                        Icons.trending_up,
                        () => _showInsightDetail(
                          'Permintaan Nasional',
                          'Menjelang hari besar nasional (seperti Idul Adha dan Idul Fitri), data historis menunjukkan peningkatan permintaan daging sapi hingga 300%. Hal ini menciptakan sentimen positif yang kuat pada seluruh aset ternak tanpa terkecuali.',
                          'Pertimbangkan untuk menambah unit sebelum H-60 hari besar untuk memaksimalkan potensi kenaikan harga.'
                        ),
                      ),
                      const Divider(height: 24),
                      _buildSmartInsight(
                        'Efisiensi Pakan',
                        'Inovasi pakan fermentasi berhasil menekan biaya operasional di seluruh kemitraan peternakan.',
                        Icons.eco_outlined,
                        () => _showInsightDetail(
                          'Efisiensi Pakan',
                          'Penggunaan teknologi pengolahan pakan silase dan fermentasi memungkinkan peternak kemitraan InvestCow menekan biaya hingga 15% setiap harinya. Efisiensi ini langsung meningkatkan margin bagi hasil bagi investor.',
                          'Pantau laporan kesehatan sapi secara berkala untuk melihat dampak nutrisi pakan terhadap ADG (Average Daily Gain).'
                        ),
                      ),
                      const Divider(height: 24),
                      _buildSmartInsight(
                        'Proyeksi 2026',
                        'Laporan pasar menunjukkan tren positif investasi aset ternak sebagai lindung nilai inflasi.',
                        Icons.public,
                        () => _showInsightDetail(
                          'Proyeksi 2026',
                          'Ternak sapi adalah aset riil yang memiliki korelasi rendah dengan pasar saham namun korelasi tinggi dengan inflasi. Di tahun 2026, diprediksi pasokan global akan mengetat, menjadikan kepemilikan sapi sebagai pelindung nilai kekayaan yang aman.',
                          'Pertahankan portofolio jangka panjang (di atas 1 tahun) untuk mendapatkan keuntungan maksimal dari siklus pertumbuhan sapi.'
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
              const SizedBox(height: 16),
              // Risk Protection Block
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => _showRiskProtectionDetails(),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Perlindungan & Mitigasi Risiko', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                SizedBox(height: 4),
                                Text('Bagaimana jika sapi sakit atau mati?', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // New Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 8),
                    const Text('Harga Unggulan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PasarPage())),
                      child: const Text('Lihat Grafik', style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildPriceScroll(limit: 3),
              const SizedBox(height: 32),

              // News Flow moved here (Contextual to Overview)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Aliran Berita',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: _fetchNews,
                      child: Row(
                        children: [
                          Text(_isLoadingNews ? 'Memuat...' : 'Terbaru', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          if (!_isLoadingNews) const Icon(Icons.refresh, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              if (_isLoadingNews && _newsItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_newsItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('Belum ada berita baru.')),
                )
              else
                ..._newsItems.map((news) => _buildNewsCard(news)).toList(),
              
              const SizedBox(height: 20),
            ]
            else if (_activeTab == 'Harga Sapi') ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Daftar Harga Sapi Live', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Pantau pergerakan harga pasar secara real-time', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildPriceScroll(limit: null),
              const SizedBox(height: 30),
            ]
            else if (_activeTab == 'Pakan') ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informasi Pakan Nutrisi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Optimalkan pertumbuhan aset dengan nutrisi terbaik', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 24),
                    _buildKnowledgeCard(
                      'Konsentrat Protein Tinggi (A1)',
                      'Diformulasikan khusus untuk fase penggemukan (fattening) 3-4 bulan dengan ADG optimal.',
                      icon: Icons.grass,
                      color: Colors.orange,
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
                      icon: Icons.health_and_safety,
                      color: Colors.blue,
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
            ]
            else if (_activeTab == 'Edukasi') ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Katalog Investasi Edu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Pelajari cara berinvestasi dengan cerdas dan aman', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 24),
                    _buildKnowledgeCard(
                      'Glosarium InvestCow',
                      'Pahami istilah-istilah sulit seperti Ikhtisar, ADG, Fattening, dan lainnya.',
                      icon: Icons.book_outlined,
                      color: Colors.blueAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const GlosariumPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildKnowledgeCard(
                      'Mitigasi Risiko Ternak',
                      'Strategi perlindungan aset melalui asuransi ternak dan protokol kesehatan mandiri.',
                      icon: Icons.shield_outlined,
                      color: Colors.teal,
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
                      icon: Icons.trending_up,
                      color: Colors.green,
                      onTap: () {
                        // Generate dynamic breakdown content
                        String breakdown = 'Detail Kepemilikan Anda:\n';
                        for (var h in _portfolioHoldings) {
                          String qtyStr = h['quantity'] % 1 == 0 ? h['quantity'].toInt().toString() : h['quantity'].toStringAsFixed(2);
                          String ratio = h['isWhole'] ? '90/10' : '70/30';
                          breakdown += '• ${h['symbol']}: $qtyStr unit ($ratio)\n';
                        }
                        
                        final estProfit = _totalOwnedCows * 4250000;
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewsDetailPage(news: {
                              'title': 'Analisis Proyeksi ROI Terpersonalisasi',
                              'source': 'Analis InvestCow',
                              'logo': 'A',
                              'logoColor': '#4CAF50',
                              'date': 'Target 2026',
                              'time': 'Proyeksi',
                              'content': 'Berdasarkan portofolio aktif Anda:\n\n$breakdown\n'
                                  '• Total Estimasi Capital Gain: ${_formatCurrency(estProfit.toInt())}\n'
                                  '• Proyeksi ROI Tahunan: 18.5% - 22.1%\n'
                                  '• Estimasi Harga Jual Target: ${_formatCurrency((_totalInvestmentValue * 1.2).toInt())}\n\n'
                                  'Aturan Kepemilikan Unit (Contoh 1.73 Unit):\n'
                                  'Jika Anda membeli atau menjual 1.73 unit, maka SELURUH jumlah tersebut (termasuk desimalnya) dianggap sebagai Kepemilikan Utuh. '
                                  'Artinya, rasio bagi hasil yang berlaku adalah 90% Investor / 10% Peternak untuk total 1.73 unit tersebut.\n\n'
                                  'Bonus Ratio 90/10 berlaku otomatis selama jumlah transaksi Anda ≥ 1.0 unit.',
                            }),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 32),
                    const Text('Wawasan Peternakan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildKnowledgeCard(
                      'Dasar-dasar Peternakan Sapi',
                      'Kuasai manajemen pakan, sanitasi, dan nutrisi untuk pertumbuhan optimal.',
                      icon: Icons.school_outlined,
                      color: Colors.blueGrey,
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
                              'content': 'Peternakan sapi modern tidak hanya sekadar memberi makan, tetapi melibatkan manajemen presisi untuk hasil optimal.\n\n1. Pemilihan Bibit (Breeding): Memilih sapi dengan genetik unggul (seperti Brahman, Limousin, atau Simental) sangat berpengaruh pada Average Daily Gain (ADG).\n\n2. Manajemen Kandang: Sirkulasi udara (ventilation) dan kebersihan kandang mencegah stres pada sapi yang dapat menurunkan nafsu makan dan menghambat pertumbuhan.\n\n3. Nutrisi Seimbang: Perpaduan antara serat (rumput/silase) dan konsentrat (nutrisi padat) sangat krusial. InvestCow menggunakan formula khusus Dokter Hewan.\n\n4. Monitoring Digital: Penggunaan CCTV dan sensor IoT membantu memantau kesehatan sapi secara real-time tanpa mengganggu aktivitas alami mereka di kandang.',
                            }),
                          ),
                        );
                      },
                    ),
                    _buildKnowledgeCard(
                      'Faktor Harga Sapi',
                      'Pelajari variabel penentu harga pasar dari bobot hingga tren musiman.',
                      icon: Icons.monetization_on_outlined,
                      color: Colors.redAccent,
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
                              'content': 'Harga sapi di pasar modal peternakan dipengaruhi oleh berbagai variabel dinamis yang saling terkait:\n\n1. Berat Badan & Kondisi Fisik: Bobot akhir adalah faktor utama. Sapi yang masuk fase "fattening" sempurna dengan konformasi otot yang baik memiliki nilai jual jauh lebih tinggi.\n\n2. Hari Besar Keagamaan: Menjelang Hari Raya Idul Adha dan Idul Fitri, harga sapi dapat melonjak signifikan (20-40%) karena lonjakan permintaan nasional yang masif.\n\n3. Biaya Input Produksi: Kenaikan harga jagung, kedelai, atau logistik pengiriman antar pulau berpengaruh pada harga dasar sapi di pasar lokal.\n\n4. Tren Sentimen Pasar: Ketersediaan stok di feedlot besar dan kebijakan impor sapi bakalan juga turut menentukan stabilitas harga di tingkat ritel dan industri daging.',
                            }),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news) {
    final colorStr = news['logoColor']?.toString() ?? '#2196F3';
    final Color logoColor = Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewsDetailPage(news: news)),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _softGrey),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: logoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  news['logo'] ?? 'N',
                  style: TextStyle(color: logoColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${news['time']} · ${news['date']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(width: 8),
                      Text('· ${news['source']}', style: TextStyle(color: logoColor, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    news['title'],
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selengkapnya...',
                    style: TextStyle(color: _accentBlue, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKnowledgeCard(String title, String content, {IconData? icon, Color? color, VoidCallback? onTap}) {
    final themeColor = color ?? Colors.blue;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: themeColor.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon ?? Icons.book_outlined, color: themeColor, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content,
                      style: TextStyle(fontSize: 13, height: 1.5, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Pelajari Lanjut', style: TextStyle(color: themeColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 14, color: themeColor),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  Widget _buildMarketStat(String label, String value, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartInsight(String title, String description, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blue[300], size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showSentimentDetails() {
    _showInsightDetail(
      'Analisis Sentimen Pasar',
      'Sentimen saat ini berada di zona "Positif" yang digerakkan oleh tingginya volume akumulasi investor pada kuartal ini. Indikator teknikal menunjukkan kekuatan beli yang dominan di pasar seluruh jenis sapi.',
      'RSI saat ini berada di level 58 (Netral-Positif). Area ini merupakan zona aman untuk melakukan "Top Up" atau penambahan unit investasi karena belum mencapai area jenuh beli (overbought).'
    );
  }

  void _showVolatilityDetails() {
    _showInsightDetail(
      'Analisis Volatilitas',
      'Tingkat volatilitas dikategorikan "Stabil". Meskipun Anda melihat pergerakan harga 10 detik sekali (live), deviasi harganya masih dalam batas wajar (+/- 0.05%), sehingga risiko pergerakan harga liar sangat rendah.',
      'Gunakan kondisi stabil ini untuk melakukan investasi jangka panjang. Pasar yang stabil biasanya merupakan fondasi yang kuat sebelum terjadi lonjakan harga (breakout) di masa depan.'
    );
  }

  void _showConfidenceDetails() {
    _showInsightDetail(
      'Skor Kepercayaan Sistem',
      'Skor 92% dihitung berdasarkan akurasi data dari 12 kemitraan peternakan aktif, kecepatan sinkronisasi data IoT di kandang, dan verifikasi fisik yang dilakukan oleh tim auditor InvestCow setiap bulannya.',
      'Skor kepercayaan tinggi menjamin bahwa harga yang Anda lihat di dashboard adalah representasi nyata dari kondisi aset fisik sapi Anda di lapangan.'
    );
  }

  void _showMarketTechnicalDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Text('Detail Analisis Pasar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Informasi mendalam mengenai pergerakan harga hari ini.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              _buildDetailRow('Status Sesi', 'Accumulation', Colors.blue),
              _buildDetailRow('Volume Perdagangan', 'Tinggi (Rata-rata di atas 120%)', Colors.green),
              _buildDetailRow('Korelasi Pakan', 'Stabil (Dampak minimal)', Colors.grey),
              const SizedBox(height: 32),
              const Text('Mengapa harga live terkadang merah?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Fluktuasi merah (-0.01%) pada harga live adalah pergerakan mikro (random walk) pasar setiap 10 detik. Hal ini sangat wajar dalam perdagangan aktif dan tidak mengubah tren positif jangka panjang (+12.5% per bulan) yang didukung oleh analisis sentimen di atas.',
                style: TextStyle(color: Colors.black54, height: 1.6),
              ),
              const SizedBox(height: 24),
              const Text('Indikator Teknikal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildInsightPoint('RSI (Relative Strength Index)', 'Berada di level 58, menunjukkan pasar masih memiliki ruang untuk penguatan sebelum mencapai area jenuh beli.'),
              _buildInsightPoint('Moving Average', 'Harga saat ini bergerak di atas MA-20, mengonfirmasi tren jangka pendek yang masih sangat sehat.'),
            ],
          ),
        ),
      ),
    );
  }

  void _showInsightDetail(String title, String content, String advice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 20),
              const Text('Analisis Mendalam:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(content, style: const TextStyle(color: Colors.black87, height: 1.6)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tips_and_updates, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('Saran untuk Anda:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(advice, style: TextStyle(color: Colors.blue[900], fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailedInsights() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Text('Wawasan Strategis Investor', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              _buildInsightPoint('Diversifikasi Aset', 'Sangat disarankan untuk membagi portofolio antara Sapi Madura (stabilitas) dan Sapi Brahman (pertumbuhan tinggi).'),
              const SizedBox(height: 24),
              _buildInsightPoint('Manajemen Risiko', 'Gunakan modal dingin. Meskipun harga ternak cenderung naik secara historis, fluktuasi jangka pendek tetap ada.'),
              const SizedBox(height: 24),
              _buildInsightPoint('Faktor Musiman', 'Menjelang Idul Adha dan Idul Fitri adalah periode emas dimana harga sapi biasanya mencapai puncak tertinggi tahunan.'),
              const SizedBox(height: 24),
              _buildInsightPoint('Siklus Pertumbuhan (Penting!)', 'Investasi sapi adalah aset biologis. Keuntungan maksimal (ROI 12.5%+) didapatkan setelah siklus penggemukan selesai (biasanya 4-6 bulan). Di minggu pertama, nilai mungkin terlihat fluktuatif karena selisih harga jual/beli pakan dan pasar.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showRiskProtectionDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Icon(Icons.security, color: Colors.blue, size: 28),
                  SizedBox(width: 12),
                  Text('Perlindungan InvestCow', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              _buildRiskPoint(
                '1. Bagaimana jika sapi sakit?',
                'InvestCow bekerjasama dengan tim Medis Veteriner (Dokter Hewan) yang standby di setiap mitra kandang. Seluruh biaya pengobatan dan vitamin rutin sudah masuk dalam dana operasional yang dikelola peternak, sehingga tidak ada biaya tambahan bagi investor.',
                Icons.medical_services_outlined,
              ),
              const SizedBox(height: 20),
              _buildRiskPoint(
                '2. Bagaimana jika sapi mati?',
                'Mitigasi utama kami adalah Asuransi Ternak (Livestock Insurance). Jika terjadi kematian akibat penyakit atau kecelakaan medis (bukan kelalaian), dana asuransi atau cadangan risiko InvestCow akan digunakan untuk mengganti modal bibit baru atau pengembalian modal sesuai akad perlindungan.',
                Icons.heart_broken_outlined,
              ),
              const SizedBox(height: 20),
              _buildRiskPoint(
                '3. Bagaimana jika harga pasar turun?',
                'Keuntungan utama berasal dari "Penambahan Berat Badan" (ADG). Meskipun harga pasar per kilogram turun tipis, selama sapi Anda bertumbuh subur dan gemuk, nilai total aset Anda (berat x harga) akan tetap di atas modal awal saat panen.',
                Icons.trending_down_outlined,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green[100]!)),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Kepercayaan Anda adalah prioritas kami. Semua aset fisik sapi dilakukan audit rutin setiap bulan.',
                        style: TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskPoint(String title, String desc, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue[700], size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(desc, style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightPoint(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 8),
        Text(desc, style: const TextStyle(color: Colors.black54, height: 1.5)),
      ],
    );
  }

  Widget _buildPriceScroll({int? limit}) {
    final displayItems = limit == null ? _cowPrices : _cowPrices.take(limit).toList();
    
    // Grid Layout for "Harga Sapi" Tab (Matching Image 2 card style but in Grid)
    if (limit == null) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        itemCount: displayItems.length,
        itemBuilder: (context, index) {
          final item = displayItems[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CctvPage(filter: item['name'].toString().split(' ').last)),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[100]!),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Expanded(
                    flex: 5,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            item['image'].startsWith('http') 
                              ? item['image'] 
                              : '${_apiClient.baseUrl}${item['image']}',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.pets, color: Colors.grey),
                            ),
                          ),
                        ),
                        // Gradient Overlay for text readability
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0),
                              ],
                              stops: const [0.0, 0.4],
                            ),
                          ),
                        ),
                        // Video Icon overlay
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.videocam, size: 14, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'], 
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatCurrency(item['price'] as num),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3142)),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['change'],
                              style: TextStyle(
                                color: item['up'] ? _accentGreen : _accentRed,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height: 15,
                              width: 50,
                              child: CustomPaint(
                                painter: SparklinePainter(item['trend'] as List<double>, item['up'] ? _accentGreen : _accentRed),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // Horizontal Layout for Dashboard
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
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CctvPage(filter: item['name'].toString().split(' ').last)),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
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
                      _formatCurrency(item['price'] as num),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['change'],
                          style: TextStyle(
                            color: item['up'] ? _accentGreen : _accentRed,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.videocam_outlined, size: 14, color: Colors.blue),
                      ],
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
              ),
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
