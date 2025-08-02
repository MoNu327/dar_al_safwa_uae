import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GalleryController extends GetxController {
  late PageController pageController;
  final RxInt currentIndex = 0.obs;
  late List<String> images;
  late int initialIndex;

  @override
  void onInit() {
    super.onInit();
    // Get arguments passed from previous screen
    final args = Get.arguments as Map<String, dynamic>? ??
        {
          'images': [],
          'initialIndex': 0,
        };
    images = args['images'];
    initialIndex = args['initialIndex'];

    // Initialize page controller with initial index
    pageController = PageController(initialPage: initialIndex);
    currentIndex.value = initialIndex;
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int index) {
    currentIndex.value = index;
  }
}
