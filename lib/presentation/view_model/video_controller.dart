import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:async';

class VideoController extends GetxController {
  // Current video state
  final Rx<YoutubePlayerController?> _currentController = Rx<YoutubePlayerController?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _isMuted = false.obs;
  final RxString _currentVideoId = ''.obs;
  final RxString _errorMessage = ''.obs;
  final RxBool _isReady = false.obs;
  final RxBool _isPaused = false.obs;

  // Timer for fallback initialization
  Timer? _initializationTimer;
  Timer? _debounceTimer;

  // Cache for avoiding repeated initializations
  final Map<String, bool> _initializedVideos = {};

  // Getters
  YoutubePlayerController? get controller => _currentController.value;
  bool get isLoading => _isLoading.value;
  bool get isMuted => _isMuted.value;
  String get errorMessage => _errorMessage.value;
  bool get hasError => _errorMessage.isNotEmpty;
  bool get isReady => _isReady.value;
  bool get isPaused => _isPaused.value;

  // Initialize or update player with debouncing
  void initializePlayer(String url) {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null || videoId.isEmpty) {
      _setError('Invalid YouTube URL');
      return;
    }

    // Debounce rapid initialization calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performInitialization(videoId, url);
    });
  }

  void _performInitialization(String videoId, String url) {
    // Skip if already initialized with same video and ready
    if (_currentVideoId.value == videoId && 
        _currentController.value != null && 
        _isReady.value &&
        _initializedVideos.containsKey(videoId)) {
      return;
    }

    _currentVideoId.value = videoId;
    _clearError();
    
    // Only show loading if we're switching videos or first load
    if (!_initializedVideos.containsKey(videoId)) {
      _isLoading.value = true;
    }
    
    _isReady.value = false;
    _isPaused.value = false;

    // Cancel any existing timer
    _initializationTimer?.cancel();

    // Dispose previous controller only if different video
    if (_currentController.value != null &&
        _currentController.value!.initialVideoId != videoId) {
      _disposeCurrentController();
    }

    // Skip if controller already exists for this video
    if (_currentController.value != null && 
        _currentController.value!.initialVideoId == videoId) {
      _isLoading.value = false;
      _isReady.value = true;
      _initializedVideos[videoId] = true;
      return;
    }

    _createNewController(videoId);
  }

  void _createNewController(String videoId) {
    try {
      _currentController.value = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: false, // Prevent auto-play for better performance
          mute: _isMuted.value,
          enableCaption: false,
          hideControls: false,
          disableDragSeek: false,
          loop: false,
          isLive: false,
          forceHD: false,
          startAt: 0,
        ),
      );
      
      _currentController.value!.addListener(_playerListener);

      // Set a more reasonable timeout
      _initializationTimer = Timer(const Duration(seconds: 5), () {
        if (_isLoading.value && !_isReady.value) {
          print('Player initialization timeout, forcing ready state');
          _isLoading.value = false;
          _isReady.value = true;
          _initializedVideos[videoId] = true;
        }
      });

    } catch (e) {
      print('Error initializing player: $e');
      _setError('Failed to initialize player: ${e.toString()}');
    }
  }

  void _playerListener() {
    final controller = _currentController.value;
    if (controller == null) return;

    try {
      final value = controller.value;
      
      // Check if player is ready
      if (value.isReady && !_isReady.value) {
        print('Player is ready for video: ${controller.initialVideoId}');
        _isLoading.value = false;
        _isReady.value = true;
        _initializedVideos[controller.initialVideoId] = true;
        _initializationTimer?.cancel();
        _clearError();
      }
      
      // Track pause state
      if (value.isReady) {
        _isPaused.value = !value.isPlaying;
      }
      
      // Handle errors
      if (value.hasError) {
        print('Player error: ${value.errorCode}');
        _setError('Playback error occurred');
        _initializedVideos.remove(controller.initialVideoId);
      }
    } catch (e) {
      print('Error in player listener: $e');
    }
  }

  // Optimized playback controls
  void playVideo() {
    if (_currentController.value != null && _isReady.value) {
      try {
        _currentController.value!.play();
        _isPaused.value = false;
      } catch (e) {
        print('Error playing video: $e');
      }
    }
  }

  void pauseVideo() {
    if (_currentController.value != null && _isReady.value) {
      try {
        _currentController.value!.pause();
        _isPaused.value = true;
      } catch (e) {
        print('Error pausing video: $e');
      }
    }
  }

  // Toggle mute state
  void toggleMute() {
    _isMuted.value = !_isMuted.value;
    if (_currentController.value != null && _isReady.value) {
      try {
        _isMuted.value
            ? _currentController.value!.mute()
            : _currentController.value!.unMute();
      } catch (e) {
        print('Error toggling mute: $e');
      }
    }
  }

  // Method to retry initialization
  void retryInitialization() {
    if (_currentVideoId.isNotEmpty) {
      // Clear cache for this video
      _initializedVideos.remove(_currentVideoId.value);
      _isReady.value = false;
      _clearError();
      final videoUrl = 'https://www.youtube.com/watch?v=${_currentVideoId.value}';
      initializePlayer(videoUrl);
    }
  }

  // Seek to position
  void seekTo(Duration position) {
    if (_currentController.value != null && _isReady.value) {
      try {
        _currentController.value!.seekTo(position);
      } catch (e) {
        print('Error seeking: $e');
      }
    }
  }

  // Get current position
  Duration get currentPosition {
    if (_currentController.value != null && _isReady.value) {
      try {
        return _currentController.value!.value.position;
      } catch (e) {
        print('Error getting position: $e');
      }
    }
    return Duration.zero;
  }

  // Get total duration
  // Duration get totalDuration {
  //   if (_currentController.value != null && _isReady.value) {
  //     try {
  //       return _currentController.value!.flags.;
  //     } catch (e) {
  //       print('Error getting duration: $e');
  //     }
  //   }
  //   return Duration.zero;
  // }

  // Helper methods
  void _setError(String message) {
    _errorMessage.value = message;
    _isLoading.value = false;
    _isReady.value = false;
  }

  void _clearError() {
    _errorMessage.value = '';
  }

  void _disposeCurrentController() {
    if (_currentController.value != null) {
      try {
        _currentController.value!.removeListener(_playerListener);
        _currentController.value!.dispose();
      } catch (e) {
        print('Error disposing controller: $e');
      } finally {
        _currentController.value = null;
      }
    }
  }

  // Clean up cache periodically
  void clearCache() {
    _initializedVideos.clear();
    print('Video cache cleared');
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _initializationTimer?.cancel();
    _disposeCurrentController();
    _initializedVideos.clear();
    super.onClose();
  }
}