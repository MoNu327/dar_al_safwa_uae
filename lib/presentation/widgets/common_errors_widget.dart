import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:dar_al_safwa/presentation/view_model/localization_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../core/theme/app_colors.dart';
import 'custom_elevated_button.dart';

class CommonErrorsWidget extends StatelessWidget {
  CommonErrorsWidget({super.key});

  LocalizationController localizationController =
      Get.find<LocalizationController>();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.06,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation
              Lottie.asset(
                'assets/lottie/common_error.json',
                width: screenWidth * 0.6,
                height: screenHeight * 0.25,
                fit: BoxFit.contain,
                repeat: true,
                animate: true,
              ),

              // Gradient Title Text
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: CustomTextWidget(
                  title: localizationController.translate('common_error_title'),
                  fontSize: popularPlaceTitle * 1,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Description Text
              // Description Text with dynamic line wrapping
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: SizedBox(
                  width: double.infinity, // Takes available width
                  child: CustomTextWidget(
                    title: localizationController
                        .translate('common_error_subtitle'),
                    fontSize: tagTitle * 1.2,
                    color: Colors.grey.shade700,
                    textAlign: TextAlign.center,
                    maxLines: 5,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.05),

              // Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Sign In Button
                  CustomButtonWidget(
                    buttonTitle: localizationController.translate('go_to_home'),
                    buttonColor: AppColors.primaryColor,
                    buttonTextColor: Colors.black,
                    buttonHeight: screenHeight * 0.06,
                    buttonWidth: screenWidth * 0.35,
                    onPressed: () {
                      Get.offAllNamed(AppRoute.navbar);
                    },
                  ),
                  SizedBox(width: screenWidth * 0.05),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
