import 'package:flutter/material.dart';
import 'kas_page.dart';
import 'kesehatan_page.dart';
import 'kandang_page.dart';
import 'cctv_page.dart';
import 'transaksi_page.dart';
import 'pasar_page.dart';
import '../main.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: Colors.cyan[400],
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Tooltip(
          message: 'Back',
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Menu InvestCow',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: const Text(
              'Pilih fitur untuk mengelola investasi sapi Anda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0), // Dikurangi dari 16 ke 12
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12, // Dikurangi dari 16 ke 12
                mainAxisSpacing: 12, // Dikurangi dari 16 ke 12
                childAspectRatio: 1.05, // Sedikit lebih lebar
                children: [
                  MenuCard(
                    icon: Icons.health_and_safety,
                    title: 'Kesehatan',
                    color: Colors.red[400]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const KesehatanPage()),
                      );
                    },
                  ),
                  MenuCard(
                    icon: Icons.history_edu,
                    title: 'Transaksi',
                    color: Colors.orange[400]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TransaksiPage()),
                      );
                    },
                  ),
                  MenuCard(
                    icon: Icons.pets,
                    title: 'Kandang',
                    color: Colors.brown[400]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const KandangPage()),
                      );
                    },
                  ),
                  MenuCard(
                    icon: Icons.videocam,
                    title: 'CCTV Sapi',
                    color: Colors.purple[400]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CctvPage()),
                      );
                    },
                  ),
                  MenuCard(
                    icon: Icons.storefront,
                    title: 'Pasar Sapi',
                    color: Colors.teal[400]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PasarPage()),
                      );
                    },
                  ),
                  MenuCard(
                    icon: Icons.account_balance_wallet,
                    title: 'Kas Sapi',
                    color: Colors.cyan[600]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const KasPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.cyan[600],
        unselectedItemColor: Colors.grey[500],
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          // Pindah ke MainScreen dengan tab sesuai index
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(initialIndex: index),
            ),
            (route) => false,
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Pasar Modal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Kunjungan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
        ],
      ),
    );
  }
}

class MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(color.red, color.green, color.blue, 0.1),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60, // Dikurangi dari 70 ke 60
                height: 60, // Dikurangi dari 70 ke 60
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(
                        color.red,
                        color.green,
                        color.blue,
                        0.4,
                      ),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 30,
                ), // Dikurangi dari 35 ke 30
              ),
              const SizedBox(height: 10), // Dikurangi dari 12 ke 10
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15, // Dikurangi dari 16 ke 15
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
