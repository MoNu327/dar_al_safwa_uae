import 'package:get/get.dart';
import 'dart:async';

import '../../core/routes/app_route.dart';

class SplashController extends GetxController {
  var opacity = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _startAnimation();
  }

  void _startAnimation() {
    Future.delayed(const Duration(milliseconds: 200), () {
      opacity.value = 1.0;
    });

    Future.delayed(const Duration(seconds: 3), () {
      Get.offNamed(AppRoute.login); // Navigate to Home Screen
    });
  }
}
