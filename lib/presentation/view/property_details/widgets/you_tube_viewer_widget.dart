import 'package:dar_al_safwa/presentation/view/property_details/controller/property_details_controller.dart';
import 'package:dar_al_safwa/presentation/view_model/video_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_text_widget.dart';

class YoutubeViewerSection extends StatefulWidget {
  final String youtubeUrl;

  const YoutubeViewerSection({Key? key, required this.youtubeUrl})
      : super(key: key);

  @override
  State<YoutubeViewerSection> createState() => _YoutubeViewerSectionState();
}

class _YoutubeViewerSectionState extends State<YoutubeViewerSection> {
  final videoController = Get.find<VideoController>();

  final propertyDetailsController = Get.find<PropertyDetailsController>();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(YoutubeViewerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.youtubeUrl != oldWidget.youtubeUrl) {
      _initializePlayer();
    }
  }

  void _initializePlayer() {
    if (widget.youtubeUrl.isNotEmpty && !_initialized) {
      videoController.initializeYoutubePlayerFromUrl(widget.youtubeUrl);
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: Get.height * 0.24,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Obx(() => _buildPlayerContent()),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildPlayerContent() {
    if (videoController.isYoutubeInitialized.value &&
        videoController.youtubeController != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: YoutubePlayer(
          controller: videoController.youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.primaryColor,
          progressColors: ProgressBarColors(
            playedColor: AppColors.primaryColor,
            handleColor: AppColors.primaryColor,
          ),
          thumbnail: _buildThumbnail(),
          onReady: () {
            debugPrint('YouTube player onReady called');
            videoController.debugMessage.value = 'Player ready!';
          },
        ),
      );
    } else {
      return _buildLoadingState();
    }
  }

  Widget _buildThumbnail() {
    final thumbnail =
        propertyDetailsController.property.value?.youtubeVideo?.thumbnail;

    return thumbnail != null
        ? Image.network(thumbnail, fit: BoxFit.cover)
        : const SizedBox.shrink();
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Obx(() => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    videoController.debugMessage.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: videoController.retryYoutubeInitialization,
              child: const Text('Retry', style: TextStyle(fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Stack(
      children: [
        // Mute Button
        Positioned(
          top: 8,
          left: 8,
          child: Obx(() => GestureDetector(
                onTap: videoController.toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    videoController.isMuted.value
                        ? Icons.volume_off
                        : Icons.volume_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              )),
        ),

        // View More Button
        Positioned(
          top: 8,
          right: 8,
          child: SizedBox(
            height: screenHeight * 0.04,
            width: screenWidth * 0.25,
            child: ElevatedButton(
              onPressed: () {
                if (widget.youtubeUrl.isNotEmpty) {
                  videoController.launchYouTubeVideo(widget.youtubeUrl);
                }
              },
              style: ElevatedButton.styleFrom(
                shape: StadiumBorder(),
                padding: EdgeInsets.all(4),
                backgroundColor: AppColors.secondaryColor,
              ),
              child: CustomTextWidget(
                fontSize: tagTitle,
                title: "View More",
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),

        // Information Text
        Positioned(
          top: 8,
          left: 48,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "Watch our YouTube videos\nfor more information.",
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
