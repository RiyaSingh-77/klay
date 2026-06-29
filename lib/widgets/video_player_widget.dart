import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

// VideoPlayerWidget wraps a single VideoPlayerController for ONE video
// URL. Each FeedPostCard that shows a video gets its own instance — the
// controller is created in initState and disposed in dispose, so
// scrolling a long feed never leaks players for videos that have
// scrolled off-screen and been rebuilt away.
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      // setState is guarded by `mounted` because initialize() is async —
      // if the user scrolls this card off-screen and it gets disposed
      // before the network response lands, calling setState on a
      // disposed State would throw.
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  void _togglePlayback() {
    if (!_isInitialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: AppTheme.surface,
        child: const Center(
          child: Icon(Icons.error_outline, color: AppTheme.textMuted, size: 32),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: AppTheme.surface,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlayback,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          // FittedBox + SizedBox at the controller's native aspect ratio
          // is what lets a video of ANY aspect ratio fill this widget's
          // bounds via BoxFit.cover-equivalent behavior — VideoPlayer
          // itself has no fit parameter the way Image does.
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
          // Play icon only shows when paused — fades out the instant
          // playback starts, same convention as Instagram/TikTok feeds.
          if (!_controller.value.isPlaying)
            Container(
              decoration: const BoxDecoration(
                color: Colors.black26,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
            ),
        ],
      ),
    );
  }
}