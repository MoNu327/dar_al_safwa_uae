import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:vr_player/vr_player.dart';

class View360 extends StatefulWidget {
  final List<String> videoUrls;

  const View360({super.key, this.videoUrls = const []});

  @override
  State<View360> createState() => _View360State();
}

class _View360State extends State<View360> {
  List<String> get videos => widget.videoUrls.isNotEmpty
      ? widget.videoUrls
      : [
          'https://example.com/vr1.mp4',
          'https://example.com/vr2.mp4',
        ];

  // Track video controllers for grid items
  final Map<int, VideoPlayerController> _videoControllers = {};

  @override
  void dispose() {
    // Dispose all video controllers
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: videos.isEmpty
          ? const Center(child: Text('No VR videos available'))
          : GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                // Initialize controller if not already done
                if (!_videoControllers.containsKey(index)) {
                  _videoControllers[index] =
                      VideoPlayerController.network(videos[index])
                        ..initialize().then((_) {
                          if (mounted) setState(() {});
                          // Mute audio for grid previews
                          _videoControllers[index]!.setVolume(0);
                          // Set to beginning and pause
                          _videoControllers[index]!.seekTo(Duration.zero);
                          _videoControllers[index]!.pause();
                        });
                }

                return GestureDetector(
                  onTap: () => _openVRPlayer(videos[index]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Video Player Preview
                        if (_videoControllers[index]?.value.isInitialized ??
                            false)
                          AspectRatio(
                            aspectRatio:
                                _videoControllers[index]!.value.aspectRatio,
                            child: VideoPlayer(_videoControllers[index]!),
                          )
                        else
                          Container(
                            color: Colors.grey[300],
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),

                        // Semi-transparent overlay with play button
                        Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            size: 50,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),

                        // Video title overlay
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.black54,
                            child: Text(
                              'VR Tour ${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _openVRPlayer(String videoUrl) {
    // Pause all grid videos before opening VR player
    for (var controller in _videoControllers.values) {
      controller.pause();
    }

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
  VrPlayerController? _vrController;
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _isVRMode = false;
  bool _hasError = false;
  bool _isLandscape = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _vrController?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize VR player: $e')),
      );
    }
  }

  Future<void> _loadVideo() async {
    if (_vrController == null) return;

    try {
      await _vrController!.loadVideo(videoUrl: widget.videoUrl);
      await _vrController!.play();

      setState(() {
        _isLoading = false;
        _isPlaying = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load video: $e')),
      );
    }
  }

  void _toggleOrientation() {
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    setState(() {
      _isLandscape = !_isLandscape;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // VR Player
          if (!_hasError)
            VrPlayer(
              x: 0,
              y: 0,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              onCreated: (controller, _) {
                _vrController = controller;
                _loadVideo();
              },
            ),

          // Error message
          if (_hasError)
            const Center(
              child: Text(
                'Failed to load VR video',
                style: TextStyle(color: Colors.white),
              ),
            ),

          // Loading indicator
          if (_isLoading) const Center(child: CircularProgressIndicator()),

          // Controls overlay
          if (!_isLoading && !_hasError)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Play/Pause button
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    color: Colors.white,
                    onPressed: () async {
                      if (_vrController == null) return;

                      if (_isPlaying) {
                        await _vrController!.pause();
                      } else {
                        await _vrController!.play();
                      }
                      setState(() => _isPlaying = !_isPlaying);
                    },
                  ),

                  // VR Mode toggle
                  IconButton(
                    icon: Icon(_isVRMode ? Icons.vrpano : Icons.vrpano_rounded),
                    color: Colors.white,
                    onPressed: () async {
                      if (_vrController == null) return;

                      await _vrController!.toggleVRMode();
                      setState(() => _isVRMode = !_isVRMode);
                    },
                  ),

                  // Orientation toggle
                  IconButton(
                    icon: Icon(_isLandscape
                        ? Icons.screen_lock_portrait
                        : Icons.screen_lock_landscape),
                    color: Colors.white,
                    onPressed: _toggleOrientation,
                  ),

                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.white,
                    onPressed: () {
                      // Reset orientation before closing
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                      ]);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
