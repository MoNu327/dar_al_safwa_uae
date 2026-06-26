// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:majan/presentation/view_model/firebase_auth_controller.dart';
// import 'dart:async';

// import '../../core/routes/app_route.dart';

// class SplashController extends GetxController {
//   var opacity = 0.0.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     _startAnimation();
//   }

//   void _startAnimation() async {
//     // Start fade-in animation
//     await Future.delayed(const Duration(milliseconds: 500));
//     opacity.value = 1.0;

//     // 🔧 FIX: Wait for auto-login to complete before navigating
//     await _checkAuthAndNavigate();
//   }

//   // 🔧 NEW: Proper auto-login handling
// Future<void> _checkAuthAndNavigate() async {
//   try {
//     final authService = Get.find<AuthService>();

//     // Wait minimum splash duration
//     await Future.delayed(const Duration(seconds: 2));

//     // ✅ Just trigger checkAutoLogin directly — it handles navigation itself
//     // Don't wait in a loop — that's the race condition
//     if (!authService.hasCheckedAutoLogin.value) {
//       await authService.checkAutoLogin();
//     }
//     // If already checked, navigation already happened — do nothing

//   } catch (e) {
//     debugPrint('❌ Splash error: $e');
//     Get.offAllNamed(AppRoute.login);
//   }
// }
// }



import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:majan/core/routes/app_route.dart';
import 'package:majan/presentation/view_model/firebase_auth_controller.dart';

class SplashController extends GetxController {
  var opacity = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _startAnimation();
  }

  void _startAnimation() async {
    // Start fade-in animation
    await Future.delayed(const Duration(milliseconds: 500));
    opacity.value = 1.0;

    // 🔧 FIX: Wait for auto-login to complete before navigating
    await _checkAuthAndNavigate();
  }

  // 🔧 NEW: Proper auto-login handling
// SplashController
// Future<void> _checkAuthAndNavigate() async {
//   try {
//     final authService = Get.find<AuthService>();
//     // Give Firebase time to initialize before we even ask
//     await Future.delayed(const Duration(seconds: 1));
//     await authService.checkAutoLogin();
//   } catch (e) {
//     debugPrint('❌ Splash error: $e');
//     Get.offAllNamed(AppRoute.login);
//   }
// }

Future<void> _checkAuthAndNavigate() async {
  try {
    final authService = Get.find<AuthService>();
    // checkAutoLogin handles all waiting internally (up to 10s for release
    // builds). No artificial delay needed here.
    await authService.checkAutoLogin();
  } catch (e) {
    debugPrint('❌ Splash error: $e');
    Get.offAllNamed(AppRoute.login);
  }
}

}