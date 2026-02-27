import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'kesehatan_detail_page.dart';

class KesehatanPage extends StatefulWidget {
  const KesehatanPage({super.key});

  @override
  State<KesehatanPage> createState() => _KesehatanPageState();
}

class _KesehatanPageState extends State<KesehatanPage> {
  final _client = ApiClient();
  final _auth = AuthService();

  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  String? _error;

  int get sehatCount => _records.where((e) => e['status'] == 'Sehat').length;
  int get perawatanCount => _records.where((e) => e['status'] != 'Sehat').length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<Map<String, dynamic>> _myRequests = [];

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _auth.getToken();
      
      // 1. Fetch products
      final prodUri = _client.uri('/admin/products-public');
      final prodRes = await http.get(prodUri, headers: _client.jsonHeaders(token: token));
      if (prodRes.statusCode != 200) throw Exception('Failed to load products');
      final products = (jsonDecode(prodRes.body) as List).cast<Map<String, dynamic>>();

      // 2. Fetch portfolio summary
      final summaryUri = _client.uri('/transactions/portfolio-summary');
      final summaryRes = await http.get(summaryUri, headers: _client.jsonHeaders(token: token));
      if (summaryRes.statusCode != 200) throw Exception('Failed to load portfolio');
      final summaryData = (jsonDecode(summaryRes.body) as List).cast<Map<String, dynamic>>();

      // 3. Fetch user health requests
      final reqUri = _client.uri('/portfolios/health-requests');
      final reqRes = await http.get(reqUri, headers: _client.jsonHeaders(token: token));
      List<Map<String, dynamic>> userRequests = [];
      if (reqRes.statusCode == 200) {
        userRequests = (jsonDecode(reqRes.body) as List).cast<Map<String, dynamic>>();
      }

      Map<String, double> ownership = {};
      for (var item in summaryData) {
        ownership[item['symbol'].toString()] = double.tryParse(item['total_quantity'].toString()) ?? 0.0;
      }

      final List<Map<String, dynamic>> newRecords = [];
      for (var prod in products) {
        final name = prod['name'].toString();
        final ticker = prod['ticker_code'].toString();
        final qty = (ownership[name] ?? 0.0) + (ownership[ticker] ?? 0.0);
        
        if (qty > 0) {
          final healthScore = prod['health_score'] as int? ?? 100;
          // Find if this cow has a pending or confirmed request
          final latestReq = userRequests.firstWhere(
            (r) => r['nama'] == name, 
            orElse: () => <String, dynamic>{}
          );

          newRecords.add({
            'nama': name,
            'status': healthScore >= 90 ? 'Sehat' : 'Perawatan',
            'score': healthScore,
            'quantity': qty.toInt(),
            'latest_request': latestReq.isNotEmpty ? latestReq : null,
            'next': DateTime.now().add(const Duration(days: 14)),
          });
        }
      }

      if (mounted) {
        setState(() {
          _records = newRecords;
          _myRequests = userRequests;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Kesehatan Sapi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _load,
              icon: Icon(Icons.refresh, color: Colors.red[400]),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernSummaryCard(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daftar Sapi Anda',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                    ),
                    Text(
                      '${_records.length} Jenis',
                      style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (_loading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ))
              else if (_error != null)
                Center(child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                ))
              else if (_records.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada sapi di portofolio Anda.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final r = _records[index];
                    return _buildCowHealthItem(r);
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSummaryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red[400]!, Colors.red[700]!],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Kesehatan',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Overall Sehat',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.health_and_safety, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSummaryStat('Sehat', sehatCount.toString(), Icons.check_circle_outline),
              Container(width: 1, height: 40, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 16)),
              _buildSummaryStat('Permintaan', _myRequests.length.toString(), Icons.assignment_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCowHealthItem(Map<String, dynamic> r) {
    final status = r['status'] as String;
    final score = r['score'] as int;
    final isHealthy = status == 'Sehat';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => KesehatanDetailPage(record: r),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isHealthy ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isHealthy ? Icons.verified_user : Icons.warning_rounded,
                    color: isHealthy ? Colors.green[600] : Colors.orange[600],
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['nama'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isHealthy ? Colors.green[100] : Colors.orange[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: isHealthy ? Colors.green[800] : Colors.orange[800],
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Score: $score%',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                          if (r['latest_request'] != null) ...[
                            const SizedBox(width: 8),
                            _buildSmallStatusBadge(r['latest_request']['status']),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(Icons.chevron_right, color: Colors.grey),
                    const SizedBox(height: 4),
                    Text(
                      '${r['quantity']} Ekor',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallStatusBadge(String status) {
    Color color = Colors.orange;
    String text = 'Diproses';
    if (status == 'confirmed') {
      color = Colors.blue;
      text = 'Dikonfirmasi';
    } else if (status == 'completed') {
      color = Colors.green;
      text = 'Selesai';
    } else if (status == 'rejected') {
      color = Colors.red;
      text = 'Ditolak';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

