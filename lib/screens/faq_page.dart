import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
        backgroundColor: Colors.cyan[400],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'Pertanyaan yang Sering Diajukan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          _buildFAQItem(
            context,
            question: 'Bagaimana cara mendaftar akun?',
            answer:
                'Untuk mendaftar akun, klik tombol "Daftar" di halaman login, kemudian isi formulir pendaftaran dengan data yang valid seperti nama, email, dan password.',
          ),

          _buildFAQItem(
            context,
            question: 'Bagaimana cara reset password?',
            answer:
                'Jika lupa password, klik "Lupa Password" di halaman login, masukkan email terdaftar Anda, dan ikuti instruksi yang dikirimkan ke email Anda.',
          ),

          _buildFAQItem(
            context,
            question: 'Apakah aplikasi ini gratis?',
            answer:
                'Ya, aplikasi ini gratis untuk digunakan. Namun beberapa fitur premium mungkin memerlukan pembayaran.',
          ),

          _buildFAQItem(
            context,
            question: 'Bagaimana cara mengubah profil?',
            answer:
                'Buka halaman Akun, klik "Edit Profil" atau masuk ke menu "Profil", lalu klik ikon edit pada informasi yang ingin diubah.',
          ),

          _buildFAQItem(
            context,
            question: 'Bagaimana cara menghubungi customer service?',
            answer:
                'Anda dapat menghubungi customer service melalui email di support@example.com atau melalui WhatsApp di +62 812 3456 7890.',
          ),

          _buildFAQItem(
            context,
            question: 'Apakah data saya aman?',
            answer:
                'Ya, kami sangat menjaga keamanan data Anda. Semua data dienkripsi dan disimpan dengan sistem keamanan tingkat tinggi sesuai standar internasional.',
          ),

          _buildFAQItem(
            context,
            question: 'Bagaimana cara menghapus akun?',
            answer:
                'Untuk menghapus akun, silakan hubungi customer service kami. Perlu diingat bahwa penghapusan akun bersifat permanen dan tidak dapat dibatalkan.',
          ),

          _buildFAQItem(
            context,
            question:
                'Aplikasi tidak berfungsi dengan baik, apa yang harus dilakukan?',
            answer:
                'Coba untuk logout kemudian login kembali, atau hapus cache aplikasi di menu Pengaturan. Jika masalah berlanjut, silakan hubungi customer service kami.',
          ),

          const SizedBox(height: 30),

          // Contact Support Button
          Card(
            color: Colors.cyan[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.help_outline, size: 50, color: Colors.cyan[400]),
                  const SizedBox(height: 10),
                  const Text(
                    'Masih ada pertanyaan?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hubungi tim support kami untuk bantuan lebih lanjut',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Menghubungi Support...')),
                      );
                    },
                    icon: const Icon(Icons.email),
                    label: const Text('Hubungi Support'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
