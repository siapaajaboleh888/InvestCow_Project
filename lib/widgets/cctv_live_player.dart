import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class CctvLivePlayer extends StatefulWidget {
  final String streamUrl;
  final String title;

  const CctvLivePlayer({
    super.key,
    required this.streamUrl,
    required this.title,
  });

  @override
  State<CctvLivePlayer> createState() => _CctvLivePlayerState();
}

class _CctvLivePlayerState extends State<CctvLivePlayer> {
  late YoutubePlayerController _controller;

  String _extractVideoId(String url) {
    if (url.contains('v=')) {
      return url.split('v=').last.split('&').first.trim();
    }
    if (url.contains('youtu.be/')) {
      return url.split('youtu.be/').last.split('?').first.trim();
    }
    // Default fallback – livestream sapi kandang demo
    return 'R9jV6_kOk9Y';
  }

  @override
  void initState() {
    super.initState();
    final videoId = _extractVideoId(widget.streamUrl);
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        mute: true,
        showFullscreenButton: true,
        showVideoAnnotations: false,
        strictRelatedVideos: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close(); // ✅ Penting: tutup controller agar tidak memory leak
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              const Icon(Icons.videocam, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Badge(
                label: Text('LIVE'),
                backgroundColor: Colors.red,
              ),
            ],
          ),
        ),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: YoutubePlayerScaffold(
              controller: _controller,
              aspectRatio: 16 / 9,
              builder: (context, player) => player,
            ),
          ),
        ),
      ],
    );
  }
}
