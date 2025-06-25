// lib/presentation/controllers/maps_controller.dart
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsController extends GetxController {
  final Rx<LatLng> location;
  final RxDouble zoomLevel = 15.0.obs;
  final RxBool isFullScreen = false.obs;

  MapsController({required LatLng initialLocation})
      : location = initialLocation.obs;

  void updateLocation(LatLng newLocation) {
    location.value = newLocation;
  }

  void toggleFullScreen(bool value) {
    isFullScreen.value = value;
  }

  Future<void> openInNativeMaps() async {
    final List<String> mapUrls = [
      'https://www.google.com/maps/search/?api=1&query=${location.value.latitude},${location.value.longitude}',
      'https://maps.apple.com/?q=${location.value.latitude},${location.value.longitude}',
      'https://www.openstreetmap.org/?mlat=${location.value.latitude}&mlon=${location.value.longitude}#map=16/${location.value.latitude}/${location.value.longitude}',
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
        continue;
      }
    }

    if (!launched) {
      Get.snackbar(
        'Error',
        'Could not launch any map application',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}