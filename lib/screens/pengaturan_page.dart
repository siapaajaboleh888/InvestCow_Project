import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  bool notifikasiAktif = true;
  bool darkModeAktif = true;
  bool lokasiAktif = true;
  String bahasa = 'Indonesia';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Colors.cyan[400],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Section: Notifikasi
          _buildSectionHeader('Notifikasi'),
          SwitchListTile(
            title: const Text('Notifikasi Push'),
            subtitle: const Text('Terima notifikasi dari aplikasi'),
            value: notifikasiAktif,
            activeThumbColor: Colors.cyan[400],
            onChanged: (value) {
              setState(() {
                notifikasiAktif = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? 'Notifikasi diaktifkan'
                        : 'Notifikasi dinonaktifkan',
                  ),
                ),
              );
            },
          ),

          const Divider(),

          // Section: Tampilan
          _buildSectionHeader('Tampilan'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Gunakan tema gelap'),
            value: darkModeAktif,
            activeThumbColor: Colors.cyan[400],
            onChanged: (value) {
              setState(() {
                darkModeAktif = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? 'Dark mode diaktifkan' : 'Dark mode dinonaktifkan',
                  ),
                ),
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.language, color: Colors.cyan[400]),
            title: const Text('Bahasa'),
            subtitle: Text(bahasa),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showBahasaDialog();
            },
          ),

          const Divider(),

          // Section: Privasi & Keamanan
          _buildSectionHeader('Privasi & Keamanan'),
          SwitchListTile(
            title: const Text('Layanan Lokasi'),
            subtitle: const Text('Izinkan akses lokasi'),
            value: lokasiAktif,
            activeThumbColor: Colors.cyan[400],
            onChanged: (value) {
              setState(() {
                lokasiAktif = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? 'Lokasi diaktifkan' : 'Lokasi dinonaktifkan',
                  ),
                ),
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.privacy_tip, color: Colors.cyan[400]),
            title: const Text('Kebijakan Privasi'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Membuka Kebijakan Privasi')),
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.security, color: Colors.cyan[400]),
            title: const Text('Keamanan Akun'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Membuka Keamanan Akun')),
              );
            },
          ),

          const Divider(),

          // Section: Data & Penyimpanan
          _buildSectionHeader('Data & Penyimpanan'),
          ListTile(
            leading: Icon(Icons.file_upload, color: Colors.cyan[400]),
            title: const Text('Export Data (JSON)'),
            subtitle: const Text('Salin semua data aplikasi dalam format JSON'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _exportData,
          ),
          // Per-module export
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
            child: Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(onPressed: () => _exportModule('kas'), icon: const Icon(Icons.account_balance_wallet), label: const Text('Kas')),
                OutlinedButton.icon(onPressed: () => _exportModule('kesehatan'), icon: const Icon(Icons.medical_services), label: const Text('Kesehatan')),
                OutlinedButton.icon(onPressed: () => _exportModule('penjualan'), icon: const Icon(Icons.trending_up), label: const Text('Penjualan')),
                OutlinedButton.icon(onPressed: () => _exportModule('kandang'), icon: const Icon(Icons.home), label: const Text('Kandang')),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.file_download, color: Colors.cyan[400]),
            title: const Text('Import Data (JSON)'),
            subtitle: const Text('Tempel JSON untuk memulihkan data'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _importData,
          ),
          // Per-module import
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
            child: Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(onPressed: () => _importModule('kas'), icon: const Icon(Icons.account_balance_wallet), label: const Text('Kas')),
                OutlinedButton.icon(onPressed: () => _importModule('kesehatan'), icon: const Icon(Icons.medical_services), label: const Text('Kesehatan')),
                OutlinedButton.icon(onPressed: () => _importModule('penjualan'), icon: const Icon(Icons.trending_up), label: const Text('Penjualan')),
                OutlinedButton.icon(onPressed: () => _importModule('kandang'), icon: const Icon(Icons.home), label: const Text('Kandang')),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.storage, color: Colors.cyan[400]),
            title: const Text('Kelola Penyimpanan'),
            subtitle: const Text('1.2 GB digunakan'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Membuka Kelola Penyimpanan')),
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red[400]),
            title: const Text('Hapus Cache'),
            subtitle: const Text('Bersihkan data cache aplikasi'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showHapusCacheDialog();
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.cyan[700],
        ),
      ),
    );
  }

  void _showBahasaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Bahasa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Indonesia'),
              value: 'Indonesia',
              groupValue: bahasa,
              activeColor: Colors.cyan[400],
              onChanged: (value) {
                setState(() {
                  bahasa = value!;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bahasa diubah ke Indonesia')),
                );
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: bahasa,
              activeColor: Colors.cyan[400],
              onChanged: (value) {
                setState(() {
                  bahasa = value!;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Language changed to English')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHapusCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Cache'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus semua cache aplikasi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache berhasil dihapus')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'kas_saldo': prefs.getDouble('kas_saldo') ?? 0,
      'kas_riwayat': jsonDecode(prefs.getString('kas_riwayat') ?? '[]'),
      'health_records': jsonDecode(prefs.getString('health_records') ?? '[]'),
      'sales_records': jsonDecode(prefs.getString('sales_records') ?? '[]'),
      'barn_records': jsonDecode(prefs.getString('barn_records') ?? '[]'),
    };
    final pretty = const JsonEncoder.withIndent('  ').convert(data);

    final controller = TextEditingController(text: pretty);
    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Data JSON'),
        content: SizedBox(
          width: 600,
          child: TextField(
            controller: controller,
            maxLines: 16,
            readOnly: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: controller.text));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tersalin ke clipboard')));
            },
            child: const Text('Copy'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Future<void> _importData() async {
    final input = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Data JSON'),
        content: SizedBox(
          width: 600,
          child: TextField(
            controller: input,
            maxLines: 16,
            decoration: const InputDecoration(hintText: 'Tempel JSON di sini', border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final decoded = jsonDecode(input.text);
      if (decoded is! Map<String, dynamic>) throw 'Root harus object';
      final obj = decoded as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      if (obj.containsKey('kas_saldo')) {
        final v = obj['kas_saldo'];
        if (v is num) await prefs.setDouble('kas_saldo', v.toDouble());
      }
      if (obj.containsKey('kas_riwayat')) {
        final list = obj['kas_riwayat'];
        if (list is! List) throw 'kas_riwayat harus array';
        await prefs.setString('kas_riwayat', jsonEncode(list));
      }
      if (obj.containsKey('health_records')) {
        final list = obj['health_records'];
        if (list is! List) throw 'health_records harus array';
        await prefs.setString('health_records', jsonEncode(list));
      }
      if (obj.containsKey('sales_records')) {
        final list = obj['sales_records'];
        if (list is! List) throw 'sales_records harus array';
        await prefs.setString('sales_records', jsonEncode(list));
      }
      if (obj.containsKey('barn_records')) {
        final list = obj['barn_records'];
        if (list is! List) throw 'barn_records harus array';
        await prefs.setString('barn_records', jsonEncode(list));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import berhasil'), backgroundColor: Colors.green),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal import: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportModule(String module) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> data;
    switch (module) {
      case 'kas':
        data = {
          'kas_saldo': prefs.getDouble('kas_saldo') ?? 0,
          'kas_riwayat': jsonDecode(prefs.getString('kas_riwayat') ?? '[]'),
        };
        break;
      case 'kesehatan':
        data = {'health_records': jsonDecode(prefs.getString('health_records') ?? '[]')};
        break;
      case 'penjualan':
        data = {'sales_records': jsonDecode(prefs.getString('sales_records') ?? '[]')};
        break;
      case 'kandang':
        data = {'barn_records': jsonDecode(prefs.getString('barn_records') ?? '[]')};
        break;
      default:
        data = {};
    }
    final pretty = const JsonEncoder.withIndent('  ').convert(data);
    final controller = TextEditingController(text: pretty);
    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Export ${module[0].toUpperCase()}${module.substring(1)}'),
        content: SizedBox(
          width: 600,
          child: TextField(controller: controller, maxLines: 16, readOnly: true, decoration: const InputDecoration(border: OutlineInputBorder())),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: controller.text));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tersalin ke clipboard')));
            },
            child: const Text('Copy'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Future<void> _importModule(String module) async {
    final input = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Import ${module[0].toUpperCase()}${module.substring(1)}'),
        content: SizedBox(
          width: 600,
          child: TextField(controller: input, maxLines: 16, decoration: const InputDecoration(hintText: 'Tempel JSON di sini', border: OutlineInputBorder())),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final decoded = jsonDecode(input.text);
      if (decoded is! Map<String, dynamic>) throw 'Root harus object';
      final obj = decoded as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      switch (module) {
        case 'kas':
          if (obj.containsKey('kas_saldo')) {
            final v = obj['kas_saldo'];
            if (v is! num) throw 'kas_saldo harus number';
            await prefs.setDouble('kas_saldo', v.toDouble());
          }
          if (obj.containsKey('kas_riwayat')) {
            final list = obj['kas_riwayat'];
            if (list is! List) throw 'kas_riwayat harus array';
            await prefs.setString('kas_riwayat', jsonEncode(list));
          }
          break;
        case 'kesehatan':
          if (!obj.containsKey('health_records') || obj['health_records'] is! List) throw 'health_records harus array';
          await prefs.setString('health_records', jsonEncode(obj['health_records']));
          break;
        case 'penjualan':
          if (!obj.containsKey('sales_records') || obj['sales_records'] is! List) throw 'sales_records harus array';
          await prefs.setString('sales_records', jsonEncode(obj['sales_records']));
          break;
        case 'kandang':
          if (!obj.containsKey('barn_records') || obj['barn_records'] is! List) throw 'barn_records harus array';
          await prefs.setString('barn_records', jsonEncode(obj['barn_records']));
          break;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import berhasil'), backgroundColor: Colors.green));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal import: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
