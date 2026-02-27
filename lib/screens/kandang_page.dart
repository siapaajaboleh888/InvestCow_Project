import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'detail_kandang_page.dart';

class KandangPage extends StatefulWidget {
  const KandangPage({super.key});

  @override
  State<KandangPage> createState() => _KandangPageState();
}

class _KandangPageState extends State<KandangPage> {
  final _client = ApiClient();
  final _auth = AuthService();
  
  List<Map<String, dynamic>> _barns = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String _occFilter = 'Semua';

  double get totalCows => _barns.fold(0.0, (p, e) => p + (double.tryParse(e['occupied'].toString()) ?? 0.0));
  int get totalBarns => _barns.where((e) => (double.tryParse(e['occupied'].toString()) ?? 0.0) >= 0.01).length;

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
      
      // 1. Fetch products (types of cattle available in market)
      final prodUri = _client.uri('/admin/products-public');
      final prodRes = await http.get(prodUri, headers: _client.jsonHeaders(token: token));
      
      if (prodRes.statusCode != 200) {
        throw Exception('Gagal memuat jenis sapi (${prodRes.statusCode})');
      }
      
      final products = (jsonDecode(prodRes.body) as List).cast<Map<String, dynamic>>();

      // 2. Fetch portfolio summary (user's cows)
      final summaryUri = _client.uri('/transactions/portfolio-summary');
      final summaryRes = await http.get(summaryUri, headers: _client.jsonHeaders(token: token));
      
      Map<String, double> ownership = {};
      if (summaryRes.statusCode == 200) {
        final summaryData = (jsonDecode(summaryRes.body) as List).cast<Map<String, dynamic>>();
        for (var item in summaryData) {
          ownership[item['symbol'].toString()] = double.tryParse(item['total_quantity'].toString()) ?? 0.0;
        }
      }

      // 3. Map to barns
      final List<Map<String, dynamic>> newBarns = products.map((p) {
        final name = p['name'].toString();
        final ticker = p['ticker_code'].toString();
        
        // Sum ownership from both possible symbols (Name or Ticker)
        final occupied = (ownership[name] ?? 0.0) + (ownership[ticker] ?? 0.0);
        
        return {
          'name': name,
          'capacity': 100, // Management capacity for visual reference
          'occupied': occupied,
          'ticker': ticker,
          'price': p['price'],
          'weight': p['current_weight'],
          'growth': p['daily_growth_rate'],
          'cctv_url': p['cctv_url'],
          'image_url': p['image_url'],
          'health': p['health_score'] ?? 100,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _barns = newBarns;
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
        backgroundColor: Colors.brown[400],
        foregroundColor: Colors.white,
        title: const Text(
          'Manajemen Kandang',
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
                        colors: [Colors.brown[400]!, Colors.brown[600]!],
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.pets, color: Colors.white, size: 60),
                        const SizedBox(height: 12),
                        const Text('Total Sapi Dimiliki', style: TextStyle(fontSize: 20, color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text(
                          totalCows % 1 == 0 ? totalCows.toInt().toString() : totalCows.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text('Kategori Kandang: $totalBarns', style: const TextStyle(fontSize: 16, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Daftar Kandang Per Jenis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                
                // Search & Filter
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari jenis sapi...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                if (_loading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ))
                else if (_error != null)
                  Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                else if (_barns.where((b) => (double.tryParse(b['occupied'].toString()) ?? 0.0) >= 0.01).isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Center(
                      child: Text('Belum ada sapi yang Anda miliki.', style: TextStyle(color: Colors.grey[700])),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _barns.where((b) {
                      final name = (b['name'] as String).toLowerCase();
                      final occValue = double.tryParse(b['occupied'].toString()) ?? 0.0;
                      return occValue >= 0.01 && (_search.isEmpty || name.contains(_search));
                    }).length,
                    itemBuilder: (context, index) {
                      final filtered = _barns.where((b) {
                        final name = (b['name'] as String).toLowerCase();
                        final occValue = double.tryParse(b['occupied'].toString()) ?? 0.0;
                        return occValue >= 0.01 && (_search.isEmpty || name.contains(_search));
                      }).toList();
                      
                      final b = filtered[index];
                      final cap = b['capacity'] as int;
                      final occ = double.tryParse(b['occupied'].toString()) ?? 0.0;
                      final ratio = cap == 0 ? 0.0 : (occ / cap).clamp(0.0, 1.0);
                      
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.brown[100],
                            radius: 30,
                            child: Icon(Icons.home, color: Colors.brown[700], size: 30),
                          ),
                          title: Text(
                            b['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Kepemilikan: ${occ % 1 == 0 ? occ.toInt() : occ.toStringAsFixed(2)} ekor'),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: ratio > 0 ? ratio : 0.02, // Small sliver if 0 but for UI
                                backgroundColor: Colors.grey[300],
                                color: occ > 0 ? Colors.brown[400] : Colors.grey[400],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kode: ${b['ticker']}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailKandangPage(barn: b),
                              ),
                            );
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
