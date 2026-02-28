import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/transactions_service.dart';
import '../services/portfolios_service.dart';
import 'riwayat_page.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:candlesticks/candlesticks.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hanya ambil angka
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    double value = double.parse(cleanText);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    String newText = formatter.format(value).trim();

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class PasarModalPage extends StatefulWidget {
  const PasarModalPage({super.key});

  @override
  State<PasarModalPage> createState() => _PasarModalPageState();
}

class _PasarModalPageState extends State<PasarModalPage> {
  final _apiClient = ApiClient();
  final _authService = AuthService();
  final _trxService = TransactionsService();
  final _portfolioService = PortfoliosService();
  IO.Socket? socket;
  
  // State
  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _selectedProduct;
  List<Candle> _candles = [];
  bool _isLoading = true;
  String? _error;
  
  double _userBalance = 0;
  String _displayName = "";
  List<Map<String, dynamic>> _portfolioSummary = [];
  final TextEditingController _amountController = TextEditingController(text: '1.000.000');

  // Real-time values
  double _currentPrice = 0;
  double _prevPrice = 0;
  bool _isPriceUp = true;
  double _percentChange = 0.0;
  String? _marketSentiment;
  double _currentWeight = 0;
  double _pricePerKg = 0;

  @override
  void initState() {
    super.initState();
    _initSocket();
    _fetchInitialData();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = await _authService.getMe();
      final summary = await _trxService.getPortfolioSummary();
      if (mounted) {
        setState(() {
          _userBalance = _toDouble(user['balance']);
          _displayName = user['display_name'] ?? "User";
          _portfolioSummary = summary;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    double? d;
    if (val is num) d = val.toDouble();
    if (val is String) d = double.tryParse(val);
    
    if (d == null || d.isNaN || d.isInfinite) return 0.0; 
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
          
          if (!mounted) return;
          setState(() {
            _prevPrice = _currentPrice;
            _currentPrice = newPrice;
            _isPriceUp = _currentPrice >= _prevPrice;
            _percentChange = _prevPrice > 0.01 
                ? ((_currentPrice - _prevPrice) / _prevPrice) * 100 
                : 0.0;
            _marketSentiment = data['marketSentiment']?.toString();
            _currentWeight = _toDouble(data['currentWeight']);
            _pricePerKg = _toDouble(data['pricePerKg']);
            
            // Add or update latest candle
            if (candleData != null) {
              double h = _toDouble(candleData['high']);
              double l = _toDouble(candleData['low']);
              double o = _toDouble(candleData['open']);
              double c = _toDouble(candleData['close']);
              
              if (h == l) { h += 1.0; l -= 1.0; }

              final newCandle = Candle(
                date: DateTime.tryParse(candleData['timestamp']?.toString() ?? '') ?? DateTime.now(),
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
          _currentWeight = _toDouble(_selectedProduct!['current_weight']);
          _pricePerKg = _toDouble(_selectedProduct!['price_per_kg']);
          _marketSentiment = _selectedProduct!['market_sentiment']?.toString();
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
        if (!mounted) return;
        setState(() {
          _candles = data.map<Candle>((item) {
            double h = _toDouble(item['high']);
            double l = _toDouble(item['low']);
            double o = _toDouble(item['open']);
            double c = _toDouble(item['close']);
            
            if (h == l) { h += 1.0; l -= 1.0; }

            return Candle(
              date: DateTime.tryParse(item['timestamp']?.toString() ?? item['date']?.toString() ?? '') ?? DateTime.now(),
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
                date: now.subtract(const Duration(minutes: 5)),
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
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat Transaksi',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () {
              _fetchInitialData();
              _fetchUserData();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Greeting & Balance
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E222D),
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Halo, $_displayName', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const Text('Saldo Anda:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(_formatCurrency(_userBalance), style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _showTopUpDialog,
                    icon: const Icon(Icons.add_card, size: 16),
                    label: const Text('Top Up'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan[700], foregroundColor: Colors.white),
                  )
                ],
              ),
            ),
            // Product Selector & Price
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1E222D),
              child: Column(
                children: [
                  if (_products.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.cyan.withOpacity(0.6), width: 2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Map<String, dynamic>>(
                          value: _selectedProduct,
                          dropdownColor: const Color(0xFF1E222D),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.cyanAccent),
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          items: _products.map((product) {
                            return DropdownMenuItem(
                              value: product,
                              child: Row(
                                children: [
                                  const Text('Jenis Sapi: ', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.normal)),
                                  Text('${product['ticker_code'] ?? 'COW'} - ${product['name'] ?? 'Sapi'}'),
                                ],
                              ),
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
                                _currentWeight = _toDouble(val['current_weight']);
                                _pricePerKg = _toDouble(val['price_per_kg']);
                                _marketSentiment = val['market_sentiment']?.toString();
                                _candles = [];
                              });
                              _fetchHistory(val['id']);
                            }
                          },
                        ),
                      ),
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
                  const SizedBox(height: 12),
                  // Transparency Info Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTransparencyItem('Berat Sapi', '${_currentWeight.toStringAsFixed(2)} kg', Icons.monitor_weight_outlined),
                        Container(width: 1, height: 30, color: Colors.white10),
                        _buildTransparencyItem('Harga/kg', _formatCurrency(_pricePerKg), Icons.payments_outlined),
                        Container(width: 1, height: 30, color: Colors.white10),
                        _buildTransparencyItem('Kesehatan', '${_selectedProduct?['health_score'] ?? 100}%', Icons.health_and_safety_outlined),
                      ],
                    ),
                  ),
                  if (_selectedProduct?['description'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        _selectedProduct!['description'],
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  if (_marketSentiment != null && _marketSentiment!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.newspaper, color: Colors.cyanAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _marketSentiment!,
                              style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Professional Chart
            Container(
              height: 380,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF171B26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: _candles.length < 2 
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.cyan),
                        SizedBox(height: 8),
                        Text('Menyeimbangkan data pasar...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Candlesticks(
                        key: ValueKey('${_selectedProduct?['id']}_${_candles.length}'),
                        candles: _candles,
                      ),
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
                    'Investasi Nominal',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: const TextStyle(color: Colors.grey, fontSize: 18),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                        onPressed: () {
                          _amountController.clear();
                          setState(() {});
                        },
                      ),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.cyan), borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.black26,
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  // Quick Selection Chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickChip('25%', 0.25),
                      _buildQuickChip('50%', 0.50),
                      _buildQuickChip('75%', 0.75),
                      _buildQuickChip('100% (MAX)', 1.0),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_selectedProduct != null)
                    Text(
                      'Estimasi: ${(_toDouble(_amountController.text.replaceAll('.', '')) / _currentPrice).toStringAsFixed(2)} Ekor ${_selectedProduct!['name']}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _tradeButton(
                          'BELI ${_selectedProduct?['ticker_code'] ?? 'SAPI'}', 
                          Colors.greenAccent, 
                          () => _handleTrade('BUY')
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _tradeButton(
                          'JUAL ${_selectedProduct?['ticker_code'] ?? 'SAPI'}', 
                          Colors.redAccent, 
                          () => _handleTrade('SELL')
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            // Portfolio Summary - Only show if there are active holdings
            () {
              final activePortfolio = _portfolioSummary.where((item) => _toDouble(item['total_quantity']) > 0.01).toList();
              if (activePortfolio.isEmpty) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E222D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Portofolio Sapi Saya', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...activePortfolio.map((item) {
                      final ticker = item['symbol'] ?? 'COW';
                      return InkWell(
                        onTap: () {
                          // Find the product in _products that matches this symbol
                          final prod = _products.firstWhere(
                            (p) => p['ticker_code'] == ticker,
                            orElse: () => {},
                          );
                          if (prod.isNotEmpty) {
                            setState(() {
                              _selectedProduct = prod;
                              _currentPrice = _toDouble(prod['price']);
                              _fetchHistory(prod['id']);
                            });
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.touch_app, size: 14, color: Colors.cyanAccent),
                                  const SizedBox(width: 8),
                                  Text(ticker, style: const TextStyle(color: Colors.white70)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${_toDouble(item['total_quantity']).toStringAsFixed(2)} Ekor', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                                  Text(_formatCurrency(_toDouble(item['total_investment'])), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            }(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransparencyItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.cyan[200], size: 16),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _buildQuickChip(String label, double percentage) {
    return InkWell(
      onTap: () {
        double amount = 0;
        // If user already owns this cattle, they might want to sell a percentage of it.
        // If they don't, they want to buy a percentage of their balance.
        // But more logically: let's use balance for buy-focused flow, 
        // or owned asset value for sell-focused flow if they explicitly choose.
        // For simplicity: Max = Balance.
        
        final ticker = _selectedProduct!['ticker_code'];
        final ownedItem = _portfolioSummary.firstWhere(
          (item) => item['symbol'] == ticker,
          orElse: () => {},
        );

        if (ownedItem.isNotEmpty && _toDouble(ownedItem['total_quantity']) > 0) {
           // If they own it, 100% means selling all of it
           double totalOwnedValue = _toDouble(ownedItem['total_quantity']) * _currentPrice;
           amount = totalOwnedValue * percentage;
        } else {
           // If they don't own it, 100% means using all balance
           amount = _userBalance * percentage;
        }

        if (amount > 0) {
          final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
          _amountController.text = formatter.format(amount).trim();
          setState(() {});
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
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
        side: BorderSide(color: color, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(
        label, 
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showTopUpDialog() {
    final TextEditingController topUpCtrl = TextEditingController(text: '0');
    String selectedMethod = 'BCA';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E222D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.cyan, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text('Top Up Saldo', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                
                const Text('Masukkan Nominal', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 12),
                TextField(
                  controller: topUpCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(color: Colors.grey, fontSize: 20),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.cyan), borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.black26,
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text('Nominal Cepat', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [50000, 100000, 200000, 500000, 1000000].map((amt) {
                    final formattedAmt = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(amt).trim();
                    return InkWell(
                      onTap: () => setModalState(() => topUpCtrl.text = formattedAmt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: topUpCtrl.text == formattedAmt ? Colors.cyan.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                          border: Border.all(color: topUpCtrl.text == formattedAmt ? Colors.cyan : Colors.white10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_formatCurrency(amt.toDouble()), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                
                const Text('Pilih Metode Pembayaran', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.2,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPaymentItem('BCA', 'B', Colors.blue, selectedMethod, (val) => setModalState(() => selectedMethod = val)),
                    _buildPaymentItem('Mandiri', 'M', Colors.orange, selectedMethod, (val) => setModalState(() => selectedMethod = val)),
                    _buildPaymentItem('BNI', 'B', Colors.deepOrange, selectedMethod, (val) => setModalState(() => selectedMethod = val)),
                    _buildPaymentItem('BRI', 'B', Colors.indigo, selectedMethod, (val) => setModalState(() => selectedMethod = val)),
                    _buildPaymentItem('Dana', 'D', Colors.blueAccent, selectedMethod, (val) => setModalState(() => selectedMethod = val)),
                    _buildPaymentItem('OVO', 'O', Colors.purple, selectedMethod, (val) => setModalState(() => selectedMethod = val)),
                    _buildPaymentItem('GoPay', 'G', Colors.green, selectedMethod, (val) => setModalState(() => selectedMethod = val)),
                    _buildPaymentItem('ShopeePay', 'S', Colors.redAccent, selectedMethod, (val) => setModalState(() => selectedMethod = val)),
                  ],
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final amt = double.tryParse(topUpCtrl.text.replaceAll('.', '')) ?? 0;
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan nominal yang valid')));
                          return;
                        }
                        await _authService.topUp(amt, method: selectedMethod);
                        if (!mounted) return;
                        Navigator.pop(context);
                        _fetchUserData();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Top Up ${_formatCurrency(amt)} via $selectedMethod Berhasil!'),
                          backgroundColor: Colors.green,
                        ));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Top Up Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentItem(String name, String initial, Color color, String current, Function(String) onSelect) {
    bool isSelected = current == name;
    return InkWell(
      onTap: () => onSelect(name),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          border: Border.all(color: isSelected ? color : Colors.white10, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
              child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 4),
            Text(name, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  void _handleTrade(String type) async {
    if (_selectedProduct == null) return;
    
    final nominal = double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;
    if (nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan nominal investasi yang valid')));
      return;
    }

    final qty = nominal / _currentPrice;

    if (type == 'BUY' && nominal > _userBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saldo tidak mencukupi. Silakan Top Up!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Validation for SELL: Check ownership and quantity
    if (type == 'SELL') {
      final ticker = _selectedProduct!['ticker_code'];
      final ownedItem = _portfolioSummary.firstWhere(
        (item) => item['symbol'] == ticker,
        orElse: () => {},
      );

      if (ownedItem.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            padding: const EdgeInsets.all(16),
            content: Text(
              '⚠️ Gagal: Sapi yang ingin Anda jual ($ticker) tidak sesuai dengan kepemilikan aset di portofolio Anda. Mohon pilih jenis sapi yang benar.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final ownedQty = _toDouble(ownedItem['total_quantity']);
      if (qty > (ownedQty + 0.000001)) { // Small epsilon to avoid floating point issues
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Aset tidak mencukupi! Anda hanya memiliki ${ownedQty.toStringAsFixed(2)} ekor sapi ini, sedangkan Anda mencoba menjual ${qty.toStringAsFixed(2)} ekor.'
            ),
            backgroundColor: Colors.orange[800],
          ),
        );
        return;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E222D),
        title: Text('Konfirmasi ${type == 'BUY' ? 'Investasi' : 'Penjualan'}', style: const TextStyle(color: Colors.white)),
        content: Text(
          'Anda akan ${type == 'BUY' ? 'menginvestasikan' : 'menjual'} ${_formatCurrency(nominal)} (${qty.toStringAsFixed(2)} Ekor) pada ${_selectedProduct!['name']}. Lanjutkan?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: type == 'BUY' ? Colors.green : Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              
              // 1. Local Optimistic Update for "Real-time" feel
              setState(() {
                final ticker = _selectedProduct!['ticker_code'];
                int index = _portfolioSummary.indexWhere((item) => item['symbol'] == ticker);
                
                if (type == 'BUY') {
                  _userBalance -= nominal;
                  if (index != -1) {
                    _portfolioSummary[index]['total_quantity'] = _toDouble(_portfolioSummary[index]['total_quantity']) + qty;
                    _portfolioSummary[index]['total_investment'] = _toDouble(_portfolioSummary[index]['total_investment']) + nominal;
                  } else {
                    _portfolioSummary.add({
                      'symbol': ticker,
                      'total_quantity': qty,
                      'total_investment': nominal,
                    });
                  }
                } else {
                  _userBalance += nominal; // Estimated, backend will provide net gain
                  if (index != -1) {
                    double current = _toDouble(_portfolioSummary[index]['total_quantity']);
                    double next = current - qty;
                    if (next < 0.0001) {
                      _portfolioSummary.removeAt(index);
                    } else {
                      _portfolioSummary[index]['total_quantity'] = next;
                    }
                  }
                }
              });

              try {
                final portfolio = await _portfolioService.getOrCreateDefault();
                await _trxService.create(
                  portfolioId: portfolio['id'],
                  type: type.toLowerCase(),
                  symbol: _selectedProduct!['ticker_code'],
                  quantity: qty,
                  price: _currentPrice,
                  occurredAt: DateTime.now(),
                );
                
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Transaksi ${type == 'BUY' ? 'Pembelian' : 'Penjualan'} Berhasil!'), backgroundColor: Colors.green),
                );
                
                // 2. Sync with Server after a tiny delay to ensure DB propagation
                await Future.delayed(const Duration(milliseconds: 800));
                if (!mounted) return;
                await _fetchUserData(); 
                await _fetchInitialData(); // Refresh product quotas too
              } catch (e) {
                // Rollback local state on error
                if (!mounted) return;
                _fetchUserData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
  }
}
