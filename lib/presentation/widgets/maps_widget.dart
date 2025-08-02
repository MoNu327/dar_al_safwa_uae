// lib/presentation/widgets/location_preview.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../view_model/maps_controller.dart';

class LocationPreview extends StatelessWidget {
  final LatLng initialLocation;
  final double previewHeight;

  const LocationPreview({
    Key? key,
    required this.initialLocation,
    this.previewHeight = 150,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MapsController mapsController = Get.put(
      MapsController(initialLocation: initialLocation),
      tag: 'location_preview_${initialLocation.hashCode}',
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMapPreview(mapsController),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: mapsController.openInNativeMaps,
          icon: const Icon(Icons.open_in_new),
          label: const Text('View larger map'),
        ),
      ],
    );
  }

  Widget _buildMapPreview(MapsController controller) {
    return Obx(() => GestureDetector(
          onTap: () => _showFullScreenMap(controller),
          child: Container(
            height: previewHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: controller.location.value,
                      initialZoom: controller.zoomLevel.value,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                        maxZoom: 19,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: controller.location.value,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Tap to expand',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  void _showFullScreenMap(MapsController controller) {
    controller.toggleFullScreen(true);
    Get.to(
      () => FullScreenMap(controller: controller),
      transition: Transition.cupertino,
    );
  }
}

class FullScreenMap extends StatelessWidget {
  final MapsController controller;

  const FullScreenMap({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location'),
        backgroundColor: AppColors.secondaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            controller.toggleFullScreen(false);
            Get.back();
          },
        ),
      ),
      body: Obx(() => FlutterMap(
            options: MapOptions(
              initialCenter: controller.location.value,
              initialZoom: controller.zoomLevel.value,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: controller.location.value,
                    child: const Icon(
                      Icons.location_pin,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          )),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondaryColor,
        onPressed: controller.openInNativeMaps,
        tooltip: 'Open in Maps',
        child: const Icon(Icons.open_in_new),
      ),
    );
  }
}
