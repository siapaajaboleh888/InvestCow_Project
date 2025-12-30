import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<double> _getKasSaldo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('kas_saldo') ?? 0;
  }

  Future<void> _catatPengeluaranKas({
    required double total,
    required String productName,
    required double quantity,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final saldoLama = prefs.getDouble('kas_saldo') ?? 0;
    final saldoBaru = saldoLama - total;

    final raw = prefs.getString('kas_riwayat');
    List<dynamic> list = [];
    if (raw != null && raw.isNotEmpty) {
      list = jsonDecode(raw) as List<dynamic>;
    }

    list.insert(0, {
      'jenis': 'Pengeluaran',
      'nominal': total,
      'metode': 'Pembelian sapi $productName ($quantity ekor)',
      'tanggal': DateTime.now().toIso8601String(),
      'status': 'Berhasil',
    });

    await prefs.setDouble('kas_saldo', saldoBaru);
    await prefs.setString('kas_riwayat', jsonEncode(list));
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
                      final quotaRaw = p['quota'];
                      final quota = (quotaRaw is num)
                          ? quotaRaw.toDouble()
                          : double.tryParse(quotaRaw?.toString() ?? '0') ?? 0;
                      final isSoldOut = quota <= 0;
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
                                          'Investasi sapi "$name"\nHarga: Rp $priceText\nKuota: ${quota.toStringAsFixed(0)} ekor';
                                      Share.share(text, subject: 'Promo Investasi Sapi');
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                isSoldOut
                                    ? 'Kuota habis / sudah terjual'
                                    : 'Kuota tersedia: ${quota.toStringAsFixed(0)} ekor',
                                style: TextStyle(
                                  color: isSoldOut ? Colors.red[700] : Colors.black87,
                                  fontWeight: isSoldOut ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          trailing: isSoldOut
                              ? const Text(
                                  'Habis',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : ElevatedButton(
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
                                        const SizedBox(height: 4),
                                        Builder(
                                          builder: (context) {
                                            final qtyPreview =
                                                double.tryParse(qtyController.text.trim()) ?? 1;
                                            final totalPreview = (qtyPreview * price)
                                                .toStringAsFixed(0)
                                                .replaceAllMapped(
                                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                                  (m) => '${m[1]}.',
                                                );
                                            return Text('Perkiraan total: Rp $totalPreview');
                                          },
                                        ),
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

                              final totalHarga = price * qty;
                              final saldoKas = await _getKasSaldo();
                              if (saldoKas < totalHarga) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Saldo kas tidak cukup untuk membeli $qty ekor $name.'),
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

                                await _catatPengeluaranKas(
                                  total: totalHarga,
                                  productName: name,
                                  quantity: qty,
                                );

                                setState(() {
                                  final currentQuota = quota;
                                  var newQuota = currentQuota - qty;
                                  if (newQuota < 0) newQuota = 0;
                                  _products[index]['quota'] = newQuota;
                                });

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
