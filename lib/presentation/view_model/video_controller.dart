import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:async';

class VideoController extends GetxController {
  // For local video
  late VideoPlayerController videoPlayerController;
  var isInitialized = false.obs;

  // For YouTube video
  YoutubePlayerController? youtubeController;
  var isYoutubeInitialized = false.obs;
  var debugMessage = ''.obs;
  var youtubeVideoId = ''.obs;
  var isMuted = false.obs;
  var currentUrl = ''.obs; // Track current URL to prevent reinitialization

  @override
  void onInit() {
    super.onInit();
    debugMessage.value = 'Controller initialized';
    _initializeLocalVideo();
  }

  void _initializeLocalVideo() {
    videoPlayerController = VideoPlayerController.asset("assets/videos/v2.mp4")
      ..initialize().then((_) {
        videoPlayerController.setLooping(true);
        videoPlayerController.play();
        isInitialized.value = true;
      });
  }

  void initializeYoutubePlayerFromUrl(String youtubeUrl) {
    // Skip if already initialized with the same URL
    if (currentUrl.value == youtubeUrl && youtubeController != null) {
      return;
    }

    debugMessage.value = 'Starting YouTube initialization from URL...';
    final videoId = YoutubePlayer.convertUrlToId(youtubeUrl);

    if (videoId == null || videoId.isEmpty) {
      debugMessage.value = 'Invalid YouTube URL: $youtubeUrl';
      return;
    }

    // Update current URL and video ID
    currentUrl.value = youtubeUrl;
    youtubeVideoId.value = videoId;

    // Initialize or reuse existing controller
    if (youtubeController == null) {
      _initializeYoutubePlayer(videoId);
    } else {
      _updateYoutubePlayer(videoId);
    }
  }

  void _initializeYoutubePlayer(String videoId) {
    try {
      debugMessage.value = 'Creating YouTube controller for ID: $videoId';

      youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: true,
          mute: isMuted.value,
          enableCaption: false,
          hideControls: false,
          controlsVisibleAtStart: true,
          loop: false,
          isLive: false,
          forceHD: false,
          startAt: 0,
        ),
      );

      _setupYoutubeListener();
    } catch (e) {
      debugMessage.value = 'Error initializing YouTube: $e';
    }
  }

  void _updateYoutubePlayer(String videoId) {
    try {
      debugMessage.value = 'Updating YouTube controller with ID: $videoId';
      youtubeController!.load(videoId, startAt: 0);
      _setupYoutubeListener();
    } catch (e) {
      debugMessage.value = 'Error updating YouTube: $e';
    }
  }

  void _setupYoutubeListener() {
    youtubeController?.addListener(() {
      if (youtubeController!.value.isReady) {
        debugMessage.value = 'YouTube player is ready!';
        isYoutubeInitialized.value = true;
      }
    });

    Timer(const Duration(seconds: 3), () {
      if (!isYoutubeInitialized.value) {
        debugMessage.value = 'Force initializing after 3 seconds';
        isYoutubeInitialized.value = true;
      }
    });
  }

  // Toggle mute state
  void toggleMute() {
    isMuted.value = !isMuted.value;
    if (youtubeController != null) {
      if (isMuted.value) {
        youtubeController!.mute();
      } else {
        youtubeController!.unMute();
      }
    }
  }

  Future<void> launchYouTubeVideo(String videoUrl) async {
    final url = Uri.parse(videoUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar("Error", "Could not launch video");
    }
  }

  void retryYoutubeInitialization() {
    debugMessage.value = 'Retrying YouTube initialization...';
    isYoutubeInitialized.value = false;
    if (youtubeVideoId.value.isNotEmpty) {
      _initializeYoutubePlayer(youtubeVideoId.value);
    }
  }

  @override
  void onClose() {
    videoPlayerController.dispose();
    youtubeController?.dispose();
    super.onClose();
  }
}
