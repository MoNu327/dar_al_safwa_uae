import 'dart:async';

import 'package:majan/presentation/view/property_details/controller/property_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../controller/vr_360_controller.dart';

class View360 extends StatelessWidget {
  final List<String> imageUrls;

  const View360({super.key, this.imageUrls = const []});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(Panorama360Controller());
    final propertiesController = Get.put(PropertyDetailsController());

    // Always check for property image URL first
    final imageUrl = propertiesController
            .property?.value?.unitTypes?.data?.first?.youtubeUrl ??
        "";

    // Set image URLs based on available data
    if (imageUrl.isNotEmpty) {
      controller.imageUrls.value = [imageUrl];
    } else if (imageUrls.isNotEmpty) {
      controller.imageUrls.value = imageUrls;
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

        if (controller.imageUrls.isEmpty) {
          return _buildNoImagesState();
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
                  .clamp(0, controller.imageUrls.length - 1);
              final endIndex = ((scrollOffset + viewportHeight) / itemHeight)
                  .ceil()
                  .clamp(0, controller.imageUrls.length - 1);

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
            itemCount: controller.imageUrls.length,
            itemBuilder: (context, index) {
              return _buildImageItem(context, controller, index);
            },
          ),
        );
      }),
    );
  }

  Widget _buildImageItem(
      BuildContext context, Panorama360Controller controller, int index) {
    return GestureDetector(
      onTap: () => _openPanoramaViewer(context, controller.imageUrls[index]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background/Thumbnail
            Container(
              color: Colors.grey[800],
              child: _buildImagePreview(controller, index),
            ),

            // Loading overlay
            Obx(() {
              if (controller.isImageLoading(index)) {
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
              if (controller.hasImageError(index)) {
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
                          onPressed: () => controller.preloadGridImage(index),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            // View button overlay
            if (!controller.isImageLoading(index) &&
                !controller.hasImageError(index))
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black54,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    Icons.panorama_photosphere,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),

            // 360° Mode indicator
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

            // Image title overlay
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
                  'Panorama ${index + 1}',
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

  Widget _buildImagePreview(Panorama360Controller controller, int index) {
    return Obx(() {
      // Show cached image
      if (controller.isImageLoaded(index)) {
        return CachedNetworkImage(
          imageUrl: controller.imageUrls[index],
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

      // Initialize image loading on demand
      if (!controller.isImageLoading(index) &&
          !controller.hasImageError(index)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.preloadGridImage(index);
        });
      }

      // Default placeholder
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: Icon(
            Icons.panorama_photosphere,
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
              // Retry connection
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoImagesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.panorama_photosphere_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Panoramic Images Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Panoramic content will appear here when available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _openPanoramaViewer(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PanoramaViewerScreen(imageUrl: imageUrl),
      ),
    );
  }
}

class PanoramaViewerScreen extends StatelessWidget {
  final String imageUrl;

  const PanoramaViewerScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<Panorama360Controller>();
    controller.initializePanorama(imageUrl);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        return Stack(
          children: [
            // Panorama Viewer
            if (!controller.panoramaLoading.value &&
                !controller.panoramaError.value)
              PanoramaViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 80,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Loading state
            if (controller.panoramaLoading.value)
              Container(
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Loading Panoramic Image...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

            // Error state
            if (controller.panoramaError.value)
              Container(
                color: Colors.black,
                child: Center(
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
                        'Failed to Load Panoramic Image',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.panoramaErrorMessage.value,
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () =>
                            controller.initializePanorama(imageUrl),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),

            // Controls overlay
            if (!controller.panoramaLoading.value &&
                !controller.panoramaError.value)
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
                        icon: Icons.panorama_photosphere,
                        onPressed: () {
                          Get.snackbar(
                            'Info',
                            'Drag to look around in 360°',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        tooltip: 'Panorama Mode',
                      ),
                      _buildControlButton(
                        icon: Icons.fullscreen,
                        onPressed: controller.toggleOrientation,
                        tooltip: 'Fullscreen',
                      ),
                      _buildControlButton(
                        icon: Icons.refresh,
                        onPressed: () =>
                            controller.initializePanorama(imageUrl),
                        tooltip: 'Refresh',
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
        );
      }),
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
