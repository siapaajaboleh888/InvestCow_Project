import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cctv_page.dart';
import '../services/api_client.dart';

class DetailKandangPage extends StatelessWidget {
  final Map<String, dynamic> barn;
  final ApiClient _client = ApiClient();
  
  DetailKandangPage({super.key, required this.barn});

  @override
  Widget build(BuildContext context) {
    final double occ = double.tryParse(barn['occupied'].toString()) ?? 0.0;
    final double price = double.tryParse(barn['price'].toString()) ?? 0;
    final double totalValue = occ * price;
    final String formattedValue = totalValue.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Detail Kandang ${barn['name']}'),
        backgroundColor: Colors.brown[400],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Image/Icon
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.brown[100],
                image: barn['image_url'] != null && barn['image_url'].toString().isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(
                        barn['image_url'].toString().startsWith('http') 
                          ? barn['image_url'] 
                          : '${_client.baseUrl}${barn['image_url'].toString().startsWith('/') ? '' : '/'}${barn['image_url']}'
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
              ),
              child: (barn['image_url'] == null || barn['image_url'].toString().isEmpty)
                ? Icon(Icons.pets, size: 100, color: Colors.brown[300])
                : null,
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildGradeChip(barn),
                            const SizedBox(height: 8),
                            Text(
                              barn['name'],
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            Text(
                              'Kode: ${barn['ticker']}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              occ % 1 == 0 ? occ.toInt().toString() : occ.toStringAsFixed(2),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            const Text('Ekor', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      )
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  const Text('Ringkasan Aset', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  _buildStatCard(
                    icon: Icons.monetization_on,
                    title: 'Estimasi Nilai Total',
                    value: 'Rp $formattedValue',
                    color: Colors.blue,
                  ),
                  
                  _buildStatCard(
                    icon: Icons.monitor_weight,
                    title: 'Rata-rata Bobot',
                    value: '${barn['weight'] ?? 350} kg',
                    color: Colors.orange,
                  ),
                  
                  _buildStatCard(
                    icon: Icons.analytics,
                    title: 'Status Pertumbuhan',
                    value: '+${barn['growth'] ?? '1.2'}% / hari',
                    color: Colors.purple,
                  ),
                  
                  _buildStatCard(
                    icon: Icons.health_and_safety,
                    title: 'Status Kesehatan',
                    value: (barn['health'] ?? 100) >= 90 ? 'Sehat' : 'Perawatan',
                    subtitle: 'Skor Kesehatan: ${barn['health'] ?? 100}/100',
                    color: (barn['health'] ?? 100) >= 90 ? Colors.green : Colors.orange,
                  ),
                  
                  const SizedBox(height: 24),
                  const Text('Pemantauan Fisik', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        child: Icon(Icons.live_tv, color: Colors.white, size: 20),
                      ),
                      title: const Text('Live CCTV Kandang'),
                      subtitle: const Text('Lihat kondisi sapi secara real-time'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final String? cctvUrl = barn['cctv_url']?.toString();
                        if (cctvUrl == null || cctvUrl.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('CCTV tidak tersedia untuk kandang ini')),
                          );
                          return;
                        }

                        if (kIsWeb) {
                          showDialog(
                            context: context,
                            builder: (context) => CctvStreamDialog(cow: {
                              'name': barn['name'],
                              'ticker_code': barn['ticker'],
                              'cctv_url': barn['cctv_url'],
                            }),
                          );
                        } else {
                          // Buka langsung di mobile dengan inAppBrowserView
                          String finalUrl = cctvUrl;
                          if (cctvUrl.startsWith('youtube://')) {
                            final id = cctvUrl.replaceFirst('youtube://', '');
                            finalUrl = 'https://www.youtube.com/watch?v=$id';
                          }
                          final uri = Uri.parse(finalUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                          }
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 80), // Spacer
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown[400],
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Tutup Detail'),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon, 
    required String title, 
    required String value, 
    required Color color,
    String? subtitle,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (subtitle != null)
                    Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGradeChip(Map<String, dynamic> barn) {
    // Parameter Penilaian (Harga adalah harga 1 ekor utuh)
    final double price = double.tryParse(barn['price'].toString()) ?? 0;
    
    // Jika data dari API kosong, berikan default yang "standar" (Grade B/C), bukan sempurna
    final double weight = double.tryParse(barn['weight'].toString()) ?? 280; // Default 280kg
    final double health = double.tryParse(barn['health'].toString()) ?? 85;  // Default sehat normal
    final double age = double.tryParse(barn['age'].toString()) ?? 12;        // Default masih muda

    // Kalkulasi Skor Penilaian (Maksimal Poin: 10)
    int score = 0;
    
    // 1. Indikator Bobot
    if (weight >= 450) score += 3;
    else if (weight >= 350) score += 2;
    else score += 1;

    // 2. Indikator Kesehatan
    if (health >= 95) score += 3;
    else if (health >= 85) score += 2;
    else score += 1;

    // 3. Indikator Nilai Aset (Harga Per Ekor Asli)
    if (price >= 35000000) score += 3;
    else if (price >= 20000000) score += 2;
    else score += 1;

    // 4. Indikator Umur Produktif (Panen ideal: 18 - 36 bulan)
    if (age >= 18 && age <= 36) score += 1;

    // Penentuan Grade Akhir
    String grade = 'C';
    String desc = 'Sapi Bakalan (Standar)';
    Color bgColor = Colors.grey[200]!;
    Color textColor = Colors.grey[800]!;
    IconData icon = Icons.info_outline;

    if (score >= 9) { // Syarat ketat: Harus skor 9 atau 10
      grade = 'A';
      desc = 'Premium (Siap Panen)';
      bgColor = Colors.amber[100]!;
      textColor = Colors.amber[900]!;
      icon = Icons.workspace_premium;
    } else if (score >= 6) { // Skor 6, 7, 8
      grade = 'B';
      desc = 'Kualitas Sangat Baik';
      bgColor = Colors.blue[100]!;
      textColor = Colors.blue[900]!;
      icon = Icons.verified;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            'Grade $grade - $desc',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
