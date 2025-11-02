import 'package:flutter/material.dart';
import 'kas_page.dart';
import 'pasar_page.dart';
import 'kesehatan_page.dart';
import 'penjualan_page.dart';
import 'kandang_page.dart';
import 'pembayaran_page.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.cyan[400],
        foregroundColor: Colors.white,
        title: const Text(
          'Menu InvestCow',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0), // Dikurangi dari 16 ke 12
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12, // Dikurangi dari 16 ke 12
          mainAxisSpacing: 12, // Dikurangi dari 16 ke 12
          childAspectRatio: 1.1, // Ditambahkan agar tidak terlalu tinggi
          children: [
            MenuCard(
              icon: Icons.account_balance_wallet,
              title: 'Kas',
              color: Colors.green[400]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const KasPage()),
                );
              },
            ),
            MenuCard(
              icon: Icons.shopping_cart,
              title: 'Pasar',
              color: Colors.blue[400]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PasarPage()),
                );
              },
            ),
            MenuCard(
              icon: Icons.medical_services,
              title: 'Kesehatan',
              color: Colors.red[400]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const KesehatanPage(),
                  ),
                );
              },
            ),
            MenuCard(
              icon: Icons.trending_up,
              title: 'Penjualan',
              color: Colors.orange[400]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PenjualanPage(),
                  ),
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
              icon: Icons.credit_card,
              title: 'Pembayaran',
              color: Colors.purple[400]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PembayaranPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
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
