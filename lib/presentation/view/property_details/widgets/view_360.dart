import 'dart:async';

import 'package:dar_al_safwa/presentation/view/property_details/controller/property_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:vr_player/vr_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../controller/vr_360_controller.dart';

class View360 extends StatelessWidget {
  final List<String> videoUrls;

  const View360({super.key, this.videoUrls = const []});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VR360Controller());
    final propertiesController = Get.put(PropertyDetailsController());

    // Always check for property video URL first
    final videoUrl = propertiesController
            .property?.value?.unitTypes?.data?.first?.youtubeUrl ??
        "";

    // Set video URLs based on available data
    if (videoUrl.isNotEmpty) {
      controller.videoUrls.value = videoUrls;
      // controller.videoUrls.value = [videoUrl];
    } else if (videoUrls.isNotEmpty) {
      controller.videoUrls.value = videoUrls;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        surfaceTintColor: AppColors.white,
        actions: [
          Obx(() => IconButton(
                icon: Icon(
                  controller.lowDataMode.value
                      ? Icons.data_saver_on
                      : Icons.data_saver_off,
                  color: controller.lowDataMode.value
                      ? AppColors.secondaryColor
                      : AppColors.grey,
                ),
                onPressed: () {
                  controller.lowDataMode.toggle();
                  Get.snackbar(
                    'Data Mode',
                    controller.lowDataMode.value
                        ? 'Low data mode enabled'
                        : 'Low data mode disabled',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              )),
        ],
      ),
      body: Obx(() {
        if (!controller.isConnected.value) {
          return _buildNoConnectionState();
        }

        if (controller.videoUrls.isEmpty) {
          return _buildNoVideosState();
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            // Update visible range for lazy loading
            if (scrollInfo is ScrollUpdateNotification) {
              final RenderBox renderBox =
                  context.findRenderObject() as RenderBox;
              final viewportHeight = renderBox.size.height;
              final scrollOffset = scrollInfo.metrics.pixels;

              // Calculate visible indices (approximate)
              final itemHeight = viewportHeight / 2; // Assuming 2 items per row
              final startIndex = (scrollOffset / itemHeight)
                  .floor()
                  .clamp(0, controller.videoUrls.length - 1);
              final endIndex = ((scrollOffset + viewportHeight) / itemHeight)
                  .ceil()
                  .clamp(0, controller.videoUrls.length - 1);

              controller.updateVisibleRange(startIndex, endIndex);
            }
            return false;
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: controller.lowDataMode.value ? 1 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: controller.lowDataMode.value ? 1.5 : 0.9,
            ),
            itemCount: controller.videoUrls.length,
            itemBuilder: (context, index) {
              return _buildVideoItem(context, controller, index);
            },
          ),
        );
      }),
    );
  }

  Widget _buildVideoItem(
      BuildContext context, VR360Controller controller, int index) {
    return GestureDetector(
      onTap: () => _openVRPlayer(context, controller.videoUrls[index]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background/Thumbnail
            Container(
              color: Colors.grey[800],
              child: _buildVideoPreview(controller, index),
            ),

            // Loading overlay
            Obx(() {
              if (controller.isVideoLoading(index)) {
                return Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 8),
                        Text(
                          'Loading...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            // Error overlay
            Obx(() {
              if (controller.hasVideoError(index)) {
                return Container(
                  color: Colors.red.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.white, size: 40),
                        const SizedBox(height: 8),
                        const Text(
                          'Failed to load',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () =>
                              controller.initializeGridVideoController(index),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            // Play button overlay
            if (!controller.isVideoLoading(index) &&
                !controller.hasVideoError(index))
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black54,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    Icons.play_arrow,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),

            // VR Mode indicator
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '360°',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Video title overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Text(
                  'VR Tour ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview(VR360Controller controller, int index) {
    return Obx(() {
      // Try to show thumbnail first
      final thumbnailUrl =
          controller.getThumbnailUrl(controller.videoUrls[index]);
      if (thumbnailUrl != null && controller.lowDataMode.value) {
        return CachedNetworkImage(
          imageUrl: thumbnailUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[800],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[800],
            child: const Icon(Icons.broken_image, color: Colors.white54),
          ),
        );
      }

      // Show video preview if loaded
      if (controller.isVideoLoaded(index)) {
        final videoController = controller.gridVideoControllers[index]!;
        return AspectRatio(
          aspectRatio: videoController.value.aspectRatio,
          child: VideoPlayer(videoController),
        );
      }

      // Initialize video controller on demand
      if (!controller.isVideoLoading(index) &&
          !controller.hasVideoError(index)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.initializeGridVideoController(index);
        });
      }

      // Default placeholder
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: Icon(
            Icons.video_library,
            color: Colors.white54,
            size: 50,
          ),
        ),
      );
    });
  }

  Widget _buildNoConnectionState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Internet Connection',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // final controller = Get.find<VR360Controller>();
              // controller._detectLowDataMode();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoVideosState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No VR Videos Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'VR content will appear here when available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _openVRPlayer(BuildContext context, String videoUrl) {
    final controller = Get.find<VR360Controller>();
    controller.pauseAllGridVideos();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VRPlayerScreen(videoUrl: videoUrl),
      ),
    );
  }
}

class VRPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VRPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VRPlayerScreen> createState() => _VRPlayerScreenState();
}

class _VRPlayerScreenState extends State<VRPlayerScreen> {
  late VR360Controller controller;
  bool _vrSupported = true;
  VideoPlayerController? _fallbackController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<VR360Controller>();
    _checkVRSupport();
  }

  @override
  void dispose() {
    _fallbackController?.dispose();
    super.dispose();
  }

  Future<void> _checkVRSupport() async {
    try {
      // Test VR initialization with timeout
      await Future.delayed(const Duration(milliseconds: 500));
      // If VR fails to initialize in 5 seconds, fallback to regular video
      Timer(const Duration(seconds: 5), () {
        if (controller.isLoading.value && !controller.hasError.value) {
          setState(() {
            _vrSupported = false;
          });
          _initializeFallbackPlayer();
        }
      });
    } catch (e) {
      setState(() {
        _vrSupported = false;
      });
      _initializeFallbackPlayer();
    }
  }

  Future<void> _initializeFallbackPlayer() async {
    try {
      _fallbackController = VideoPlayerController.network(widget.videoUrl);
      await _fallbackController!.initialize();
      await _fallbackController!.setLooping(true);
      await _fallbackController!.play();
      setState(() {});
    } catch (e) {
      print('Fallback player failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // VR Player (if supported)
          if (_vrSupported)
            Obx(() => Stack(
                  children: [
                    if (!controller.hasError.value)
                      VrPlayer(
                        x: 0,
                        y: 0,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        onCreated: (vrController, _) {
                          controller.initializeVRPlayer(
                              widget.videoUrl, vrController);
                        },
                      ),

                    // VR Error state
                    if (controller.hasError.value)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 80,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'VR Player Not Supported',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Switching to regular video player...',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _vrSupported = false;
                                });
                                _initializeFallbackPlayer();
                              },
                              child: const Text('Use Regular Player'),
                            ),
                          ],
                        ),
                      ),

                    // VR Loading state
                    if (controller.isLoading.value)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                'Loading VR Video...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // VR Controls overlay
                    if (!controller.isLoading.value &&
                        !controller.hasError.value)
                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildControlButton(
                                icon: controller.isPlaying.value
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                onPressed: controller.togglePlayPause,
                                tooltip: controller.isPlaying.value
                                    ? 'Pause'
                                    : 'Play',
                              ),
                              _buildControlButton(
                                icon: controller.isVRMode.value
                                    ? Icons.vrpano
                                    : Icons.vrpano_outlined,
                                onPressed: controller.toggleVRMode,
                                tooltip: 'Toggle VR Mode',
                              ),
                              _buildControlButton(
                                icon: Icons.video_library,
                                onPressed: () {
                                  setState(() {
                                    _vrSupported = false;
                                  });
                                  _initializeFallbackPlayer();
                                },
                                tooltip: 'Regular Player',
                              ),
                              _buildControlButton(
                                icon: Icons.close,
                                onPressed: () => Navigator.pop(context),
                                tooltip: 'Close',
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                )),

          // Fallback Video Player
          if (!_vrSupported)
            Stack(
              children: [
                if (_fallbackController != null &&
                    _fallbackController!.value.isInitialized)
                  Center(
                    child: AspectRatio(
                      aspectRatio: _fallbackController!.value.aspectRatio,
                      child: VideoPlayer(_fallbackController!),
                    ),
                  )
                else
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Loading Video...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                // Fallback Controls
                if (_fallbackController != null &&
                    _fallbackController!.value.isInitialized)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            icon: _fallbackController!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            onPressed: () {
                              setState(() {
                                if (_fallbackController!.value.isPlaying) {
                                  _fallbackController!.pause();
                                } else {
                                  _fallbackController!.play();
                                }
                              });
                            },
                            tooltip: _fallbackController!.value.isPlaying
                                ? 'Pause'
                                : 'Play',
                          ),
                          _buildControlButton(
                            icon: Icons.fullscreen,
                            onPressed: () {
                              SystemChrome.setPreferredOrientations([
                                DeviceOrientation.landscapeLeft,
                                DeviceOrientation.landscapeRight,
                              ]);
                            },
                            tooltip: 'Fullscreen',
                          ),
                          _buildControlButton(
                            icon: Icons.close,
                            onPressed: () {
                              SystemChrome.setPreferredOrientations(
                                  [DeviceOrientation.portraitUp]);
                              Navigator.pop(context);
                            },
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(25),
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
          iconSize: 28,
        ),
      ),
    );
  }
}
