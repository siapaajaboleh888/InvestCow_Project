import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class KesehatanPage extends StatefulWidget {
  const KesehatanPage({super.key});

  @override
  State<KesehatanPage> createState() => _KesehatanPageState();
}

class _KesehatanPageState extends State<KesehatanPage> {
  final List<Map<String, dynamic>> _records = [];
  int get sehatCount => _records.where((e) => e['status'] == 'Sehat').length;
  int get perawatanCount => _records.where((e) => e['status'] != 'Sehat').length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('health_records');
    setState(() {
      _records
        ..clear()
        ..addAll(raw == null || raw.isEmpty
            ? []
            : (jsonDecode(raw) as List)
                .cast<Map<String, dynamic>>()
                .map((e) => {
                      'nama': e['nama'],
                      'status': e['status'],
                      'next': e['next'] != null ? DateTime.parse(e['next']) : null,
                    }));
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'health_records',
      jsonEncode(_records
          .map((e) => {
                'nama': e['nama'],
                'status': e['status'],
                'next': (e['next'] as DateTime?)?.toIso8601String(),
              })
          .toList()),
    );
  }

  Future<void> _addOrEdit({Map<String, dynamic>? current}) async {
    final name = TextEditingController(text: current?['nama'] ?? '');
    String status = current?['status'] ?? 'Sehat';
    DateTime? nextDate = current?['next'];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(current == null ? 'Tambah Catatan' : 'Edit Catatan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nama Sapi'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'Sehat', child: Text('Sehat')),
                    DropdownMenuItem(value: 'Perawatan', child: Text('Perawatan')),
                    DropdownMenuItem(value: 'Sakit', child: Text('Sakit')),
                  ],
                  onChanged: (v) => setS(() => status = v ?? 'Sehat'),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.vaccines),
                  title: const Text('Jadwal Vaksin Berikutnya'),
                  subtitle: Text(
                    nextDate == null
                        ? 'Belum diatur'
                        : '${nextDate!.day}/${nextDate!.month}/${nextDate!.year}',
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: nextDate ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (picked != null) setS(() => nextDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      setState(() {
        if (current == null) {
          _records.add({'nama': name.text.trim(), 'status': status, 'next': nextDate});
        } else {
          final idx = _records.indexOf(current);
          _records[idx] = {'nama': name.text.trim(), 'status': status, 'next': nextDate};
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
        backgroundColor: Colors.red[400],
        foregroundColor: Colors.white,
        title: const Text(
          'Kesehatan Sapi',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
                      colors: [Colors.red[400]!, Colors.red[600]!],
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.medical_services,
                        color: Colors.white,
                        size: 60,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Monitoring Kesehatan',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sehat: $sehatCount • Perawatan/Sakit: $perawatanCount',
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _records.length,
                itemBuilder: (context, index) {
                  final r = _records[index];
                  final overdue = r['next'] != null && (r['next'] as DateTime).isBefore(DateTime.now());
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: r['status'] == 'Sehat' ? Colors.green[100] : Colors.orange[100],
                        child: Icon(
                          overdue ? Icons.warning_amber : Icons.health_and_safety,
                          color: overdue ? Colors.orange[700] : (r['status'] == 'Sehat' ? Colors.green[700] : Colors.orange[700]),
                        ),
                      ),
                      title: Text(r['nama'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${r['status']}'),
                          Text('Vaksin berikutnya: ' + (
                              r['next'] == null ? '-' : '${(r['next'] as DateTime).day}/${(r['next'] as DateTime).month}/${(r['next'] as DateTime).year}'
                          )),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') {
                            await _addOrEdit(current: r);
                          } else if (v == 'delete') {
                            setState(() => _records.removeAt(index));
                            await _save();
                          }
                        },
                        itemBuilder: (ctx) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Hapus')),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (_records.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Center(
                    child: Text('Belum ada catatan. Tekan + untuk menambah.', style: TextStyle(color: Colors.grey[700])),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(),
        backgroundColor: Colors.red[400],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
