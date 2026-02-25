import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';
import '../services/auth_service.dart';

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

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _auth.getToken();
      
      // 1. Fetch products to get health_score
      final prodUri = _client.uri('/admin/products-public');
      final prodRes = await http.get(prodUri, headers: _client.jsonHeaders(token: token));
      if (prodRes.statusCode != 200) throw Exception('Failed to load products');
      final products = (jsonDecode(prodRes.body) as List).cast<Map<String, dynamic>>();

      // 2. Fetch portfolio summary to see what the user owns
      final summaryUri = _client.uri('/transactions/portfolio-summary');
      final summaryRes = await http.get(summaryUri, headers: _client.jsonHeaders(token: token));
      if (summaryRes.statusCode != 200) throw Exception('Failed to load portfolio');
      final summaryData = (jsonDecode(summaryRes.body) as List).cast<Map<String, dynamic>>();

      // Pre-map ownership for quick lookup by name or ticker
      Map<String, double> ownership = {};
      for (var item in summaryData) {
        ownership[item['symbol'].toString()] = double.tryParse(item['total_quantity'].toString()) ?? 0.0;
      }

      // 3. Match owned cows to product health data
      final List<Map<String, dynamic>> newRecords = [];
      for (var prod in products) {
        final name = prod['name'].toString();
        final ticker = prod['ticker_code'].toString();
        
        // Sum ownership from both possible symbols
        final qty = (ownership[name] ?? 0.0) + (ownership[ticker] ?? 0.0);
        
        if (qty > 0) {
          final healthScore = prod['health_score'] as int? ?? 100;
          newRecords.add({
            'nama': name,
            'status': healthScore >= 90 ? 'Sehat' : 'Perawatan',
            'score': healthScore,
            'quantity': qty.toInt(),
            'next': DateTime.now().add(const Duration(days: 14)), // Simulated next vaccine
          });
        }
      }

      if (mounted) {
        setState(() {
          _records = newRecords;
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
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.red[400],
        foregroundColor: Colors.white,
        title: const Text(
          'Kesehatan Sapi',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.red[400]!, Colors.red[600]!],
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.medical_services,
                          color: Colors.white,
                          size: 60,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Monitoring Kesehatan',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_loading)
                          const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2))
                        else
                          Text(
                            'Sehat: $sehatCount Kategori • Perawatan: $perawatanCount Kategori',
                            style: const TextStyle(fontSize: 16, color: Colors.white70),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ))
                else if (_error != null)
                  Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                else if (_records.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Center(
                      child: Text('Belum ada sapi di portofolio Anda.', style: TextStyle(color: Colors.grey[700])),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final r = _records[index];
                      final status = r['status'] as String;
                      final score = r['score'] as int;
                      
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: status == 'Sehat' ? Colors.green[100] : Colors.orange[100],
                            child: Icon(
                              status == 'Sehat' ? Icons.health_and_safety : Icons.warning_amber,
                              color: status == 'Sehat' ? Colors.green[700] : Colors.orange[700],
                            ),
                          ),
                          title: Text(
                            '${r['nama']} (${r['quantity']} ekor)', 
                            style: const TextStyle(fontWeight: FontWeight.bold)
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Status: $status (Score: $score)'),
                              const SizedBox(height: 2),
                              Text('Vaksin berikutnya: ' + (
                                  r['next'] == null ? '-' : '${(r['next'] as DateTime).day}/${(r['next'] as DateTime).month}/${(r['next'] as DateTime).year}'
                              )),
                            ],
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                          ),
                          onTap: () {
                            // Detail kesehatan per jenis
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
