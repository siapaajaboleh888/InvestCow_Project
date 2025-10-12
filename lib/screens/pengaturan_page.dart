import 'package:flutter/material.dart';

class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  bool notifikasiAktif = true;
  bool darkModeAktif = false;
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
            activeColor: Colors.cyan[400],
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
            activeColor: Colors.cyan[400],
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
            activeColor: Colors.cyan[400],
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
}
