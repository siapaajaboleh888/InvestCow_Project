import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class KandangPage extends StatefulWidget {
  const KandangPage({super.key});

  @override
  State<KandangPage> createState() => _KandangPageState();
}

class _KandangPageState extends State<KandangPage> {
  final List<Map<String, dynamic>> _barns = [];
  String _search = '';
  String _occFilter = 'Semua'; // Semua, Tersedia, Penuh

  int get totalCows => _barns.fold(0, (p, e) => p + (e['occupied'] as int));
  int get totalBarns => _barns.length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('barn_records');
    setState(() {
      _barns
        ..clear()
        ..addAll(raw == null || raw.isEmpty
            ? []
            : (jsonDecode(raw) as List)
                .cast<Map<String, dynamic>>()
                .map((e) => {
                      'name': e['name'],
                      'capacity': e['capacity'],
                      'occupied': e['occupied'],
                    }));
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'barn_records',
      jsonEncode(_barns
          .map((e) => {
                'name': e['name'],
                'capacity': e['capacity'],
                'occupied': e['occupied'],
              })
          .toList()),
    );
  }

  Future<void> _addOrEdit({Map<String, dynamic>? current}) async {
    final name = TextEditingController(text: current?['name'] ?? 'Kandang Baru');
    final capacity = TextEditingController(text: (current?['capacity'] ?? 10).toString());
    final occupied = TextEditingController(text: (current?['occupied'] ?? 0).toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(current == null ? 'Tambah Kandang' : 'Edit Kandang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Nama'), controller: name),
            const SizedBox(height: 8),
            TextField(decoration: const InputDecoration(labelText: 'Kapasitas'), controller: capacity, keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(decoration: const InputDecoration(labelText: 'Terisi'), controller: occupied, keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok == true) {
      final cap = int.tryParse(capacity.text) ?? 0;
      final occ = (int.tryParse(occupied.text) ?? 0).clamp(0, cap);
      setState(() {
        if (current == null) {
          _barns.add({'name': name.text.trim(), 'capacity': cap, 'occupied': occ});
        } else {
          final idx = _barns.indexOf(current);
          _barns[idx] = {'name': name.text.trim(), 'capacity': cap, 'occupied': occ};
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
        backgroundColor: Colors.brown[400],
        foregroundColor: Colors.white,
        title: const Text(
          'Manajemen Kandang',
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
                        colors: [Colors.brown[400]!, Colors.brown[600]!],
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.pets, color: Colors.white, size: 60),
                        const SizedBox(height: 12),
                        const Text('Total Sapi', style: TextStyle(fontSize: 20, color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text(
                          '$totalCows',
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text('Kandang: $totalBarns', style: const TextStyle(fontSize: 16, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Daftar Kandang', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                // Search & Filter
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari nama kandang...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _occFilter,
                      items: const [
                        DropdownMenuItem(value: 'Semua', child: Text('Semua')),
                        DropdownMenuItem(value: 'Tersedia', child: Text('Tersedia')),
                        DropdownMenuItem(value: 'Penuh', child: Text('Penuh')),
                      ],
                      onChanged: (v) => setState(() => _occFilter = v ?? 'Semua'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _barns
                      .where((b) {
                        final name = (b['name'] as String).toLowerCase();
                        final cap = b['capacity'] as int;
                        final occ = b['occupied'] as int;
                        final matchSearch = _search.isEmpty || name.contains(_search);
                        final matchFilter = _occFilter == 'Semua' || (_occFilter == 'Tersedia' && occ < cap) || (_occFilter == 'Penuh' && occ >= cap);
                        return matchSearch && matchFilter;
                      })
                      .length,
                  itemBuilder: (context, index) {
                    final filtered = _barns.where((b) {
                      final name = (b['name'] as String).toLowerCase();
                      final cap = b['capacity'] as int;
                      final occ = b['occupied'] as int;
                      final matchSearch = _search.isEmpty || name.contains(_search);
                      final matchFilter = _occFilter == 'Semua' || (_occFilter == 'Tersedia' && occ < cap) || (_occFilter == 'Penuh' && occ >= cap);
                      return matchSearch && matchFilter;
                    }).toList();
                    final b = filtered[index];
                    final cap = b['capacity'] as int;
                    final occ = b['occupied'] as int;
                    final ratio = cap == 0 ? 0.0 : (occ / cap).clamp(0.0, 1.0);
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.brown[100],
                          radius: 30,
                          child: Icon(Icons.home, color: Colors.brown[700], size: 30),
                        ),
                        title: Text(
                          b['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Isi: $occ/$cap ekor'),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: Colors.grey[300],
                              color: Colors.brown[400],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              await _addOrEdit(current: b);
                            } else if (v == 'delete') {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus kandang?'),
                                  content: const Text('Tindakan ini tidak dapat dibatalkan.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                setState(() => _barns.removeAt(index));
                                await _save();
                              }
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
                if (_barns.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Center(
                      child: Text('Belum ada kandang. Tekan + untuk menambah.', style: TextStyle(color: Colors.grey[700])),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(),
        backgroundColor: Colors.brown[400],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
