import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PembayaranPage extends StatefulWidget {
  const PembayaranPage({super.key});

  @override
  State<PembayaranPage> createState() => _PembayaranPageState();
}

class _PembayaranPageState extends State<PembayaranPage> {
  double saldo = 0;
  final List<Map<String, dynamic>> riwayat = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      saldo = prefs.getDouble('kas_saldo') ?? 0;
      final raw = prefs.getString('kas_riwayat');
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        riwayat
          ..clear()
          ..addAll(list.map((e) => {
                'jenis': e['jenis'],
                'nominal': (e['nominal'] as num).toDouble(),
                'metode': e['metode'],
                'tanggal': DateTime.parse(e['tanggal']),
                'status': e['status'],
              }));
      }
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('kas_saldo', saldo);
    final encoded = jsonEncode(riwayat
        .map((e) => {
              'jenis': e['jenis'],
              'nominal': e['nominal'],
              'metode': e['metode'],
              'tanggal': (e['tanggal'] as DateTime).toIso8601String(),
              'status': e['status'],
            })
        .toList());
    await prefs.setString('kas_riwayat', encoded);
  }

  Future<void> _topUp() async {
    final controller = TextEditingController();
    final metode = TextEditingController(text: 'Transfer Bank');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Top Up Saldo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: metode,
              decoration: const InputDecoration(labelText: 'Metode'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Top Up')),
        ],
      ),
    );
    if (ok == true) {
      final nominal = double.tryParse(controller.text);
      if (nominal != null && nominal > 0) {
        setState(() {
          saldo += nominal;
          riwayat.insert(0, {
            'jenis': 'Top Up',
            'nominal': nominal,
            'metode': metode.text.trim().isEmpty ? 'Transfer Bank' : metode.text.trim(),
            'tanggal': DateTime.now(),
            'status': 'Berhasil',
          });
        });
        await _save();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Top Up berhasil'), backgroundColor: Colors.green),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.purple[400],
        foregroundColor: Colors.white,
        title: const Text(
          'Pembayaran',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
        ),
        elevation: 0,
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
                        colors: [Colors.purple[400]!, Colors.purple[600]!],
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.credit_card, color: Colors.white, size: 60),
                        const SizedBox(height: 12),
                        const Text(
                          'Saldo Tersedia',
                          style: TextStyle(fontSize: 20, color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rp ${saldo.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _topUp,
                        icon: const Icon(Icons.add_circle),
                        label: const Text('Top Up'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Fitur transfer akan ditambahkan'), backgroundColor: Colors.orange),
                          );
                        },
                        icon: const Icon(Icons.send),
                        label: const Text('Transfer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Transaksi Terakhir',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: riwayat.length.clamp(0, 20),
                  itemBuilder: (context, index) {
                    final t = riwayat[index];
                    final income = t['jenis'] == 'Top Up';
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: income ? Colors.green[100] : Colors.red[100],
                          radius: 30,
                          child: Icon(
                            income ? Icons.arrow_downward : Icons.arrow_upward,
                            color: income ? Colors.green[700] : Colors.red[700],
                            size: 30,
                          ),
                        ),
                        title: Text(
                          t['jenis'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          '${(t['tanggal'] as DateTime).day}/${(t['tanggal'] as DateTime).month}/${(t['tanggal'] as DateTime).year}',
                        ),
                        trailing: Text(
                          '${income ? '+' : '-'} Rp ${(t['nominal'] as double).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: income ? Colors.green[700] : Colors.red[700],
                            fontSize: 14,
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
}
