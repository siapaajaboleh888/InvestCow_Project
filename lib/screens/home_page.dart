import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';
import 'menu_page.dart';
import 'news_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiClient _apiClient = ApiClient();
  List<Map<String, dynamic>> _newsItems = [];
  bool _isLoadingNews = true;
  Timer? _refreshTimer;
  String _activeTab = 'Ikhtisar';

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
    _startSimulation();
    
    // Auto refresh every 3 minutes for news
    _refreshTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      _fetchNews();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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
            if (_activeTab == 'Ikhtisar' || _activeTab == 'Harga Sapi') ...[
              // Cow Price Cards (Visible in Ikhtisar too as requested)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _cowPrices.length,
                  itemBuilder: (context, index) {
                    final item = _cowPrices[index];
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
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
                          Row(
                            children: [
                              Text(
                                item['change'],
                                style: TextStyle(
                                  color: item['up'] ? _accentGreen : _accentRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                    );
                  },
                ),
              ),
            ],

            if (_activeTab == 'Pakan')
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Info Pakan Berkualitas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildKnowledgeCard('Konsentrat Protein Tinggi', 'Pakan tambahan untuk mempercepat pertumbuhan bobot harian hingga 1.2kg/hari.'),
                    _buildKnowledgeCard('Hijauan Segar', 'Rumput gajah dan tebon jagung pilihan untuk menjaga pencernaan sapi tetap sehat.'),
                  ],
                ),
              ),

            if (_activeTab == 'Edukasi')
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Edukasi Investasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildKnowledgeCard('Manajemen Risiko', 'Cara mengidentifikasi kesehatan sapi dan perlindungan asuransi ternak.'),
                    _buildKnowledgeCard('Hitung ROI', 'Simulasi keuntungan dari penggemukan sapi bakalan durasi 4-6 bulan.'),
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
                    'Peternakan sapi adalah usaha budidaya ternak sapi untuk tujuan daging, susu, ataupun pembibitan. Hal penting yang perlu diperhatikan antara lain kualitas pakan, kebersihan kandang, dan kesehatan ternak.',
                  ),
                  _buildKnowledgeCard(
                    '2. Faktor Harga Sapi',
                    'Bobot badan, usia sapi, jenis genetik, dan kondisi tubuh menentukan harga pasar. Menjelang hari besar seperti Idul Adha, harga biasanya mengalami kenaikan signifikan.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKnowledgeCard(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
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
