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
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
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
            _percentChange = _prevPrice != 0 
                ? ((_currentPrice - _prevPrice) / _prevPrice) * 100 
                : 0.0;
            
            // Add or update latest candle
            if (candleData != null) {
              final newCandle = Candle(
                date: DateTime.parse(candleData['timestamp']),
                high: _toDouble(candleData['high']),
                low: _toDouble(candleData['low']),
                open: _toDouble(candleData['open']),
                close: _toDouble(candleData['close']),
                volume: 1.0, 
              );
              
              // We usually prepend for the candlestick widget
              _candles.insert(0, newCandle);
              // Limit history size
              if (_candles.length > 100) _candles.removeLast();
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
        throw Exception('Gagal memuat produk');
      }
    } catch (e) {
      setState(() => _error = e.toString());
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
            return Candle(
              date: DateTime.parse(item['date']),
              high: _toDouble(item['high']),
              low: _toDouble(item['low']),
              open: _toDouble(item['open']),
              close: _toDouble(item['close']),
              volume: _toDouble(item['volume']),
            );
          }).toList();
          
          // If history is empty, add a dummy initial candle to visualizer
          if (_candles.isEmpty && _selectedProduct != null) {
             final basePrice = _currentPrice > 0 ? _currentPrice : 1000.0;
             _candles.add(Candle(
               date: DateTime.now(),
               high: basePrice * 1.01,
               low: basePrice * 0.99,
               open: basePrice,
               close: basePrice,
               volume: 0,
             ));
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
              child: _candles.isEmpty 
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.cyan),
                        SizedBox(height: 8),
                        Text('Memuat data chart...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : Candlesticks(
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
