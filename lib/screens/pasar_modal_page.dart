import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import '../services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:candlesticks/candlesticks.dart';
import 'package:intl/intl.dart';

class PasarModalPage extends StatefulWidget {
  const PasarModalPage({super.key});

  @override
  State<PasarModalPage> createState() => _PasarModalPageState();
}

class _PasarModalPageState extends State<PasarModalPage> {
  final _apiClient = ApiClient();
  IO.Socket? socket;
  
  // State
  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _selectedProduct;
  List<Candle> _candles = [];
  bool _isLoading = true;
  String? _error;
  int quantity = 1;

  // Real-time values
  double _currentPrice = 0;
  double _prevPrice = 0;
  bool _isPriceUp = true;
  double _percentChange = 0.0;

  @override
  void initState() {
    super.initState();
    _initSocket();
    _fetchInitialData();
  }

  double _toDouble(dynamic val) {
    if (val == null) return 10.0;
    double? d;
    if (val is num) d = val.toDouble();
    if (val is String) d = double.tryParse(val);
    
    // Minimum 10.0 to avoid any log issues or tiny numbers causing division problems
    if (d == null || d <= 0 || d.isNaN || d.isInfinite) return 10.0; 
    return d;
  }

  void _initSocket() {
    final url = _apiClient.socketUrl;
    socket = IO.io(url, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());

    socket!.onConnect((_) {
      print('Connected to Socket.io');
    });

    socket!.on('price-update', (data) {
      if (data != null && _selectedProduct != null) {
        final productId = data['productId'].toString();
        if (productId == _selectedProduct!['id'].toString()) {
          final newPrice = _toDouble(data['newPrice']);
          final candleData = data['candle'];
          
          setState(() {
            _prevPrice = _currentPrice;
            _currentPrice = newPrice;
            _isPriceUp = _currentPrice >= _prevPrice;
            _percentChange = _prevPrice > 0.01 
                ? ((_currentPrice - _prevPrice) / _prevPrice) * 100 
                : 0.0;
            
            // Add or update latest candle
            if (candleData != null) {
              double h = _toDouble(candleData['high']);
              double l = _toDouble(candleData['low']);
              double o = _toDouble(candleData['open']);
              double c = _toDouble(candleData['close']);
              
              if (h == l) { h += 1.0; l -= 1.0; }

              final newCandle = Candle(
                date: DateTime.tryParse(candleData['timestamp'].toString()) ?? DateTime.now(),
                high: h,
                low: l,
                open: o,
                close: c,
                volume: 1.0, 
              );
              
              _candles.insert(0, newCandle);
              if (_candles.length > 200) _candles.removeLast();

              // CRITICAL: If still only 1 candle, add dummy to prevent crash
              if (_candles.length == 1) {
                 _candles.add(Candle(
                   date: newCandle.date.subtract(const Duration(minutes: 1)),
                   high: newCandle.high,
                   low: newCandle.low,
                   open: newCandle.open,
                   close: newCandle.close,
                   volume: 0,
                 ));
              }
            }
          });
        }
      }
    });

    socket!.connect();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await http.get(_apiClient.uri('/admin/products-public'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        _products = data.cast<Map<String, dynamic>>();
        if (_products.isNotEmpty) {
          _selectedProduct = _products[0];
          _currentPrice = _toDouble(_selectedProduct!['price']);
          await _fetchHistory(_selectedProduct!['id']);
        }
      } else {
        throw Exception('Gagal memuat produk: ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchHistory(dynamic productId) async {
    try {
      final res = await http.get(_apiClient.uri('/admin/products/$productId/history'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _candles = data.map<Candle>((item) {
            double h = _toDouble(item['high']);
            double l = _toDouble(item['low']);
            double o = _toDouble(item['open']);
            double c = _toDouble(item['close']);
            
            if (h == l) { h += 1.0; l -= 1.0; }

            return Candle(
              date: DateTime.tryParse(item['date'].toString()) ?? DateTime.now(),
              high: h,
              low: l,
              open: o,
              close: c,
              volume: _toDouble(item['volume']),
            );
          }).toList();
          
          // Ensure at least 2 candles for the chart stability
          if (_candles.length < 2 && _selectedProduct != null) {
             final basePrice = _currentPrice > 10.0 ? _currentPrice : 1000.0;
             final now = DateTime.now();
             
             List<Candle> dummy = [];
             // First candle
             dummy.add(Candle(
               date: now.subtract(const Duration(minutes: 1)),
               high: basePrice * 1.005,
               low: basePrice * 0.995,
               open: basePrice * 0.998,
               close: basePrice,
               volume: 1,
             ));
             // Second candle
             dummy.add(Candle(
               date: now,
               high: basePrice * 1.01,
               low: basePrice * 0.99,
               open: basePrice,
               close: basePrice,
               volume: 1,
             ));
             
             // Prepend existing if any, or just use dummy
             if (_candles.isNotEmpty) {
               dummy.removeLast(); // keep the existing one as latest
               dummy.addAll(_candles);
             }
             
             _candles = dummy.reversed.toList();
          }
        });
      }
    } catch (e) {
      print('Error fetching history: $e');
    }
  }

  @override
  void dispose() {
    socket?.dispose();
    super.dispose();
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF131722),
        body: Center(child: CircularProgressIndicator(color: Colors.cyan[700])),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF131722),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchInitialData,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF131722), // TradingView dark background
      appBar: AppBar(
        title: const Text('Terminal Pasar Sapi'),
        backgroundColor: const Color(0xFF1E222D),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchInitialData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Product Selector & Price
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1E222D),
              child: Column(
                children: [
                  if (_products.isNotEmpty)
                    DropdownButton<Map<String, dynamic>>(
                      value: _selectedProduct,
                      dropdownColor: const Color(0xFF1E222D),
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      underline: Container(),
                      items: _products.map((product) {
                        return DropdownMenuItem(
                          value: product,
                          child: Text('${product['ticker_code'] ?? 'COW'} - ${product['name'] ?? 'Sapi'}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedProduct = val;
                            _currentPrice = _toDouble(val['price']);
                            final prevPrice = _toDouble(val['prev_price']);
                            _percentChange = prevPrice != 0 
                                ? ((_currentPrice - prevPrice) / prevPrice) * 100 
                                : 0.0;
                            _isPriceUp = _currentPrice >= prevPrice;
                            _candles = [];
                          });
                          _fetchHistory(val['id']);
                        }
                      },
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatCurrency(_currentPrice),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                _isPriceUp ? Icons.arrow_upward : Icons.arrow_downward,
                                color: _isPriceUp ? Colors.greenAccent : Colors.redAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_isPriceUp ? "+" : ""}${_percentChange.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color: _isPriceUp ? Colors.greenAccent : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _selectedProduct?['ticker_code'] ?? 'COW',
                                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const CircleAvatar(
                         backgroundColor: Colors.cyan,
                         child: Icon(Icons.show_chart, color: Colors.white),
                      )
                    ],
                  ),
                ],
              ),
            ),

            // Professional Chart
            Container(
              height: 350,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _candles.length < 2 
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.cyan),
                        SizedBox(height: 8),
                        Text('Memproses data pasar...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : Candlesticks(
                    key: ValueKey('${_selectedProduct?['id']}_${_candles.length}'),
                    candles: _candles,
                  ),
            ),

            // Trading Panel
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E222D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Eksekusi',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jumlah (Ekor)', style: TextStyle(color: Colors.grey)),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(() => quantity = max(1, quantity - 1)),
                            icon: const Icon(Icons.remove_circle, color: Colors.cyan),
                          ),
                          Text(
                            '$quantity',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () => setState(() => quantity++),
                            icon: const Icon(Icons.add_circle, color: Colors.cyan),
                          ),
                        ],
                      )
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Investasi', style: TextStyle(color: Colors.grey)),
                      Text(
                        _formatCurrency(_currentPrice * quantity),
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _tradeButton('BELI', Colors.greenAccent, () => _handleTrade('BUY')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _tradeButton('JUAL', Colors.redAccent, () => _handleTrade('SELL')),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tradeButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  void _handleTrade(String type) {
    if (_selectedProduct == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E222D),
        title: Text('Konfirmasi $type', style: const TextStyle(color: Colors.white)),
        content: Text(
          'Anda yakin ingin ${type == 'BUY' ? 'membeli' : 'menjual'} $quantity ekor ${_selectedProduct!['name']} seharga ${_formatCurrency(_currentPrice * quantity)}?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: type == 'BUY' ? Colors.green : Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Pesanan $type Berhasil Ditempatkan!'), backgroundColor: Colors.cyan),
              );
            },
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
  }
}
