import 'package:flutter/material.dart';
import 'dart:async';

class CctvPage extends StatefulWidget {
  const CctvPage({super.key});

  @override
  State<CctvPage> createState() => _CctvPageState();
}

class _CctvPageState extends State<CctvPage> {
  final List<Map<String, String>> _cows = [
    {'name': 'Brahman A1', 'id': 'C-101', 'image': 'assets/images/sapi_brahman.jpg'},
    {'name': 'Limosin Premium', 'id': 'C-203', 'image': 'assets/images/sapi_limousin.jpg'},
    {'name': 'Bali X', 'id': 'C-305', 'image': 'assets/images/sapi_bali.jpg'},
    {'name': 'Simental S1', 'id': 'C-402', 'image': 'assets/images/sapi_madura.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        title: const Text('CCTV Monitoring Sapi'),
        backgroundColor: Colors.cyan[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Icon(Icons.live_tv, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Monitoring Kandang - Live 24/7',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Online',
                    style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _cows.length,
              itemBuilder: (context, index) {
                final cow = _cows[index];
                return _buildCctvCard(context, cow);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCctvCard(BuildContext context, Map<String, String> cow) {
    return GestureDetector(
      onTap: () => _showLiveStream(context, cow),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Placeholder image for video stream
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.black87,
                    child: const Center(
                      child: Icon(Icons.videocam, color: Colors.white24, size: 40),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 8),
                        SizedBox(width: 4),
                        Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cow['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('ID: ${cow['id']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.visibility, color: Colors.cyan[700], size: 14),
                      const SizedBox(width: 4),
                      const Text('Lihat Kondisi', style: TextStyle(color: Colors.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLiveStream(BuildContext context, Map<String, String> cow) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Container(
          color: Colors.black,
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                title: Text('CCTV ${cow['name']}'),
              ),
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // In real app, use video_player or flutter_vlc_player
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.red),
                          SizedBox(height: 16),
                          Text('Menghubungkan ke Kamera...', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                      Positioned(
                        bottom: 40,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.mic_off, color: Colors.white, size: 20),
                              SizedBox(width: 16),
                              Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              SizedBox(width: 16),
                              Icon(Icons.fullscreen, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
