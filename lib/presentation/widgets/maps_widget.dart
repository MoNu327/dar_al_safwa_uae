import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';

class LocationPreview extends StatelessWidget {
  final LatLng location;
  final double previewHeight;

  const LocationPreview({
    Key? key,
    required this.location,
    this.previewHeight = 150,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Preview Container
        _buildMapPreview(context),
        const SizedBox(height: 8),
        // Open in Maps Button
        TextButton.icon(
          onPressed: _openInNativeMaps,
          icon: const Icon(Icons.open_in_new),
          label: const Text('View larger map'),
        ),
      ],
    );
  }

  Widget _buildMapPreview(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullScreenMap(context),
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
                  initialCenter: location,
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all, // Disable gestures
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
                        point: location,
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
              // Tap overlay indicator
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }

  void _showFullScreenMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Location'),
            backgroundColor: AppColors.secondaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: FlutterMap(
            options: MapOptions(
              initialCenter: location,
              initialZoom: 15.0,
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
                    point: location,
                    child: const Icon(
                      Icons.location_pin,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _openInNativeMaps,
            tooltip: 'Open in Maps',
            child: const Icon(Icons.open_in_new),
          ),
        ),
      ),
    );
  }

  Future<void> _openInNativeMaps() async {
    // Try multiple map providers for better compatibility
    final List<String> mapUrls = [
      // Google Maps (mobile apps)
      'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
      // Apple Maps (iOS)
      'https://maps.apple.com/?q=${location.latitude},${location.longitude}',
      // OpenStreetMap (web fallback)
      'https://www.openstreetmap.org/?mlat=${location.latitude}&mlon=${location.longitude}#map=16/${location.latitude}/${location.longitude}',
    ];

    bool launched = false;

    for (String url in mapUrls) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) break;
        }
      } catch (e) {
        // Continue to next URL if current one fails
        continue;
      }
    }

    if (!launched) {
      throw Exception('Could not launch any map application');
    }
  }
}
