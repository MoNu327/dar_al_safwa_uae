import 'package:majan/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:majan/presentation/view_model/splash_controller.dart';

class SplashScreen extends StatelessWidget {
  final SplashController controller = Get.put(SplashController());

  SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackgroundColor,
      body: Center(
        child: Obx(() => AnimatedOpacity(
              duration: const Duration(seconds: 5),
              opacity: controller.opacity.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo/launcher1.png',
                    width: Get.width * 0.5,
                  ),
                ],
              ),
            )),
      ),
    );
  }
}
