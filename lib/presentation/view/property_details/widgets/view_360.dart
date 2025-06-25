import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:vr_player/vr_player.dart';

import '../controller/vr_360_controller.dart';

class View360 extends StatelessWidget {
  final List<String> videoUrls;

  const View360({super.key, this.videoUrls = const []});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VR360Controller());
    if (videoUrls.isNotEmpty) {
      controller.videoUrls.value = videoUrls;
    }

    return Scaffold(
      body: Obx(() => controller.videoUrls.isEmpty
          ? const Center(child: Text('No VR videos available'))
          : GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: controller.videoUrls.length,
              itemBuilder: (context, index) {
                // Initialize controller if not already done
                if (!controller.gridVideoControllers.containsKey(index)) {
                  controller.initializeGridVideoController(index);
                }

                return GestureDetector(
                  onTap: () =>
                      _openVRPlayer(context, controller.videoUrls[index]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Video Player Preview
                        Obx(() {
                          final videoController =
                              controller.gridVideoControllers[index];
                          if (videoController?.value.isInitialized ?? false) {
                            return AspectRatio(
                              aspectRatio: videoController!.value.aspectRatio,
                              child: VideoPlayer(videoController),
                            );
                          }
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                                child: CircularProgressIndicator()),
                          );
                        }),

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
            )),
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

class VRPlayerScreen extends StatelessWidget {
  final String videoUrl;

  const VRPlayerScreen({super.key, required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VR360Controller>();

    return Scaffold(
      body: Obx(() => Stack(
            children: [
              // VR Player
              if (!controller.hasError.value)
                VrPlayer(
                  x: 0,
                  y: 0,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  onCreated: (vrController, _) {
                    controller.initializeVRPlayer(videoUrl, vrController);
                  },
                ),

              // Error message
              if (controller.hasError.value)
                const Center(
                  child: Text(
                    'Failed to load VR video',
                    style: TextStyle(color: Colors.white),
                  ),
                ),

              // Loading indicator
              if (controller.isLoading.value)
                const Center(child: CircularProgressIndicator()),

              // Controls overlay
              if (!controller.isLoading.value && !controller.hasError.value)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Play/Pause button
                      IconButton(
                        icon: Icon(controller.isPlaying.value
                            ? Icons.pause
                            : Icons.play_arrow),
                        color: Colors.white,
                        onPressed: controller.togglePlayPause,
                      ),

                      // VR Mode toggle
                      IconButton(
                        icon: Icon(controller.isVRMode.value
                            ? Icons.vrpano
                            : Icons.vrpano_rounded),
                        color: Colors.white,
                        onPressed: controller.toggleVRMode,
                      ),

                      // Orientation toggle
                      IconButton(
                        icon: Icon(controller.isLandscape.value
                            ? Icons.screen_lock_portrait
                            : Icons.screen_lock_landscape),
                        color: Colors.white,
                        onPressed: controller.toggleOrientation,
                      ),

                      // Close button
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: Colors.white,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
            ],
          )),
    );
  }
}
