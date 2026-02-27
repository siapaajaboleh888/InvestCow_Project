import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'news_detail_page.dart';

class KesehatanDetailPage extends StatefulWidget {
  final Map<String, dynamic> record;

  const KesehatanDetailPage({super.key, required this.record});

  @override
  State<KesehatanDetailPage> createState() => _KesehatanDetailPageState();
}

class _KesehatanDetailPageState extends State<KesehatanDetailPage> {
  List<Map<String, dynamic>> _myRequests = [];
  bool _loadingRequests = true;

  @override
  void initState() {
    super.initState();
    _fetchMyRequests();
  }

  Future<void> _fetchMyRequests() async {
    try {
      final client = ApiClient();
      final auth = AuthService();
      final token = await auth.getToken();
      final uri = client.uri('/portfolios/health-requests');
      final res = await http.get(uri, headers: client.jsonHeaders(token: token));
      
      if (res.statusCode == 200) {
        final data = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
        setState(() {
          _myRequests = data.where((r) => r['nama'] == widget.record['nama']).toList();
          _loadingRequests = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching requests: $e');
      setState(() => _loadingRequests = false);
    }
  }

  Future<void> _submitRequest(String type, String desc) async {
    try {
      final client = ApiClient();
      final auth = AuthService();
      final token = await auth.getToken();
      final uri = client.uri('/portfolios/health-requests');
      
      final res = await http.post(
        uri,
        headers: client.jsonHeaders(token: token),
        body: jsonEncode({
          'cow_name': widget.record['nama'],
          'request_type': type,
          'description': desc,
        }),
      );

      if (res.statusCode == 201) {
        _showSuccessSnippet(type);
        _fetchMyRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim permintaan'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteRequest(int id) async {
    try {
      final client = ApiClient();
      final auth = AuthService();
      final token = await auth.getToken();
      final uri = client.uri('/portfolios/health-requests/$id');
      
      final res = await http.delete(uri, headers: client.jsonHeaders(token: token));

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permintaan berhasil dihapus'), backgroundColor: Colors.green),
        );
        _fetchMyRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus permintaan'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.record['status'] as String;
    final score = widget.record['score'] as int;
    final name = widget.record['nama'] as String;
    final qty = widget.record['quantity'] as int;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.red[600],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.red[400]!, Colors.red[700]!],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      Icons.health_and_safety,
                      size: 180,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$qty Ekor Sapi',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(status, score),
                  
                  if (_myRequests.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Status Permintaan Terakhir',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                    ),
                    const SizedBox(height: 16),
                    ..._myRequests.map((req) => _buildRequestStatusCard(req)).toList(),
                  ],

                  const SizedBox(height: 24),
                  const Text(
                    'Program Kesehatan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                  ),
                  const SizedBox(height: 16),
                  _buildProgramGrid(),
                  const SizedBox(height: 24),
                  const Text(
                    'Riwayat Penanganan Rutin',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                  ),
                  const SizedBox(height: 16),
                  _buildHistoryItem(
                    'Vaksinasi Anthrax',
                    '20 Jan 2026',
                    Icons.vaccines,
                    Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewsDetailPage(news: {
                            'title': 'Vaksinasi Anthrax Rutin - Jan 2026',
                            'source': 'Medis InvestCow',
                            'logo': 'V',
                            'logoColor': '#2196F3',
                            'date': '20 Jan 2026',
                            'time': 'Selesai',
                            'content': 'Vaksinasi Anthrax adalah prosedur wajib tahunan untuk menjaga kekebalan sapi terhadap bakteri Bacillus anthracis.\n\nDetail Penanganan:\n• Lokasi: Kandang Mitra A-1\n• Petugas: drh. Bambang S.\n• Hasil: Sapi menunjukkan reaksi normal, nafsu makan stabil.\n• Masa Perlindungan: 12 Bulan ke depan.',
                          }),
                        ),
                      );
                    },
                  ),
                  _buildHistoryItem(
                    'Pemberian Vitamin B12',
                    '15 Jan 2026',
                    Icons.medication,
                    Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewsDetailPage(news: {
                            'title': 'Booster Vitamin B12 & Metabolisme',
                            'source': 'Nutrisi InvestCow',
                            'logo': 'B',
                            'logoColor': '#FF9800',
                            'date': '15 Jan 2026',
                            'time': 'Selesai',
                            'content': 'Pemberian injeksi B-Complex (B12) ditujukan untuk memaksimalkan metabolisme energi dan meningkatkan efisiensi pakan.\n\nManfaat:\n1. Meningkatkan nafsu makan sapi secara signifikan.\n2. Mendukung pembentukan sel darah merah agar transportasi nutrisi ke otot lebih lancar.\n3. Mempercepat target bobot harian (ADG).',
                          }),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tips & Informasi',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                  ),
                  const SizedBox(height: 16),
                  _buildTipCard(
                    'Kenapa Beri Vitamin?',
                    'Vitamin membantu sapi tetap bugar di cuaca ekstrem dan menjaga nafsu makan tetap stabil.',
                    Icons.lightbulb_outline,
                    Colors.amber,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewsDetailPage(news: {
                            'title': 'Pentingnya Vitamin pada Fase Penggemukan',
                            'source': 'Edukasi InvestCow',
                            'logo': 'E',
                            'logoColor': '#FFC107',
                            'date': 'Tips Sehat',
                            'time': 'Edukasi',
                            'content': 'Vitamin bukan sekadar pelengkap, melainkan katalisator pertumbuhan.\n\nDi InvestCow, kami menggunakan premix vitamin khusus yang membantu sapi beradaptasi dengan heat stress (stres panas) di Indonesia.\n\nTips:\n- Vitamin A untuk kesehatan mukosa.\n- Vitamin E untuk antioksidan sel.\n- Pastikan air minum selalu tersedia setelah pemberian vitamin oral.',
                          }),
                        ),
                      );
                    },
                  ),
                  _buildTipCard(
                    'Tanda Sapi Sehat',
                    'Mata cerah, kulit mengkilap, dan aktif bergerak adalah tanda utama sapi Anda sehat.',
                    Icons.pets,
                    Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewsDetailPage(news: {
                            'title': 'Cara Mudah Cek Kesehatan Sapi',
                            'source': 'Kesehatan InvestCow',
                            'logo': 'K',
                            'logoColor': '#4CAF50',
                            'date': 'Tips Sehat',
                            'time': 'Edukasi',
                            'content': 'Investor dapat melihat kesehatan sapinya secara fisik melalui CCTV atau foto terbaru:\n\n1. Mata: Harus jernih, tidak sayu atau berair.\n2. Kulit: Rambut mengkilap (tidak kusam) dan kulit elastis.\n3. Perilaku: Sapi aktif berdiri saat pakan datang dan melakukan gumul (memamah biak) saat istirahat.',
                          }),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: () {
            _showActionSheet(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
          ),
          child: const Text('Lakukan Penanganan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildRequestStatusCard(Map<String, dynamic> req) {
    final status = req['status'] as String;
    final isAdminNote = req['admin_note'] != null && req['admin_note'].toString().isNotEmpty;
    
    Color statusColor = Colors.orange;
    String statusText = 'Diproses';
    
    if (status == 'confirmed') {
      statusColor = Colors.blue;
      statusText = 'Dikonfirmasi';
    } else if (status == 'completed') {
      statusColor = Colors.green;
      statusText = 'Selesai';
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusText = 'Ditolak';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      req['request_type'],
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor.darker(0.2)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                if (status != 'completed') ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showDeleteConfirmation(req['id']),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_forever, color: Colors.red, size: 18),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (req['description'] != null)
                  Text(
                    req['description'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                if (isAdminNote) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.admin_panel_settings, size: 16, color: Colors.blue),
                            const SizedBox(width: 6),
                            Text(
                              'RESPONS ADMIN',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue[800], letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          req['admin_note'],
                          style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
                if (req['handover_date'] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 6),
                      Text(
                        'Jadwal Penanganan:',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(req['handover_date']),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return date.toString();
    }
  }

  Widget _buildTipCard(String title, String desc, IconData icon, Color color, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color.darker(0.3))),
                    const SizedBox(height: 4),
                    Text(desc, style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status, int score) {
    final isHealthy = status == 'Sehat';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isHealthy ? Colors.green[400]! : Colors.orange[400]!,
                  ),
                ),
              ),
              Text(
                '$score%',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHealthy ? 'Kondisi Optimal' : 'Perlu Perhatian',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isHealthy ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isHealthy 
                    ? 'Sapi dalam kondisi sangat sehat dan produktif.'
                    : 'Beberapa sapi memerlukan vitamin tambahan.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildProgramItem(
          'Vitamin',
          'Tiap 14 Hari',
          Icons.health_and_safety,
          Colors.orange[100]!,
          Colors.orange[700]!,
        ),
        _buildProgramItem(
          'Vaksin',
          '3 Bulan Sekali',
          Icons.vaccines,
          Colors.blue[100]!,
          Colors.blue[700]!,
        ),
        _buildProgramItem(
          'Nutrisi',
          'Setiap Hari',
          Icons.restaurant,
          Colors.green[100]!,
          Colors.green[700]!,
        ),
        _buildProgramItem(
          'Cek Fisik',
          'Tiap 7 Hari',
          Icons.visibility,
          Colors.purple[100]!,
          Colors.purple[700]!,
        ),
      ],
    );
  }

  Widget _buildProgramItem(String title, String schedule, IconData icon, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bg),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: text, size: 32),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: text, fontSize: 16)),
          const SizedBox(height: 4),
          Text(schedule, style: TextStyle(color: text.withOpacity(0.8), fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String title, String date, IconData icon, Color color, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Penanganan',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih jenis perawatan yang ingin diberikan pada sapi Anda.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              _buildActionItem(
                context,
                'Pemberian Vitamin',
                'Vitamin booster sesuai jadwal.',
                Icons.medication_liquid,
                Colors.orange,
              ),
              _buildActionItem(
                context,
                'Minuman Bergizi (Nutrisi)',
                'Suplemen cair pembentuk otot.',
                Icons.local_drink,
                Colors.blue,
              ),
              _buildActionItem(
                context,
                'Cek Kesehatan Rutin',
                'Pemeriksaan tim medis profesional.',
                Icons.health_and_safety,
                Colors.green,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, String title, String desc, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _submitRequest(title, desc);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Permintaan?'),
        content: const Text('Apakah Anda yakin ingin menghapus permintaan penanganan ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRequest(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnippet(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Permintaan $action sudah terkirim ke tim admin.'),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darker(double factor) {
    assert(factor >= 0 && factor <= 1);
    return Color.fromARGB(
      alpha,
      (red * (1 - factor)).round(),
      (green * (1 - factor)).round(),
      (blue * (1 - factor)).round(),
    );
  }
}
