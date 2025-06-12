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

  // Try with a definitely working video ID first
  final String youtubeVideoId = 'l6EzZafb1Pk';

  @override
  void onInit() {
    super.onInit();
    debugMessage.value = 'Controller initialized';
    _initializeLocalVideo();
    _initializeYoutubePlayer();
  }

  void _initializeLocalVideo() {
    videoPlayerController = VideoPlayerController.asset("assets/videos/v2.mp4")
      ..initialize().then((_) {
        videoPlayerController.setLooping(true);
        videoPlayerController.play();
        isInitialized.value = true;
      });
  }

  void _initializeYoutubePlayer() {
    debugMessage.value = 'Starting YouTube initialization...';

    try {
      // First validate the video ID
      if (!YoutubePlayer.convertUrlToId(youtubeVideoId)!.isNotEmpty) {
        debugMessage.value = 'Invalid video ID';
        return;
      }

      debugMessage.value = 'Creating YouTube controller...';

      youtubeController = YoutubePlayerController(
        initialVideoId: youtubeVideoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: false,
          hideControls: false,
          controlsVisibleAtStart: true,
          loop: false,
          isLive: false,
          forceHD: false,
          startAt: 0,
        ),
      );

      debugMessage.value = 'YouTube controller created, adding listener...';

      youtubeController!.addListener(() {
        debugMessage.value =
            'Listener called - State: ${youtubeController!.value.playerState}';

        if (youtubeController!.value.isReady) {
          debugMessage.value = 'YouTube player is ready!';
          isYoutubeInitialized.value = true;
        }

        if (youtubeController!.value.hasError) {
          debugMessage.value =
              'YouTube player has error: ${youtubeController!.value.errorCode}';
        }
      });

      // Force check after 3 seconds
      Timer(const Duration(seconds: 3), () {
        if (!isYoutubeInitialized.value) {
          debugMessage.value = 'Force initializing after 3 seconds';
          isYoutubeInitialized.value = true;
        }
      });

      debugMessage.value = 'YouTube initialization complete';
    } catch (e) {
      debugMessage.value = 'Error initializing YouTube: $e';
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
    youtubeController?.dispose();
    _initializeYoutubePlayer();
  }

  void testWithDifferentVideo(String videoId) {
    debugMessage.value = 'Testing with video ID: $videoId';
    isYoutubeInitialized.value = false;

    try {
      youtubeController?.load(videoId);

      Timer(const Duration(seconds: 2), () {
        isYoutubeInitialized.value = true;
        debugMessage.value = 'Loaded new video: $videoId';
      });
    } catch (e) {
      debugMessage.value = 'Error loading video: $e';
    }
  }

  @override
  void onClose() {
    if (videoPlayerController.value.isInitialized) {
      videoPlayerController.dispose();
    }
    youtubeController?.dispose();
    super.onClose();
  }
}
