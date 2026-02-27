import 'package:flutter/material.dart';
import 'cctv_page.dart';

class DetailKandangPage extends StatelessWidget {
  final Map<String, dynamic> barn;
  
  const DetailKandangPage({super.key, required this.barn});

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
                image: barn['image_url'] != null 
                  ? DecorationImage(
                      image: NetworkImage(barn['image_url']),
                      fit: BoxFit.cover,
                    )
                  : null,
              ),
              child: barn['image_url'] == null 
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            barn['name'],
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Kode: ${barn['ticker']}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
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
                      onTap: () {
                        // Launch CCTV Dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => CctvStreamDialog(cow: {
                            'name': barn['name'],
                            'ticker_code': barn['ticker'],
                            'cctv_url': barn['cctv_url'],
                          }),
                        );
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
}
