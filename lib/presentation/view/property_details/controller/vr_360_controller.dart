import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class Panorama360Controller extends GetxController {
  // For grid view images
  final RxList<String> imageUrls = <String>[].obs;
  final RxMap<int, bool> gridImageLoading = <int, bool>{}.obs;
  final RxMap<int, bool> gridImageError = <int, bool>{}.obs;
  final RxMap<int, bool> gridImageLoaded = <int, bool>{}.obs;

  // For panorama viewer
  final RxBool panoramaLoading = true.obs;
  final RxBool panoramaError = false.obs;
  final RxBool isLandscape = false.obs;
  final RxString panoramaErrorMessage = ''.obs;
  final RxString currentImageUrl = ''.obs;

  // Performance optimizations
  final RxBool isConnected = true.obs;
  final RxString connectionType = 'unknown'.obs;
  final RxBool lowDataMode = false.obs;

  // Lazy loading
  final RxInt visibleStartIndex = 0.obs;
  final RxInt visibleEndIndex = 4.obs;
  final int maxConcurrentLoads = 2;

  @override
  void onInit() {
    super.onInit();
    _setupConnectivityListener();
    _detectLowDataMode();
  }

  @override
  void onClose() {
    gridImageLoading.clear();
    gridImageError.clear();
    gridImageLoaded.clear();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.onClose();
  }

  void _setupConnectivityListener() {
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      isConnected.value = result != ConnectivityResult.none;
      connectionType.value = result.toString();
      lowDataMode.value = result == ConnectivityResult.mobile;
    });
  }

  void _detectLowDataMode() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    isConnected.value = connectivityResult != ConnectivityResult.none;
    connectionType.value = connectivityResult.toString();
    lowDataMode.value = connectivityResult == ConnectivityResult.mobile;
  }

  void updateVisibleRange(int startIndex, int endIndex) {
    visibleStartIndex.value = startIndex;
    visibleEndIndex.value = endIndex;
    _clearInvisibleImageStates();
  }

  void _clearInvisibleImageStates() {
    final statesToClear = <int>[];

    for (var index in gridImageLoading.keys) {
      if (index < visibleStartIndex.value - 1 ||
          index > visibleEndIndex.value + 1) {
        statesToClear.add(index);
      }
    }

    for (var index in statesToClear) {
      gridImageLoading.remove(index);
      gridImageError.remove(index);
      gridImageLoaded.remove(index);
    }
  }

  Future<void> initializePanorama(String imageUrl) async {
    try {
      panoramaLoading.value = true;
      panoramaError.value = false;
      panoramaErrorMessage.value = '';
      currentImageUrl.value = imageUrl;

      if (!isValidImageUrl(imageUrl)) {
        throw Exception('Invalid image URL format');
      }

      // The actual image loading will be handled by the Image.network widget
      panoramaLoading.value = false;
    } catch (e) {
      panoramaLoading.value = false;
      panoramaError.value = true;
      panoramaErrorMessage.value = getUserFriendlyErrorMessage(e.toString());
    }
  }

  Future<void> preloadGridImage(int index) async {
    if (gridImageLoaded[index] == true || gridImageLoading[index] == true)
      return;

    if (lowDataMode.value && !_shouldLoadInLowDataMode(index)) {
      return;
    }

    try {
      gridImageLoading[index] = true;
      gridImageError[index] = false;

      if (index >= imageUrls.length ||
          imageUrls[index].isEmpty ||
          !isValidImageUrl(imageUrls[index])) {
        throw Exception('Invalid image URL');
      }

      gridImageLoaded[index] = true;
      gridImageLoading[index] = false;
    } catch (e) {
      gridImageLoading[index] = false;
      gridImageError[index] = true;
      print('Failed to load image preview $index: ${e.toString()}');
    }
  }

  bool _shouldLoadInLowDataMode(int index) {
    return index >= visibleStartIndex.value - 1 &&
        index <= visibleEndIndex.value + 1;
  }

  bool isValidImageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          (url.toLowerCase().contains('.jpg') ||
              url.toLowerCase().contains('.jpeg') ||
              url.toLowerCase().contains('.png') ||
              url.toLowerCase().contains('.webp') ||
              url.toLowerCase().contains('.gif') ||
              url.toLowerCase().contains('image'));
    } catch (e) {
      return false;
    }
  }

  String getUserFriendlyErrorMessage(String error) {
    if (error.contains('timeout')) {
      return 'Image loading took too long. Please check your connection.';
    } else if (error.contains('connection') || error.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.contains('Invalid')) {
      return 'Invalid image format or URL.';
    } else {
      return 'Unable to load image. Please try again.';
    }
  }

  Future<void> toggleOrientation() async {
    try {
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
    } catch (e) {
      print('Error changing orientation: $e');
    }
  }

  Future<void> preloadNextImage(int currentIndex) async {
    final nextIndex = currentIndex + 1;
    if (nextIndex < imageUrls.length && gridImageLoaded[nextIndex] != true) {
      await preloadGridImage(nextIndex);
    }
  }

  String? getThumbnailUrl(String imageUrl) {
    if (imageUrl.contains('?')) {
      return '$imageUrl&w=300&h=200';
    } else {
      return '$imageUrl?w=300&h=200';
    }
  }

  bool isImageLoaded(int index) {
    return gridImageLoaded[index] ?? false;
  }

  bool isImageLoading(int index) {
    return gridImageLoading[index] ?? false;
  }

  bool hasImageError(int index) {
    return gridImageError[index] ?? false;
  }

  void clearAllImageStates() {
    gridImageLoading.clear();
    gridImageError.clear();
    gridImageLoaded.clear();
  }

  Future<void> refreshImage(int index) async {
    gridImageLoading[index] = false;
    gridImageError[index] = false;
    gridImageLoaded[index] = false;
    await preloadGridImage(index);
  }

  String getImageQuality() {
    return lowDataMode.value ? 'low' : 'high';
  }

  bool shouldPreloadImage() {
    return isConnected.value && !lowDataMode.value;
  }
}
