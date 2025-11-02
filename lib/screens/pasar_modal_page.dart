import 'package:flutter/material.dart';
import 'dart:math';

class PasarModalPage extends StatefulWidget {
  const PasarModalPage({super.key});

  @override
  State<PasarModalPage> createState() => _PasarModalPageState();
}

class _PasarModalPageState extends State<PasarModalPage> {
  String selectedSapi = 'Sapi Limosin';
  double currentPrice = 25000000;
  int quantity = 1;
  bool isPriceUp = true;

  final Map<String, double> sapiPrices = {
    'Sapi Limosin': 25000000,
    'Sapi Simental': 28000000,
    'Sapi Bali': 18000000,
    'Sapi Brahman': 22000000,
  };

  // Data untuk grafik sederhana
  final List<double> priceHistory = [
    24500000,
    24700000,
    24900000,
    25200000,
    25000000,
    25300000,
    25100000,
    24800000,
    25000000,
    25200000,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pasar Modal Sapi'),
        backgroundColor: Colors.cyan[400],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header - Pilihan Sapi
            Container(
              color: Colors.cyan[50],
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButton<String>(
                    value: selectedSapi,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    underline: Container(),
                    items: sapiPrices.keys.map((String sapi) {
                      return DropdownMenuItem<String>(
                        value: sapi,
                        child: Row(children: [const Text('🐄 '), Text(sapi)]),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedSapi = newValue;
                          currentPrice = sapiPrices[newValue]!;
                          isPriceUp = Random().nextBool();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rp ${_formatPrice(currentPrice)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                isPriceUp
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: isPriceUp ? Colors.green : Colors.red,
                                size: 16,
                              ),
                              Text(
                                isPriceUp ? '+2.5%' : '-1.8%',
                                style: TextStyle(
                                  color: isPriceUp ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isPriceUp ? '+Rp 500.000' : '-Rp 350.000',
                                style: TextStyle(
                                  color: isPriceUp ? Colors.green : Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Grafik Harga
            Container(
              height: 200,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(158, 158, 158, 0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Grafik Harga 10 Hari Terakhir',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: ChartPainter(priceHistory),
                    ),
                  ),
                ],
              ),
            ),

            // Trading Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Quantity Selector
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jumlah Sapi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                if (quantity > 1) {
                                  setState(() => quantity--);
                                }
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                              iconSize: 36,
                              color: Colors.cyan[700],
                            ),
                            Container(
                              width: 80,
                              alignment: Alignment.center,
                              child: Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() => quantity++);
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              iconSize: 36,
                              color: Colors.cyan[700],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Total: Rp ${_formatPrice(currentPrice * quantity)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyan[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Buy & Sell Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _showTradeDialog(context, 'BUY');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'BUY',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _showTradeDialog(context, 'SELL');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'SELL',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Market Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Pasar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard('Volume Transaksi', '245 ekor'),
                  _buildInfoCard(
                    'Harga Tertinggi',
                    'Rp ${_formatPrice(currentPrice * 1.05)}',
                  ),
                  _buildInfoCard(
                    'Harga Terendah',
                    'Rp ${_formatPrice(currentPrice * 0.95)}',
                  ),
                  _buildInfoCard(
                    'Rata-rata Harga',
                    'Rp ${_formatPrice(currentPrice)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  void _showTradeDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                type == 'BUY' ? Icons.trending_up : Icons.trending_down,
                color: type == 'BUY' ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text('Konfirmasi $type'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jenis Sapi: $selectedSapi'),
              const SizedBox(height: 8),
              Text('Jumlah: $quantity ekor'),
              const SizedBox(height: 8),
              Text('Harga per ekor: Rp ${_formatPrice(currentPrice)}'),
              const SizedBox(height: 8),
              const Divider(),
              Text(
                'Total: Rp ${_formatPrice(currentPrice * quantity)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Transaksi $type berhasil! $quantity ekor $selectedSapi',
                    ),
                    backgroundColor: type == 'BUY' ? Colors.green : Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: type == 'BUY' ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(type),
            ),
          ],
        );
      },
    );
  }
}

// Custom Painter untuk Grafik
class ChartPainter extends CustomPainter {
  final List<double> data;

  ChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final minPrice = data.reduce(min);
    final maxPrice = data.reduce(max);
    final priceRange = maxPrice - minPrice;

    // Mulai path
    final firstX = 0.0;
    final firstY =
        size.height - ((data[0] - minPrice) / priceRange * size.height);

    path.moveTo(firstX, firstY);
    fillPath.moveTo(firstX, size.height);
    fillPath.lineTo(firstX, firstY);

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minPrice) / priceRange * size.height);

      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    // Tutup fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Gambar fill dan line
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Gambar titik-titik
    final pointPaint = Paint()
      ..color = Colors.cyan[700]!
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minPrice) / priceRange * size.height);
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
