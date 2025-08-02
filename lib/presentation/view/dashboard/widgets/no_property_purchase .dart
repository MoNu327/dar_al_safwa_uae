import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_elevated_button.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../controllers/bottom_navbar_controller.dart';
import '../../../view_model/localization_controller.dart';

class NoPropertyPurchaseScreen extends StatelessWidget {
  NoPropertyPurchaseScreen({super.key});

  final BottomNavbarController bottomNavbarController =
      Get.find<BottomNavbarController>();
  LocalizationController localizationController =
      Get.find<LocalizationController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.03,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation
              Lottie.asset(
                'assets/lottie/no_purchase.json',
                width: screenWidth * 0.5,
                height: screenHeight * 0.3,
                fit: BoxFit.contain,
                repeat: true,
                animate: true,
              ),

              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: CustomTextWidget(
                  title: localizationController.translate('no_property_title'),
                  fontSize: popularPlaceTitle,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),

              SizedBox(height: screenHeight * 0.02),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: CustomTextWidget(
                  title:
                      localizationController.translate('no_property_subtitle'),
                  fontSize: tagTitle,
                  color: Colors.grey.shade700,
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: screenHeight * 0.05),
              CustomButtonWidget(
                buttonTitle:
                    localizationController.translate('explore_property'),
                buttonColor: AppColors.primaryColor,
                buttonTextColor: AppColors.black,
                // borderColor: AppColors.warning,
                onPressed: () {
                  bottomNavbarController.goToNavbarIndex(0);
                  // Get.offNamed(AppRoute.login);
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
