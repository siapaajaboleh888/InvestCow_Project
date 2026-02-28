import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class CctvPage extends StatefulWidget {
  final String? filter;
  const CctvPage({super.key, this.filter});

  @override
  State<CctvPage> createState() => _CctvPageState();
}

class _CctvPageState extends State<CctvPage> {
  final _client = ApiClient();
  final _authService = AuthService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _cows = [];

  @override
  void initState() {
    super.initState();
    _loadCows();
  }

  Future<void> _loadCows() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = _client.uri('/admin/products-public');
      final res = await http.get(uri, headers: _client.jsonHeaders());
      if (res.statusCode != 200) {
        throw Exception('Gagal memuat data kandang (${res.statusCode})');
      }
      final data = jsonDecode(res.body) as List;
      setState(() {
        _cows = data.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayCows = widget.filter == null 
        ? _cows 
        : _cows.where((c) => (c['name'] ?? '').toString().toLowerCase().contains(widget.filter!.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        title: Text(widget.filter != null ? 'CCTV: ${widget.filter}' : 'CCTV Monitoring Sapi'),
        backgroundColor: Colors.cyan[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCows,
          ),
        ],
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
                Text(
                  widget.filter != null ? 'Hasil Pencarian: ${widget.filter}' : 'Monitoring Kandang - Live Real-Time',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : displayCows.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.videocam_off, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text('Tidak ada data kandang untuk "${widget.filter ?? ''}"'),
                                if (widget.filter != null) ...[
                                  const SizedBox(height: 16),
                                  TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CctvPage())), child: const Text('Lihat Semua Kandang'))
                                ]
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: displayCows.length,
                            itemBuilder: (context, index) {
                              final cow = displayCows[index];
                              return _buildCctvCard(context, cow);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCctvCard(BuildContext context, Map<String, dynamic> cow) {
    final imageUrl = cow['image_url']?.toString();
    final cctvUrl = cow['cctv_url']?.toString();

    return GestureDetector(
      onTap: () {
        if (cctvUrl != null && cctvUrl.isNotEmpty) {
          _showLiveStream(context, cow);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CCTV tidak tersedia untuk sapi ini')),
          );
        }
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.black87,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl.startsWith('http') ? imageUrl : '${_client.baseUrl}$imageUrl',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.videocam, color: Colors.white24, size: 40),
                          )
                        : const Center(
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
                  Text(
                    cow['name'] ?? 'Unnamed',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text('ID: ${cow['ticker_code'] ?? '-'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.visibility, color: Colors.cyan[700], size: 14),
                      const SizedBox(width: 4),
                      const Text('Pantau Sapi', style: TextStyle(color: Colors.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
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

  void _showLiveStream(BuildContext context, Map<String, dynamic> cow) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CctvStreamDialog(cow: cow),
    );
  }
}

class CctvStreamDialog extends StatefulWidget {
  final Map<String, dynamic> cow;
  const CctvStreamDialog({super.key, required this.cow});

  @override
  State<CctvStreamDialog> createState() => _CctvStreamDialogState();
}

class _CctvStreamDialogState extends State<CctvStreamDialog> {
  // Common Video Player
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  
  // YouTube Player
  YoutubePlayerController? _ytController;
  
  bool _initialized = false;
  String? _error;
  bool _isYoutube = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final String cctvUrl = widget.cow['cctv_url'] ?? '';
    if (cctvUrl.isEmpty) {
      setState(() => _error = 'URL CCTV tidak ditemukan');
      return;
    }

    if (cctvUrl.startsWith('youtube://')) {
      _isYoutube = true;
      final videoId = cctvUrl.replaceFirst('youtube://', '');
      debugPrint('📺 CCTV Loading YouTube ID: $videoId');
      
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
          // origin: 'http://localhost',
          strictRelatedVideos: false,
        ),

      );
      
      // For Web, we sometimes need to wait for initialization or use a specific origin
      setState(() => _initialized = true);
    } else {
      _isYoutube = false;
      debugPrint('📺 CCTV Loading HLS/MP4 URL: $cctvUrl');
      try {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(cctvUrl));
        await _videoPlayerController!.initialize();
        
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: true,
          isLive: true,
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          allowFullScreen: true,
          placeholder: Container(color: Colors.black),
          errorBuilder: (context, errorMessage) {
            debugPrint('❌ CCTV Error in Chewie: $errorMessage');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.orange, size: 42),
                  const SizedBox(height: 8),
                  Text(
                    'Gagal memuat stream: $errorMessage',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
        
        setState(() => _initialized = true);
      } catch (e) {
        debugPrint('❌ CCTV Catch Error: $e');
        setState(() => _error = 'Gagal menghubungkan ke CCTV: $e');
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _ytController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.black54,
            foregroundColor: Colors.white,
            title: Text('Live CCTV: ${widget.cow['name']}'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: Center(
              child: _error != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Tutup'),
                        )
                      ],
                    )
                  : _initialized
                      ? _buildPlayer()
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.cyan),
                            SizedBox(height: 16),
                            Text('Menghubungkan ke Kandang Sapi...', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, color: Colors.cyan, size: 16),
                const SizedBox(width: 8),
                Text(
                  'ID Produk: ${widget.cow['ticker_code']}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Kandang Terverifikasi',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    if (_isYoutube) {
      return YoutubePlayer(
        key: ValueKey(widget.cow['ticker_code']),
        controller: _ytController!,
        aspectRatio: 16 / 9,
      );
    } else {
      return AspectRatio(
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      );
    }
  }
}


