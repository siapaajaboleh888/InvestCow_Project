import 'package:flutter/material.dart';
import '../widgets/cctv_live_player.dart';

class CctvDemoPage extends StatelessWidget {
  const CctvDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InvestCow - Live Monitoring'),
        backgroundColor: Colors.cyan[700],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: const [
          CctvLivePlayer(
            title: "Farm Sanctuary - Area Padang Rumput",
            streamUrl: "https://www.youtube.com/watch?v=1H_80v7OaA8", 
          ),
          SizedBox(height: 10),
          CctvLivePlayer(
            title: "Explore.org - Monitoring Kandang",
            streamUrl: "https://www.youtube.com/watch?v=3_OndKnt6_E", 
          ),

          Padding(
            padding: EdgeInsets.all(24.0),
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.cyan),
                        SizedBox(width: 8),
                        Text('Sistem Monitoring Aktif', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Monitoring ini menggunakan live feed publik dari peternakan global untuk tujuan demonstrasi transparansi InvestCow.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
