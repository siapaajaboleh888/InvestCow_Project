import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PenjualanPage extends StatefulWidget {
  const PenjualanPage({super.key});

  @override
  State<PenjualanPage> createState() => _PenjualanPageState();
}

class _PenjualanPageState extends State<PenjualanPage> {
  final List<Map<String, dynamic>> _sales = [];
  double get totalRevenue => _sales.fold(0.0, (p, e) => p + (e['total'] as double));
  int get countSold => _sales.length;
  String _search = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sales_records');
    setState(() {
      _sales
        ..clear()
        ..addAll(raw == null || raw.isEmpty
            ? []
            : (jsonDecode(raw) as List)
                .cast<Map<String, dynamic>>()
                .map((e) => {
                      'id': e['id'],
                      'item': e['item'],
                      'qty': e['qty'],
                      'price': (e['price'] as num).toDouble(),
                      'total': (e['total'] as num).toDouble(),
                      'date': DateTime.parse(e['date']),
                    }));
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'sales_records',
      jsonEncode(_sales
          .map((e) => {
                'id': e['id'],
                'item': e['item'],
                'qty': e['qty'],
                'price': e['price'],
                'total': e['total'],
                'date': (e['date'] as DateTime).toIso8601String(),
              })
          .toList()),
    );
  }

  Future<void> _addOrEdit({Map<String, dynamic>? current}) async {
    final item = TextEditingController(text: current?['item'] ?? 'Sapi Limosin');
    final qty = TextEditingController(text: (current?['qty'] ?? 1).toString());
    final price = TextEditingController(text: (current?['price'] ?? 25000000).toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(current == null ? 'Penjualan Baru' : 'Edit Penjualan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Jenis Sapi'), controller: item),
            const SizedBox(height: 8),
            TextField(decoration: const InputDecoration(labelText: 'Qty'), controller: qty, keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(decoration: const InputDecoration(labelText: 'Harga (Rp)'), controller: price, keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok == true) {
      final q = int.tryParse(qty.text) ?? 1;
      final p = double.tryParse(price.text) ?? 0;
      final t = q * p;
      setState(() {
        if (current == null) {
          _sales.insert(0, {
            'id': DateTime.now().millisecondsSinceEpoch,
            'item': item.text.trim(),
            'qty': q,
            'price': p,
            'total': t.toDouble(),
            'date': DateTime.now(),
          });
        } else {
          final idx = _sales.indexOf(current);
          _sales[idx] = {
            'id': current['id'],
            'item': item.text.trim(),
            'qty': q,
            'price': p,
            'total': t.toDouble(),
            'date': current['date'],
          };
        }
      });
      await _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.orange[400],
        foregroundColor: Colors.white,
        title: const Text(
          'Penjualan',
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
                        colors: [Colors.orange[400]!, Colors.orange[600]!],
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.trending_up, color: Colors.white, size: 60),
                        const SizedBox(height: 12),
                        const Text('Total Penjualan', style: TextStyle(fontSize: 20, color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text(
                          'Rp ${totalRevenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text('Transaksi: $countSold', style: const TextStyle(fontSize: 16, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Search + Date range filter
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari item/jenis sapi...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _startDate = DateTime(picked.year, picked.month, picked.day));
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_startDate == null ? 'Mulai' : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
                      },
                      icon: const Icon(Icons.event, size: 16),
                      label: Text(_endDate == null ? 'Selesai' : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                    ),
                    IconButton(
                      tooltip: 'Reset filter',
                      onPressed: () => setState(() { _search = ''; _startDate = null; _endDate = null; }),
                      icon: const Icon(Icons.clear),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sales
                      .where((s) {
                        final name = (s['item'] as String).toLowerCase();
                        final d = s['date'] as DateTime;
                        final matchText = _search.isEmpty || name.contains(_search);
                        final afterStart = _startDate == null || !d.isBefore(_startDate!);
                        final beforeEnd = _endDate == null || !d.isAfter(_endDate!);
                        return matchText && afterStart && beforeEnd;
                      })
                      .length,
                  itemBuilder: (context, index) {
                    final filtered = _sales.where((s) {
                      final name = (s['item'] as String).toLowerCase();
                      final d = s['date'] as DateTime;
                      final matchText = _search.isEmpty || name.contains(_search);
                      final afterStart = _startDate == null || !d.isBefore(_startDate!);
                      final beforeEnd = _endDate == null || !d.isAfter(_endDate!);
                      return matchText && afterStart && beforeEnd;
                    }).toList();
                    final s = filtered[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange[100],
                          child: const Icon(Icons.receipt_long, color: Colors.orange),
                        ),
                        title: Text('${s['item']} x${s['qty']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${(s['date'] as DateTime).day}/${(s['date'] as DateTime).month}/${(s['date'] as DateTime).year}'),
                        trailing: Text(
                          'Rp ${(s['total'] as double).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
                        ),
                        onTap: () => _addOrEdit(current: s),
                        onLongPress: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Hapus penjualan?'),
                              content: const Text('Tindakan ini tidak dapat dibatalkan.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
                              ],
                            ),
                          );
                          if (ok == true) {
                            setState(() => _sales.removeAt(index));
                            await _save();
                          }
                        },
                      ),
                    );
                  },
                ),
                if (_sales.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Center(
                      child: Text('Belum ada penjualan. Tekan + untuk menambah.', style: TextStyle(color: Colors.grey[700])),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(),
        backgroundColor: Colors.orange[400],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
