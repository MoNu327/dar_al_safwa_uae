import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class VideoController extends GetxController {
  late VideoPlayerController videoPlayerController;
  var isInitialized = false.obs; // Observable boolean

  @override
  void onInit() {
    super.onInit();
    videoPlayerController = VideoPlayerController.asset("assets/videos/v2.mp4")
      ..initialize().then((_) {
        videoPlayerController.setLooping(true);
        videoPlayerController.play(); // Auto-play video
        isInitialized.value = true; // Update observable
      });
  }

  @override
  void onClose() {
    if (videoPlayerController.value.isInitialized) {
      videoPlayerController.dispose();
    }
    super.onClose();
  }
}
