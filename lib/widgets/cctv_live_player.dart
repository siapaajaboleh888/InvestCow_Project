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

  @override
  void initState() {
    super.initState();
    
    // Ambil ID Video dari URL
    String videoId = "R9jV6_kOk9Y"; // Default
    if (widget.streamUrl.contains("v=")) {
      videoId = widget.streamUrl.split("v=").last.split("&").first;
    } else if (widget.streamUrl.contains("youtu.be/")) {
      videoId = widget.streamUrl.split("youtu.be/").last.split("?").first;
    }

    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        mute: true,
        showFullscreenButton: true,
        // Biarkan kosong agar library menyesuaikan dengan domain saat ini secara otomatis
        // origin: 'http://localhost',
      ),

    );
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
              Text(
                widget.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              const Badge(
                label: Text('LIVE'),
                backgroundColor: Colors.red,
              ),
            ],
          ),
        ),
        // Container dengan Aspect Ratio untuk IFrame
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: YoutubePlayer(
              controller: _controller,
              aspectRatio: 16 / 9,
            ),
          ),
        ),
      ],
    );
  }
}
