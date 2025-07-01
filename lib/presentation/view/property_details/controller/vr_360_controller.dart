import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:vr_player/vr_player.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class VR360Controller extends GetxController {
  // For grid view videos
  final RxList<String> videoUrls = <String>[].obs;
  final RxMap<int, VideoPlayerController> gridVideoControllers =
      <int, VideoPlayerController>{}.obs;
  final RxMap<int, bool> gridVideoLoading = <int, bool>{}.obs;
  final RxMap<int, bool> gridVideoError = <int, bool>{}.obs;

  // For VR player
  final Rx<VrPlayerController?> vrController = Rx<VrPlayerController?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isPlaying = false.obs;
  final RxBool isVRMode = false.obs;
  final RxBool hasError = false.obs;
  final RxBool isLandscape = true.obs;
  final RxString errorMessage = ''.obs;

  // Performance optimizations
  final RxBool isConnected = true.obs;
  final RxString connectionType = 'unknown'.obs;
  final RxBool lowDataMode = false.obs;
  
  // Lazy loading
  final RxInt visibleStartIndex = 0.obs;
  final RxInt visibleEndIndex = 4.obs;
  final int maxConcurrentLoads = 2;

  @override
  void onInit() {
    super.onInit();
    _setupConnectivityListener();
    _detectLowDataMode();
  }

  @override
  void onClose() {
    // Dispose all grid video controllers
    for (var controller in gridVideoControllers.values) {
      controller.dispose();
    }
    gridVideoControllers.clear();
    gridVideoLoading.clear();
    gridVideoError.clear();

    // Dispose VR controller
    vrController.value?.dispose();
    vrController.value = null;

    // Reset orientation
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    super.onClose();
  }

  // Setup connectivity monitoring
  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      isConnected.value = result != ConnectivityResult.none;
      connectionType.value = result.toString();
      
      // Enable low data mode on mobile networks
      lowDataMode.value = result == ConnectivityResult.mobile;
    });
  }

  // Detect low data mode based on connection
  void _detectLowDataMode() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    isConnected.value = connectivityResult != ConnectivityResult.none;
    connectionType.value = connectivityResult.toString();
    lowDataMode.value = connectivityResult == ConnectivityResult.mobile;
  }

  // Update visible range for lazy loading
  void updateVisibleRange(int startIndex, int endIndex) {
    visibleStartIndex.value = startIndex;
    visibleEndIndex.value = endIndex;
    
    // Dispose controllers outside visible range
    _disposeInvisibleControllers();
  }

  // Dispose controllers outside visible range
  void _disposeInvisibleControllers() {
    final controllersToDispose = <int>[];
    
    for (var index in gridVideoControllers.keys) {
      if (index < visibleStartIndex.value - 1 || 
          index > visibleEndIndex.value + 1) {
        controllersToDispose.add(index);
      }
    }
    
    for (var index in controllersToDispose) {
      gridVideoControllers[index]?.dispose();
      gridVideoControllers.remove(index);
      gridVideoLoading.remove(index);
      gridVideoError.remove(index);
    }
  }

  // Initialize grid video controller with optimization
  Future<void> initializeGridVideoController(int index) async {
    if (gridVideoControllers.containsKey(index) || 
        gridVideoLoading[index] == true) return;

    // Check if we should load based on data mode
    if (lowDataMode.value && !_shouldLoadInLowDataMode(index)) {
      return;
    }

    try {
      gridVideoLoading[index] = true;
      gridVideoError[index] = false;

      // Validate URL
      if (index >= videoUrls.length || 
          videoUrls[index].isEmpty || 
          !_isValidVideoUrl(videoUrls[index])) {
        throw Exception('Invalid video URL');
      }

      final controller = VideoPlayerController.network(
        videoUrls[index],
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      // Set timeout for initialization
      await controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Video initialization timeout');
        },
      );

      gridVideoControllers[index] = controller;
      
      // Configure for preview
      controller.setVolume(0);
      controller.setLooping(true);
      await controller.seekTo(Duration.zero);
      await controller.pause();

      gridVideoLoading[index] = false;
      
    } catch (e) {
      gridVideoLoading[index] = false;
      gridVideoError[index] = true;
      
      // Don't show snackbar for every error, just log
      print('Failed to load video preview $index: ${e.toString()}');
    }
  }

  // Check if should load in low data mode
  bool _shouldLoadInLowDataMode(int index) {
    // Only load videos in visible range + 1 buffer
    return index >= visibleStartIndex.value - 1 && 
           index <= visibleEndIndex.value + 1;
  }

  // Validate video URL
  bool _isValidVideoUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && 
             (uri.scheme == 'http' || uri.scheme == 'https') &&
             (url.toLowerCase().contains('.mp4') || 
              url.toLowerCase().contains('.mov') ||
              url.toLowerCase().contains('youtube') ||
              url.toLowerCase().contains('vimeo'));
    } catch (e) {
      return false;
    }
  }

  // Initialize VR player with better error handling
  Future<void> initializeVRPlayer(
      String videoUrl, VrPlayerController controller) async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      // Check connection
      if (!isConnected.value) {
        throw Exception('No internet connection');
      }

      // Validate URL
      if (!_isValidVideoUrl(videoUrl)) {
        throw Exception('Invalid video URL format');
      }

      vrController.value = controller;

      // Load video with timeout
      await controller.loadVideo(videoUrl: videoUrl).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('VR video loading timeout');
        },
      );

      // Start playing
      await controller.play();

      isLoading.value = false;
      isPlaying.value = true;
      
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = e.toString();
      
      // Show user-friendly error message
      Get.snackbar(
        'VR Video Error', 
        _getUserFriendlyErrorMessage(e.toString()),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Get user-friendly error message
  String _getUserFriendlyErrorMessage(String error) {
    if (error.contains('timeout')) {
      return 'Video loading took too long. Please check your connection.';
    } else if (error.contains('connection') || error.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.contains('Invalid')) {
      return 'Invalid video format or URL.';
    } else {
      return 'Unable to load video. Please try again.';
    }
  }

  // Retry VR player initialization
  Future<void> retryVRPlayer(String videoUrl) async {
    if (vrController.value != null) {
      await initializeVRPlayer(videoUrl, vrController.value!);
    }
  }

  // Toggle play/pause with error handling
  Future<void> togglePlayPause() async {
    if (vrController.value == null) return;

    try {
      if (isPlaying.value) {
        await vrController.value!.pause();
      } else {
        await vrController.value!.play();
      }
      isPlaying.toggle();
    } catch (e) {
      print('Error toggling play/pause: $e');
    }
  }

  // Toggle VR mode with error handling
  Future<void> toggleVRMode() async {
    if (vrController.value == null) return;

    try {
      await vrController.value!.toggleVRMode();
      isVRMode.toggle();
    } catch (e) {
      print('Error toggling VR mode: $e');
      Get.snackbar('Error', 'Failed to toggle VR mode');
    }
  }

  // Toggle screen orientation
  Future<void> toggleOrientation() async {
    try {
      if (isLandscape.value) {
        await SystemChrome.setPreferredOrientations(
            [DeviceOrientation.portraitUp]);
      } else {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
      isLandscape.toggle();
    } catch (e) {
      print('Error changing orientation: $e');
    }
  }

  // Pause all grid videos
  void pauseAllGridVideos() {
    for (var controller in gridVideoControllers.values) {
      try {
        controller.pause();
      } catch (e) {
        print('Error pausing video: $e');
      }
    }
  }

  // Preload next video for smoother experience
  Future<void> preloadNextVideo(int currentIndex) async {
    final nextIndex = currentIndex + 1;
    if (nextIndex < videoUrls.length && 
        !gridVideoControllers.containsKey(nextIndex)) {
      await initializeGridVideoController(nextIndex);
    }
  }

  // Get thumbnail URL for faster loading
  String? getThumbnailUrl(String videoUrl) {
    if (videoUrl.contains('youtube')) {
      final videoId = _extractYouTubeVideoId(videoUrl);
      if (videoId != null) {
        return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
      }
    }
    return null;
  }

  // Extract YouTube video ID
  String? _extractYouTubeVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/embed/)([^&\n?#]+)',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  // Check if video is already loaded
  bool isVideoLoaded(int index) {
    return gridVideoControllers.containsKey(index) &&
           gridVideoControllers[index]!.value.isInitialized;
  }

  // Check if video is loading
  bool isVideoLoading(int index) {
    return gridVideoLoading[index] ?? false;
  }

  // Check if video has error
  bool hasVideoError(int index) {
    return gridVideoError[index] ?? false;
  }
}