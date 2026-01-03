import 'package:flutter/material.dart';
import 'menu_page.dart'; // Import halaman menu

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.cyan[400],
        foregroundColor: Colors.white,
        title: const Text(
          'InvestCow',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MenuPage(),
                            ),
                          );
                        },
                        child: const InvestCowIcon(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'InvestCow',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        '"Investasi masa depanku"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Pengetahuan sapi dan investasi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      '1. Dasar-dasar Peternakan Sapi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Peternakan sapi adalah usaha budidaya ternak sapi untuk tujuan daging, susu, ataupun pembibitan. Hal penting yang perlu diperhatikan antara lain kualitas pakan, kebersihan kandang, kesehatan ternak, dan manajemen keuangan. Peternak yang baik selalu mencatat pemasukan dan pengeluaran sehingga tahu keuntungan setiap periode pemeliharaan.',
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '2. Jenis-jenis Sapi Populer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Sapi Brahman – Daya tahan tinggi terhadap iklim tropis, memiliki punuk dan gelambir khas.\n'
                      '• Sapi Bali – Sapi asli Indonesia dengan kualitas daging yang sangat baik dan rendah lemak.\n'
                      '• Sapi Madura – Sapi pekerja yang tangguh dengan daging empuk dan gurih.\n'
                      '• Sapi Limousin – Sapi asal Perancis dengan pertumbuhan otot sangat cepat dan karkas tinggi.\n'
                      '• Sapi Angus – Kualitas premium, sangat dicari untuk steak dan olahan daging mewah.',
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '3. Faktor yang Mempengaruhi Harga Sapi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Harga sapi ditentukan oleh beberapa faktor:\n'
                      '• Bobot badan (kg hidup)\n'
                      '• Usia sapi (pedet, bakalan, siap potong)\n'
                      '• Jenis dan kualitas genetik\n'
                      '• Kondisi tubuh (sehat, gemuk, bebas cacat)\n'
                      '• Musim (misalnya menjelang Idul Adha harga cenderung naik).',
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '4. Kisaran Harga Sapi (Gambaran Umum)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Harga berikut hanya kisaran umum dan dapat berbeda di setiap daerah:\n'
                      '• Pedet (anak sapi) lokal: sekitar Rp 8.000.000 – Rp 12.000.000 per ekor.\n'
                      '• Bakalan sapi potong 250–300 kg: sekitar Rp 18.000.000 – Rp 28.000.000.\n'
                      '• Sapi premium untuk kurban (Limosin/Simental besar): bisa mencapai Rp 35.000.000 ke atas per ekor.\n'
                      'Selalu lakukan pengecekan langsung ke pasar hewan atau peternak terpercaya sebelum transaksi.',
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '5. Tips Dasar untuk Calon Investor Sapi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Pilih mitra peternak yang transparan dan memiliki catatan usaha yang jelas.\n'
                      '• Pahami risiko usaha ternak: penyakit, fluktuasi harga pakan, dan harga jual.\n'
                      '• Mulai dengan jumlah ekor yang sesuai dengan kemampuan modal.\n'
                      '• Catat setiap transaksi, termasuk biaya pakan, obat, tenaga kerja, dan hasil penjualan.\n'
                      '• Diversifikasi: jangan hanya bergantung pada satu jenis sapi atau satu jenis usaha saja.',
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Untuk melihat produk sapi yang siap diinvestasikan, buka menu Pasar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InvestCowIcon extends StatelessWidget {
  const InvestCowIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF00BCD4), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
            ),
          ),
          // Trend up line
          Icon(
            Icons.trending_up,
            color: Colors.white,
            size: 54,
          ),
          // Small dot accent (represents price point)
          Positioned(
            right: 34,
            top: 38,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
