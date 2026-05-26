import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsDetailPage extends StatelessWidget {
  final Map<String, dynamic> news;

  const NewsDetailPage({super.key, required this.news});

  /// Cek apakah URL berasal dari domain internal investcow.id
  /// (domain ini belum live, jadi tidak perlu dibuka di browser)
  bool _isInternalUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.contains('investcow.id');
    } catch (_) {
      return false;
    }
  }

  Future<void> _openUrl(BuildContext context, String urlStr) async {
    // Jika URL internal investcow.id, kontennya sudah ditampilkan di app
    if (_isInternalUrl(urlStr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konten ini eksklusif dari InvestCow dan sudah ditampilkan di halaman ini.'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(urlStr);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
      if (!launched && context.mounted) {
        // Fallback ke external application jika inAppBrowserView gagal
        final launchedExternal = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launchedExternal && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak dapat membuka: $urlStr'),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuka tautan berita. Periksa koneksi internet Anda.'),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = news['logoColor'] != null
        ? Color(int.parse(news['logoColor'].toString().replaceFirst('#', '0xFF')))
        : const Color(0xFF2196F3);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Professional Source Branding Header (Image 4/5 Style)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          news['logo'] ?? 'N',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  news['source'] ?? 'Portal Berita',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: const Text(
                                    '+ Ikuti',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '7.4K Pengikut',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.ios_share, color: Colors.grey, size: 20),
                    ],
                  ),
                ),
                const Divider(),
                const SizedBox(height: 12),
    
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        news['title'] ?? 'Judul Berita',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          letterSpacing: -0.5,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Date and Time
                      Text(
                        '${news['time']} · ${news['date']}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      // Main Content (High Density)
                      Text(
                        news['content'] ?? 'Isi berita tidak tersedia.',
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.7,
                          color: Color(0xFF333333),
                        ),
                      ),
                      
                      // Internal Action (selengkapnya)
                      if (news['internalAction'] != null) ...[
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: news['internalAction'] as VoidCallback,
                          child: Text(
                            '(Selengkapnya...)',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                      // Action Button to Source — hanya tampil jika bukan URL internal
                      if (news['url'] != null && !_isInternalUrl(news['url'].toString()))
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: () => _openUrl(context, news['url'].toString()),
                            icon: const Icon(Icons.open_in_browser, size: 18),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            label: const Text('Baca Selengkapnya di Sumber Asli'),
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                const Divider(),
                const SizedBox(height: 20),
                // Footer/CTA
                const Center(
                  child: Text(
                    '© 2026 InvestCow. Berita Terpercaya Industri Peternakan.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
