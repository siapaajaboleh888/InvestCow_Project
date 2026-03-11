import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/portfolios_service.dart';
import '../services/transactions_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:intl/intl.dart';

class PasarPage extends StatefulWidget {
  const PasarPage({super.key});

  @override
  State<PasarPage> createState() => _PasarPageState();
}

class _PasarPageState extends State<PasarPage> {
  final _client = ApiClient();
  final _authService = AuthService();
  final _portfoliosService = PortfoliosService();
  final _transactionsService = TransactionsService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _products = [];
  double _userBalance = 0;
  IO.Socket? socket;
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _initSocket();
    _loadProducts();
  }

  void _initSocket() {
    socket = IO.io(_client.socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());

    socket!.on('product-updated', (data) {
      if (data != null && data is Map && mounted) {
        final updatedId = data['id'].toString();
        setState(() {
          int idx = _products.indexWhere((p) => p['id'].toString() == updatedId);
          if (idx != -1) {
            _products[idx] = {
              ..._products[idx],
              ...Map<String, dynamic>.from(data),
            };
          } else {
            _products.insert(0, Map<String, dynamic>.from(data));
          }
        });
      }
    });

    socket!.on('price-update-batch', (dataList) {
      if (dataList != null && dataList is List && mounted) {
        setState(() {
          for (var item in dataList) {
            final productId = item['productId']?.toString();
            int idx = _products.indexWhere((p) => p['id'].toString() == productId);
            if (idx != -1) {
              _products[idx]['price'] = item['newPrice'];
            }
          }
        });
      }
    });

    socket!.connect();
  }

  @override
  void dispose() {
    socket?.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _authService.getMe();
      final uri = _client.uri('/admin/products-public');
      final res = await http.get(uri, headers: _client.jsonHeaders());
      if (res.statusCode != 200) {
        throw Exception('Gagal memuat produk (${res.statusCode})');
      }
      final data = jsonDecode(res.body) as List;
      setState(() {
        _products = data.cast<Map<String, dynamic>>();
        final balanceRaw = user['balance'];
        if (balanceRaw is num) {
          _userBalance = balanceRaw.toDouble();
        } else if (balanceRaw is String) {
          _userBalance = double.tryParse(balanceRaw) ?? 0;
        } else {
          _userBalance = 0;
        }
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
    try {
      final user = await _authService.getMe();
      final balanceRaw = user['balance'];
      if (balanceRaw is num) {
        return balanceRaw.toDouble();
      } else if (balanceRaw is String) {
        return double.tryParse(balanceRaw) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _catatPengeluaranKas({
    required double total,
    required String productName,
    required double quantity,
  }) async {
    // This method is no longer directly used for balance updates in the new backend approach.
    // It's kept here for historical context or if other parts of the app still rely on it for local logging.
    // The actual balance deduction will happen via the backend transaction.
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
      'metode': 'Pembelian sapi $productName (${quantity.toInt()} ekor)',
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
        backgroundColor: Colors.cyan[400],
        foregroundColor: Colors.white,
        title: const Text(
          'Pasar Sapi',
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
                        colors: [Colors.cyan[400]!, Colors.cyan[700]!],
                      ),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.shopping_cart, color: Colors.white, size: 60),
                        SizedBox(height: 12),
                        Text(
                          'Pasar Sapi',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Beli sapi secara utuh untuk investasi',
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
                      final priceText = _currencyFormat.format(price);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () => _showBuyDialog(p, index),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Image section - Fixed Width
                                  Hero(
                                    tag: 'product_${p['id']}',
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[100],
                                        child: imageUrl != null && imageUrl.isNotEmpty
                                            ? Image.network(
                                                imageUrl.startsWith('http')
                                                    ? imageUrl
                                                    : '${_client.baseUrl}$imageUrl',
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    const Icon(Icons.pets, color: Colors.grey),
                                              )
                                            : const Icon(Icons.pets, color: Colors.grey, size: 30),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Content section - Flexible
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF2D3142),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          priceText,
                                          style: TextStyle(
                                            color: Colors.cyan[800],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              isSoldOut ? Icons.error_outline : Icons.inventory_2_outlined,
                                              size: 12,
                                              color: isSoldOut ? Colors.red : Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                isSoldOut ? 'Sold Out' : 'Sisa: ${quota.toInt()} ekor',
                                                style: TextStyle(
                                                  color: isSoldOut ? Colors.red : Colors.grey[700],
                                                  fontSize: 11,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Action section - Constrained Width
                                  SizedBox(
                                    width: 75,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!isSoldOut)
                                          ElevatedButton(
                                            onPressed: () => _showBuyDialog(p, index),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.cyan[600],
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(double.infinity, 32),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Text('Beli', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          )
                                        else
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Habis',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 11),
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        InkWell(
                                          onTap: () {
                                              final text = 'Investasi sapi "$name"\nHarga: $priceText\nKuota: ${quota.toInt()} ekor';
                                              Share.share(text, subject: 'Promo Investasi Sapi');
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.share_outlined, size: 14, color: Colors.grey),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  Future<void> _showBuyDialog(Map<String, dynamic> p, int index) async {
    final name = p['name']?.toString() ?? 'Produk';
    final price = double.tryParse(p['price']?.toString() ?? '0') ?? 0;
    final priceText = _currencyFormat.format(price);
    
    final qtyController = TextEditingController(text: '1');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final qtyPreview = double.tryParse(qtyController.text.trim()) ?? 0;
            final totalPreviewNum = price * qtyPreview;
            final totalPreview = _currencyFormat.format(totalPreviewNum);

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Beli Sapi Utuh', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unit: $name', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.cyan[50], borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Harga Unit', style: TextStyle(fontSize: 12)),
                            Text(priceText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Bayar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            Text(totalPreview, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.cyan)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Ekor',
                      prefixIcon: const Icon(Icons.exposure_plus_1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (val) => setDialogState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Bayar Sekarang'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    final qty = double.tryParse(qtyController.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jumlah ekor tidak valid')));
      return;
    }

    final totalHarga = price * qty;
    final saldoKas = await _getKasSaldo();
    if (saldoKas < totalHarga) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saldo tidak cukup. Total: $totalHarga')));
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
        note: 'Pembelian via Pasar Sapi',
      );

      await _catatPengeluaranKas(total: totalHarga, productName: name, quantity: qty);

      if (mounted) {
        setState(() {
          int idx = _products.indexWhere((p) => p['id'] == p['id']); // dummy update, real sync will follow
           _loadProducts(); // true refresh
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🌟 Sukses! Anda telah berhasil membeli $qty ekor $name.',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }
}
