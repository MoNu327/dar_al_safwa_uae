import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:vr_player/vr_player.dart';

class VR360Controller extends GetxController {
  // For grid view videos
  final RxList<String> videoUrls = <String>[].obs;
  final RxMap<int, VideoPlayerController> gridVideoControllers =
      <int, VideoPlayerController>{}.obs;

  // For VR player
  final Rx<VrPlayerController?> vrController = Rx<VrPlayerController?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isPlaying = false.obs;
  final RxBool isVRMode = false.obs;
  final RxBool hasError = false.obs;
  final RxBool isLandscape = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize with default videos if none provided
    if (videoUrls.isEmpty) {
      videoUrls.addAll([
        'https://example.com/vr1.mp4',
        'https://example.com/vr2.mp4',
      ]);
    }
  }

  @override
  void onClose() {
    // Dispose all grid video controllers
    for (var controller in gridVideoControllers.values) {
      controller.dispose();
    }
    gridVideoControllers.clear();

    // Dispose VR controller
    vrController.value?.dispose();
    vrController.value = null;

    // Reset orientation
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    super.onClose();
  }

  // Initialize grid video controller for a specific index
  Future<void> initializeGridVideoController(int index) async {
    if (gridVideoControllers.containsKey(index)) return;

    try {
      final controller = VideoPlayerController.network(videoUrls[index]);
      gridVideoControllers[index] = controller;

      await controller.initialize();
      controller.setVolume(0); // Mute audio for previews
      controller.seekTo(Duration.zero);
      controller.pause();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load video preview: ${e.toString()}');
    }
  }

  // Initialize VR player
  Future<void> initializeVRPlayer(
      String videoUrl, VrPlayerController controller) async {
    try {
      isLoading.value = true;
      hasError.value = false;
      vrController.value = controller;

      await controller.loadVideo(videoUrl: videoUrl);
      await controller.play();

      isLoading.value = false;
      isPlaying.value = true;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      Get.snackbar('Error', 'Failed to load VR video: ${e.toString()}');
    }
  }

  // Toggle play/pause
  Future<void> togglePlayPause() async {
    if (vrController.value == null) return;

    if (isPlaying.value) {
      await vrController.value!.pause();
    } else {
      await vrController.value!.play();
    }
    isPlaying.toggle();
  }

  // Toggle VR mode
  Future<void> toggleVRMode() async {
    if (vrController.value == null) return;

    await vrController.value!.toggleVRMode();
    isVRMode.toggle();
  }

  // Toggle screen orientation
  Future<void> toggleOrientation() async {
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
  }

  // Pause all grid videos
  void pauseAllGridVideos() {
    for (var controller in gridVideoControllers.values) {
      controller.pause();
    }
  }
}
