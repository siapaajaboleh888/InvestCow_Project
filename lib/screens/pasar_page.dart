import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../services/api_client.dart';
import '../services/portfolios_service.dart';
import '../services/transactions_service.dart';

class PasarPage extends StatefulWidget {
  const PasarPage({super.key});

  @override
  State<PasarPage> createState() => _PasarPageState();
}

class _PasarPageState extends State<PasarPage> {
  final _client = ApiClient();
  final _portfoliosService = PortfoliosService();
  final _transactionsService = TransactionsService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = _client.uri('/admin/products-public');
      final res = await http.get(uri, headers: _client.jsonHeaders());
      if (res.statusCode != 200) {
        throw Exception('Gagal memuat produk (${res.statusCode})');
      }
      final data = jsonDecode(res.body) as List;
      setState(() {
        _products = data.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
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
        backgroundColor: Colors.blue[400],
        foregroundColor: Colors.white,
        title: const Text(
          'Pasar Modal Sapi',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
        ),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
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
                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                      ),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.shopping_cart, color: Colors.white, size: 60),
                        SizedBox(height: 12),
                        Text(
                          'Pasar Modal Sapi',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Pilih paket investasi sapi yang tersedia',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sapi Tersedia',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Center(child: Padding(
                    padding: EdgeInsets.only(top: 32.0),
                    child: CircularProgressIndicator(),
                  ))
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 32.0),
                    child: Center(
                      child: Text(
                        'Gagal memuat produk:\n$_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                else if (_products.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 32.0),
                    child: Center(
                      child: Text(
                        'Belum ada produk yang ditawarkan.\nSilakan kembali lagi nanti.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final p = _products[index];
                      final name = p['name']?.toString() ?? 'Produk';
                      final price = double.tryParse(p['price'].toString()) ?? 0;
                      final quota = p['quota'];
                      final imageUrl = p['image_url']?.toString();

                      final priceText = price
                          .toStringAsFixed(0)
                          .replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (m) => '${m[1]}.',
                          );

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: imageUrl != null && imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.pets),
                                  ),
                                )
                              : CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  radius: 28,
                                  child: Icon(
                                    Icons.pets,
                                    color: Colors.blue[700],
                                  ),
                                ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Harga: Rp $priceText'),
                                  IconButton(
                                    icon: const Icon(Icons.share, size: 18),
                                    padding: const EdgeInsets.only(left: 4),
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      final text =
                                          'Investasi sapi "$name"\nHarga: Rp $priceText\nKuota: $quota ekor';
                                      Share.share(text, subject: 'Promo Investasi Sapi');
                                    },
                                  ),
                                ],
                              ),
                              Text('Kuota tersedia: $quota ekor'),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              final qtyController = TextEditingController(text: '1');
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    title: const Text('Konfirmasi Pembelian'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Produk: $name'),
                                        const SizedBox(height: 4),
                                        Text('Harga per ekor: Rp $priceText'),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: qtyController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Jumlah ekor',
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Transaksi akan dicatat ke portofolio sapi utama Anda.',
                                          style: TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        child: const Text('Konfirmasi'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirmed != true) return;

                              final qty = double.tryParse(qtyController.text.trim());
                              if (qty == null || qty <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Jumlah ekor tidak valid'),
                                  ),
                                );
                                return;
                              }

                              try {
                                final portfolio = await _portfoliosService.getOrCreateDefault();
                                final portfolioId = portfolio['id'] as int;

                                await _transactionsService.create(
                                  portfolioId: portfolioId,
                                  type: 'BUY',
                                  symbol: name,
                                  quantity: qty,
                                  price: price,
                                  occurredAt: DateTime.now(),
                                  note: 'Pembelian melalui Pasar Modal Sapi',
                                );

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Pembelian $qty ekor $name berhasil dicatat.'),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Gagal mencatat transaksi: ${e.toString()}'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[400],
                              foregroundColor: Colors.white,
                              minimumSize: const Size(72, 36),
                            ),
                            child: const Text('Beli'),
                          ),
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
