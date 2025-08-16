import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/routes/app_route.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../view_model/localization_controller.dart';
import 'custom_elevated_button.dart';
import 'custom_text_widget.dart';

class SignupWarningScreen extends StatelessWidget {
  SignupWarningScreen({super.key});
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
                'assets/lottie/signup_warning.json',
                width: screenWidth * 0.5,
                height: screenHeight * 0.3,
                fit: BoxFit.contain,
                repeat: true,
                animate: true,
              ),

              SizedBox(height: screenHeight * 0.04),

              // Gradient Title Text
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: CustomTextWidget(
                  title:
                      localizationController.translate('sign_up_warning_title'),
                  fontSize: popularPlaceTitle * 1.3,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Description Text
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: CustomTextWidget(
                  title: localizationController
                      .translate('sign_up_warning_subtitle'),
                  fontSize: tagTitle * 1.1,
                  color: Colors.grey.shade700,
                  textAlign: TextAlign.center,
                  maxLines: 5,
                ),
              ),

              SizedBox(height: screenHeight * 0.05),

              // Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Sign In Button
                  CustomButtonWidget(
                    buttonTitle: localizationController.translate('sign_in'),
                    buttonColor: AppColors.primaryColor,
                    buttonTextColor: Colors.black,
                    buttonHeight: screenHeight * 0.06,
                    buttonWidth: screenWidth * 0.4,
                    onPressed: () {
                      // Navigate to Sign In
                      Get.offNamed(AppRoute.login);
                    },
                  ),
                  SizedBox(width: screenWidth * 0.05),

                  // Sign Up Button
                  // OutlinedButton(
                  //   style: OutlinedButton.styleFrom(
                  //     side: BorderSide(color: AppColors.primaryColor, width: 2),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(30),
                  //     ),
                  //     padding: EdgeInsets.symmetric(
                  //       horizontal: screenWidth * 0.08,
                  //       vertical: screenHeight * 0.02,
                  //     ),
                  //   ),
                  //   onPressed: () {
                  //     // Navigate to Sign Up
                  //   },
                  //   child: Text(
                  //     "Sign Up",
                  //     style: TextStyle(
                  //       color: Colors.black,
                  //       fontSize: tagTitle,
                  //       fontWeight: FontWeight.bold,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
