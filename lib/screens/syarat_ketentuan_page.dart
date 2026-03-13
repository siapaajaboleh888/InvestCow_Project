import 'package:flutter/material.dart';

class SyaratKetentuanPage extends StatelessWidget {
  const SyaratKetentuanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Syarat & Ketentuan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perjanjian Investasi Syirkah InvestCow',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Terakhir diperbarui: 13 Maret 2026',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Pendahuluan',
              'Selamat bergabung di InvestCow. Dengan mendaftar akun, Anda menundukkan diri pada syarat dan ketentuan ini. InvestCow adalah platform yang menghubungkan Investor dengan Peternak Mitra melalui skema investasi riil aset ternak.',
            ),
            _buildSection(
              '2. Definisi Kepemilikan',
              '• Sapi Utuh: Kepemilikan ≥ 1 Unit. Investor memiliki hak penuh atas 1 ekor sapi tertentu.\n'
              '• Kepemilikan Fraksional: Kepemilikan < 1 Unit. Investor memiliki porsi kepemilikan atas nilai aset ekonomi sapi yang dikelola secara kolektif.',
            ),
            _buildSection(
              '3. Sistem Bagi Hasil (Syirkah)',
              'Berdasarkan kesepakatan adil, pembagian Keuntungan Netto diatur sebagai berikut:\n'
              '• Skema Sapi Utuh: Investor mendapatkan 90%, Peternak mendapatkan 10% sebagai upah jasa pengelolaan.\n'
              '• Skema Fraksional: Investor mendapatkan 70%, Peternak mendapatkan 30% sebagai upah jasa pengelolaan dan biaya administrasi pooling.',
            ),
            _buildSection(
              '4. Jangka Waktu & Penjualan',
              'Masa penggemukan (fattening) umumnya berlangsung 3-6 bulan. Investor memiliki hak untuk menentukan waktu jual melalui dashboard Pasar Modal sesuai dengan ketersediaan pembeli dan harga pasar yang berlaku.',
            ),
            _buildSection(
              '5. Mitigasi Risiko',
              'Setiap investasi memiliki risiko. InvestCow memitigasi risiko kematian melalui:\n'
              '• Asuransi Ternak (T&C berlaku sesuai polis provider).\n'
              '• Dana Cadangan Likuid untuk penanganan kesehatan darurat.\n'
              '• Namun demikian, penurunan harga pasar (market risk) adalah tanggung jawab investor sebagai pemilik aset.',
            ),
            _buildSection(
              '6. Transparansi & Monitoring',
              'Investor berhak memantau kondisi aset melalui fitur Live CCTV dan laporan berkala ADG (Average Daily Gain) yang tersedia di dalam aplikasi.',
            ),
            _buildSection(
              '7. Larangan & Keamanan',
              'User dilarang keras melakukan manipulasi data, tindak pidana pencucian uang, atau aktivitas ilegal lainnya yang melanggar hukum Republik Indonesia.',
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Dengan melanjutkan pendaftaran, Anda menyatakan telah membaca, memahami, dan menyetujui seluruh isi perjanjian di atas.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF424242),
            ),
          ),
        ],
      ),
    );
  }
}
