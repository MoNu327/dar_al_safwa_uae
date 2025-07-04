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
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxBool isLandscape = true.obs;
  final RxString errorMessage = ''.obs;

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
    // Clear all image loading states
    gridImageLoading.clear();
    gridImageError.clear();
    gridImageLoaded.clear();

    // Reset orientation
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    super.onClose();
  }

  // Setup connectivity monitoring
  void _setupConnectivityListener() {
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      isConnected.value = result != ConnectivityResult.none;
      connectionType.value = result.toString();

      // Enable low data mode on mobile networks
      lowDataMode.value = result == ConnectivityResult.mobile;
    });
  }

  // Detect low data mode based on connection
  void _detectLowDataMode() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    isConnected.value = connectivityResult != ConnectivityResult.none;
    connectionType.value = connectivityResult.toString();
    lowDataMode.value = connectivityResult == ConnectivityResult.mobile;
  }

  // Update visible range for lazy loading
  void updateVisibleRange(int startIndex, int endIndex) {
    visibleStartIndex.value = startIndex;
    visibleEndIndex.value = endIndex;

    // Clear loading states for images outside visible range
    _clearInvisibleImageStates();
  }

  // Clear loading states for images outside visible range
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

  // Preload grid image with optimization
  Future<void> preloadGridImage(int index) async {
    if (gridImageLoaded[index] == true ||
        gridImageLoading[index] == true) return;

    // Check if we should load based on data mode
    if (lowDataMode.value && !_shouldLoadInLowDataMode(index)) {
      return;
    }

    try {
      gridImageLoading[index] = true;
      gridImageError[index] = false;

      // Validate URL
      if (index >= imageUrls.length ||
          imageUrls[index].isEmpty ||
          !isValidImageUrl(imageUrls[index])) {
        throw Exception('Invalid image URL');
      }

      // The image will be loaded by CachedNetworkImage
      // We just mark it as loaded for state management
      gridImageLoaded[index] = true;
      gridImageLoading[index] = false;
    } catch (e) {
      gridImageLoading[index] = false;
      gridImageError[index] = true;

      // Don't show snackbar for every error, just log
      print('Failed to load image preview $index: ${e.toString()}');
    }
  }

  // Check if should load in low data mode
  bool _shouldLoadInLowDataMode(int index) {
    // Only load images in visible range + 1 buffer
    return index >= visibleStartIndex.value - 1 &&
        index <= visibleEndIndex.value + 1;
  }

  // Validate image URL
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

  // Get user-friendly error message
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

  // Toggle screen orientation
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

  // Preload next image for smoother experience
  Future<void> preloadNextImage(int currentIndex) async {
    final nextIndex = currentIndex + 1;
    if (nextIndex < imageUrls.length &&
        gridImageLoaded[nextIndex] != true) {
      await preloadGridImage(nextIndex);
    }
  }

  // Get thumbnail URL for faster loading (if applicable)
  String? getThumbnailUrl(String imageUrl) {
    // For regular images, we can return a lower resolution version
    // This is a basic implementation - you might want to use a service
    // that provides different image sizes
    if (imageUrl.contains('?')) {
      return '$imageUrl&w=300&h=200';
    } else {
      return '$imageUrl?w=300&h=200';
    }
  }

  // Check if image is already loaded
  bool isImageLoaded(int index) {
    return gridImageLoaded[index] ?? false;
  }

  // Check if image is loading
  bool isImageLoading(int index) {
    return gridImageLoading[index] ?? false;
  }

  // Check if image has error
  bool hasImageError(int index) {
    return gridImageError[index] ?? false;
  }

  // Clear all image states
  void clearAllImageStates() {
    gridImageLoading.clear();
    gridImageError.clear();
    gridImageLoaded.clear();
  }

  // Refresh image at specific index
  Future<void> refreshImage(int index) async {
    gridImageLoading[index] = false;
    gridImageError[index] = false;
    gridImageLoaded[index] = false;
    await preloadGridImage(index);
  }

  // Get image quality based on data mode
  String getImageQuality() {
    return lowDataMode.value ? 'low' : 'high';
  }

  // Check if image should be preloaded based on connection
  bool shouldPreloadImage() {
    return isConnected.value && !lowDataMode.value;
  }
}