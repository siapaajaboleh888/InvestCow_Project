import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_client.dart';

class CctvPage extends StatefulWidget {
  final String? filter;
  const CctvPage({super.key, this.filter});

  @override
  State<CctvPage> createState() => _CctvPageState();
}

class _CctvPageState extends State<CctvPage> {
  final _client = ApiClient();
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
      final res = await http
          .get(uri, headers: _client.jsonHeaders())
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw Exception('Gagal memuat data kandang (${res.statusCode})');
      }
      final data = jsonDecode(res.body) as List;
      if (mounted) {
        setState(() {
          _cows = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
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
        : _cows
            .where((c) => (c['name'] ?? '')
                .toString()
                .toLowerCase()
                .contains(widget.filter!.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        title: Text(widget.filter != null
            ? 'CCTV: ${widget.filter}'
            : 'CCTV Monitoring Sapi'),
        backgroundColor: Colors.cyan[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang',
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
                Expanded(
                  child: Text(
                    widget.filter != null
                        ? 'Hasil Pencarian: ${widget.filter}'
                        : 'Monitoring Kandang – Live Real-Time',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Online',
                    style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.signal_wifi_off,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text('Gagal memuat data: $_error',
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadCows,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: displayCows.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.videocam_off,
                                            size: 64, color: Colors.grey[400]),
                                        const SizedBox(height: 16),
                                        Text(
                                            'Tidak ada data kandang untuk "${widget.filter ?? ''}"'),
                                      ],
                                    ),
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.all(12),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.cyan[50],
                              border: Border(
                                  top: BorderSide(color: Colors.cyan[100]!)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.cyan[800], size: 18),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Feed ini menggunakan siaran publik untuk demonstrasi transparansi monitoring kandang.',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
          _showStreamDialog(cow);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('CCTV tidak tersedia untuk sapi ini')),
          );
        }
      },
      child: Card(
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            imageUrl.startsWith('http')
                                ? imageUrl
                                : '${_client.baseUrl}${imageUrl.startsWith('/') ? '' : '/'}$imageUrl',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.videocam,
                                    color: Colors.white24, size: 40),
                          )
                        : const Center(
                            child: Icon(Icons.videocam,
                                color: Colors.white24, size: 40),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cctvUrl != null && cctvUrl.isNotEmpty
                          ? Colors.red
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle,
                            color: Colors.white,
                            size: 8),
                        const SizedBox(width: 4),
                        Text(
                          cctvUrl != null && cctvUrl.isNotEmpty
                              ? 'LIVE'
                              : 'N/A',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
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
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text('ID: ${cow['ticker_code'] ?? '-'}',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.visibility, color: Colors.cyan[700], size: 14),
                      const SizedBox(width: 4),
                      const Text('Pantau Sapi',
                          style: TextStyle(
                              color: Colors.cyan,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
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

  void _showStreamDialog(Map<String, dynamic> cctv) {
    showDialog(
      context: context,
      builder: (context) => CctvStreamDialog(cow: cctv),
    );
  }
}

// ---------------------------------------------------------------------------
// CctvStreamDialog — dengan auto-reconnect dan error handling yang benar
// ---------------------------------------------------------------------------

class CctvStreamDialog extends StatefulWidget {
  final Map<String, dynamic> cow;
  const CctvStreamDialog({super.key, required this.cow});

  @override
  State<CctvStreamDialog> createState() => _CctvStreamDialogState();
}

enum _PlayerStatus { loading, ready, error, reconnecting }

class _CctvStreamDialogState extends State<CctvStreamDialog> {
  YoutubePlayerController? _ytController;

  _PlayerStatus _status = _PlayerStatus.loading;
  String _statusMessage = 'Menghubungkan ke kandang sapi...';

  // Reconnect state
  int _retryCount = 0;
  static const int _maxRetries = 3;
  Timer? _retryTimer;
  Timer? _timeoutTimer;
  Timer? _bufferingTimer;
  int _retryCountdown = 5;

  String get _videoId {
    final String cctvUrl = widget.cow['cctv_url'] ?? '';
    if (cctvUrl.startsWith('youtube://')) {
      return cctvUrl.replaceFirst('youtube://', '').trim();
    }
    // Support full YouTube URLs
    if (cctvUrl.contains('v=')) {
      return cctvUrl.split('v=').last.split('&').first.trim();
    }
    if (cctvUrl.contains('youtu.be/')) {
      return cctvUrl.split('youtu.be/').last.split('?').first.trim();
    }
    return cctvUrl.trim();
  }

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    final id = _videoId;
    if (id.isEmpty) {
      setState(() {
        _status = _PlayerStatus.error;
        _statusMessage = 'URL CCTV tidak valid atau belum dikonfigurasi.';
      });
      return;
    }

    // Cancel previous resources
    _ytController?.close();
    _ytController = null;
    _timeoutTimer?.cancel();
    _bufferingTimer?.cancel();
    _bufferingTimer = null;

    if (mounted) {
      setState(() {
        _status = _PlayerStatus.loading;
        _statusMessage = _retryCount == 0
            ? 'Menghubungkan ke kandang sapi...'
            : 'Mencoba ulang ke-$_retryCount/$_maxRetries...';
      });
    }

    debugPrint('📺 CCTV init YouTube ID: $id (attempt ${_retryCount + 1})');

    _ytController = YoutubePlayerController.fromVideoId(
      videoId: id,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        enableCaption: false,
        showVideoAnnotations: false,
        strictRelatedVideos: true,
        // Tanpa origin agar tidak ada CORS block di perangkat nyata
      ),
    );

    // Listen player state untuk deteksi error dengan benar
    _ytController!.listen((state) {
      if (!mounted) return;

      // Deteksi error berdasarkan playerState dan error code
      final hasError = state.error != YoutubeError.none;
      if (hasError && _status != _PlayerStatus.error) {
        debugPrint('❌ CCTV YouTube error: ${state.error}');
        _handlePlaybackError('YouTube error: ${state.error.name}');
        return;
      }

      // Deteksi buffering terhenti (watchdog)
      if (state.playerState == PlayerState.buffering) {
        if (_bufferingTimer == null || !_bufferingTimer!.isActive) {
          debugPrint('⏱ CCTV buffering detected, starting 15s watchdog...');
          _bufferingTimer = Timer(const Duration(seconds: 15), () {
            if (mounted && _status == _PlayerStatus.ready) {
              debugPrint('⏱ CCTV buffering watchdog fired after 15 seconds');
              _handlePlaybackError('Koneksi tidak stabil / buffering terhenti');
            }
          });
        }
      } else if (state.playerState == PlayerState.playing) {
        _bufferingTimer?.cancel();
        _bufferingTimer = null;

        if (_status == _PlayerStatus.loading) {
          _timeoutTimer?.cancel();
          if (mounted) {
            setState(() {
              _status = _PlayerStatus.ready;
              _retryCount = 0; // reset retry setelah berhasil
            });
          }
        }
      } else if (state.playerState == PlayerState.paused) {
        _bufferingTimer?.cancel();
        _bufferingTimer = null;
      }
    });

    // Timeout 20 detik — jika tidak playing, anggap gagal
    _timeoutTimer = Timer(const Duration(seconds: 20), () {
      if (mounted && _status == _PlayerStatus.loading) {
        debugPrint('⏱ CCTV timeout setelah 20 detik');
        _handlePlaybackError('Waktu koneksi habis (timeout)');
      }
    });

    // Mark as ready to show player (player iframe sudah terpasang)
    // Status tetap loading sampai player benar-benar playing atau error
    if (mounted) setState(() {});
  }

  void _handlePlaybackError(String reason) {
    _timeoutTimer?.cancel();
    _retryTimer?.cancel();

    if (_retryCount < _maxRetries) {
      _retryCount++;
      _retryCountdown = 5;

      if (mounted) {
        setState(() {
          _status = _PlayerStatus.reconnecting;
          _statusMessage = 'Koneksi terputus. Mencoba ulang ke-$_retryCount/$_maxRetries dalam $_retryCountdown detik...';
        });
      }

      // Countdown timer
      _retryTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        _retryCountdown--;
        if (_retryCountdown <= 0) {
          t.cancel();
          _initPlayer();
        } else {
          setState(() {
            _statusMessage = 'Mencoba ulang ke-$_retryCount/$_maxRetries dalam $_retryCountdown detik...';
          });
        }
      });
    } else {
      // Semua retry habis
      if (mounted) {
        setState(() {
          _status = _PlayerStatus.error;
          _statusMessage = 'Gagal terhubung setelah $_maxRetries percobaan.\nYouTube mungkin membatasi playback di perangkat ini.';
        });
      }
    }
  }

  void _manualRetry() {
    _retryCount = 0;
    _retryTimer?.cancel();
    _timeoutTimer?.cancel();
    _initPlayer();
  }

  Future<void> _openInYouTube() async {
    final id = _videoId;
    final uri = Uri.parse('https://www.youtube.com/watch?v=$id');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('❌ Gagal buka YouTube: $e');
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _timeoutTimer?.cancel();
    _bufferingTimer?.cancel();
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
            actions: [
              // Tombol buka di YouTube selalu tersedia
              IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: 'Buka di YouTube',
                onPressed: _openInYouTube,
              ),
            ],
          ),
          Expanded(
            child: _buildBody(),
          ),
          // Status bar bawah
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _status == _PlayerStatus.ready
                      ? Icons.check_circle_outline
                      : _status == _PlayerStatus.error
                          ? Icons.error_outline
                          : Icons.sync,
                  color: _status == _PlayerStatus.ready
                      ? Colors.green
                      : _status == _PlayerStatus.error
                          ? Colors.redAccent
                          : Colors.orangeAccent,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _status == _PlayerStatus.ready
                        ? 'Streaming aktif — ${widget.cow['ticker_code']}'
                        : _statusMessage,
                    style: TextStyle(
                      color: _status == _PlayerStatus.ready
                          ? Colors.white70
                          : Colors.orangeAccent,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _PlayerStatus.loading:
        return Stack(
          children: [
            // Tampilkan player di balik loading agar cepat siap
            if (_ytController != null)
              Opacity(
                opacity: 0.0,
                child: _buildYoutubePlayer(),
              ),
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.cyan),
                  SizedBox(height: 16),
                  Text('Menghubungkan ke kandang sapi...',
                      style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 8),
                  Text('Memuat stream YouTube...',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          ],
        );

      case _PlayerStatus.ready:
        return _buildYoutubePlayer();

      case _PlayerStatus.reconnecting:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sync, color: Colors.orangeAccent, size: 56),
              const SizedBox(height: 16),
              const Text('Koneksi Terputus',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(_statusMessage,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _manualRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Sekarang'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        );

      case _PlayerStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.signal_wifi_connected_no_internet_4_rounded,
                    color: Colors.redAccent, size: 64),
                const SizedBox(height: 16),
                const Text('Stream Tidak Tersedia',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(_statusMessage,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 13),
                    textAlign: TextAlign.center),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _manualRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan[700],
                          foregroundColor: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    if (!kIsWeb)
                      ElevatedButton.icon(
                        onPressed: _openInYouTube,
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text('Buka di YouTube'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildYoutubePlayer() {
    if (_ytController == null) return const SizedBox.shrink();
    return YoutubePlayerScaffold(
      controller: _ytController!,
      aspectRatio: 16 / 9,
      builder: (context, player) => player,
    );
  }
}
