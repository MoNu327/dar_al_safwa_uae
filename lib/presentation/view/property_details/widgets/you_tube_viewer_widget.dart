import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../view_model/video_controller.dart';

class OptimizedYoutubePlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final double aspectRatio;

  const OptimizedYoutubePlayer({
    Key? key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.aspectRatio = 16 / 9,
  }) : super(key: key);

  @override
  State<OptimizedYoutubePlayer> createState() => _OptimizedYoutubePlayerState();
}

class _OptimizedYoutubePlayerState extends State<OptimizedYoutubePlayer>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  VideoController? _controller;
  String? _currentVideoId;
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true; // Keep widget alive when switching tabs

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeController();
  }

  @override
  void didUpdateWidget(OptimizedYoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reinitialize if video URL changed
    if (oldWidget.videoUrl != widget.videoUrl) {
      _initializeController();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_controller != null && _isInitialized) {
      switch (state) {
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
          _controller!.pauseVideo();
          break;
        case AppLifecycleState.resumed:
          // Don't auto-resume, let user control playback
          break;
        case AppLifecycleState.detached:
          _controller!.pauseVideo();
          break;
        case AppLifecycleState.hidden:
          _controller!.pauseVideo();
          break;
      }
    }
  }

  void _initializeController() {
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

    // Skip if same video is already initialized
    if (_currentVideoId == videoId && _isInitialized && _controller != null) {
      return;
    }

    _currentVideoId = videoId;

    // Get or create controller
    try {
      _controller = Get.find<VideoController>();
    } catch (e) {
      _controller = Get.put(VideoController(), permanent: true);
    }

    if (videoId != null && videoId.isNotEmpty) {
      _controller!.initializePlayer(widget.videoUrl);
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_controller == null) {
      return _buildThumbnailFallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(Get.width * 0.04),
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Get.width * 0.04),
            color: Colors.black12,
          ),
          child: Obx(() {
            if (_controller!.hasError) {
              return _buildErrorState(_controller!.errorMessage, _controller!);
            }

            if (_controller!.isLoading) {
              return _buildLoadingState();
            }

            if (_controller!.controller != null && _controller!.isReady) {
              return _buildPlayer(_controller!);
            }

            return _buildThumbnailFallback();
          }),
        ),
      ),
    );
  }

  Widget _buildPlayer(VideoController controller) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Get.width * 0.04),
        child: Stack(
          children: [
            YoutubePlayer(
              controller: controller.controller!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: AppColors.secondaryColor,
              progressColors: const ProgressBarColors(
                playedColor: AppColors.secondaryColor,
                handleColor: AppColors.primaryColor,
              ),
              bottomActions: const [
                CurrentPosition(),
                ProgressBar(isExpanded: true),
                RemainingDuration(),
              ],
              onReady: () {
                debugPrint('YouTube Player onReady callback fired');
              },
              onEnded: (metaData) {
                debugPrint('Video ended');
              },
            ),
            // Mute button overlay
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: Icon(
                    controller.isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: controller.toggleMute,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Get.width * 0.04),
        color: Colors.black87,
      ),
      child: Stack(
        children: [
          // Background thumbnail if available
          if (widget.thumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(Get.width * 0.04),
              child: Image.network(
                widget.thumbnailUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white24),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.white24),
                  );
                },
              ),
            ),
          // Loading overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Get.width * 0.04),
              color: Colors.black54,
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.secondaryColor),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Loading video...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailFallback() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Get.width * 0.04),
        color: Colors.grey[200],
      ),
      child: widget.thumbnailUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(Get.width * 0.04),
              child: Image.network(
                widget.thumbnailUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 50),
                  );
                },
              ),
            )
          : const Center(
              child: Icon(Icons.video_library, size: 50, color: Colors.grey),
            ),
    );
  }

  Widget _buildErrorState(String message, VideoController controller) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Get.width * 0.04),
        color: Colors.red[50],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: controller.retryInitialization,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryColor,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.white),
            ),
          ),
          if (widget.thumbnailUrl != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(Get.width * 0.04),
              child: Image.network(
                widget.thumbnailUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Don't dispose the controller here as it's shared and permanent
    super.dispose();
  }
}
