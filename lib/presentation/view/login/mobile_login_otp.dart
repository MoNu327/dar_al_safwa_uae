import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/presentation/view_model/localization_controller.dart';
import 'package:majan/presentation/view_model/mobile_login_controller.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/presentation/widgets/language_text_button.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

import '../../view_model/firebase_auth_controller.dart';
import '../../widgets/custom_elevated_button.dart';

class MobileLoginOtp extends StatelessWidget {
  MobileLoginOtp({super.key});

  final LocalizationController localizationController = Get.find();
  final MobileLoginController mobileLoginController =
      Get.put(MobileLoginController());
  final TextEditingController otpController = TextEditingController();
  final AuthService authService = Get.put(AuthService());

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};

    final verificationId = args['verificationId'] ?? '';
    final phoneNumber = args['phoneNumber'] ?? '';
    final resendToken = args['resendToken'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          // <-- Added ScrollView
          physics:
              const BouncingScrollPhysics(), // Optional: For iOS-like bounce effect
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Get.width * 0.05,
              vertical: Get.height * 0.05,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: screenHeight2,
              children: [
                _buildHeader(),
                const Divider(),
                _buildTitleAndSubtitle(),
                _buildOtpInput(),
                SizedBox(
                    height:
                        Get.height * 0.01), // Replaced kHeight with SizedBox
                Obx(() {
                  return CustomButtonWidget(
                    childWidgetLoader: authService.isVerifyPhone.value,
                    buttonTextColor: AppColors.primaryColor,
                    buttonColor: AppColors.black,
                    buttonTitle: 'Sign In',
                    onPressed: () {
                      debugPrint("mobile no:$phoneNumber");
                      authService.isVerifyPhone.value
                          ? null
                          : authService.verifyPhoneNumber(
                              verificationId: verificationId,
                              smsCode: otpController.text.trim());
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Header with back button and language button
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildBackButton(),
        LanguageTextButton(localizationController: localizationController),
      ],
    );
  }

  // Reusable method to build back button
  Widget _buildBackButton() {
    return InkWell(
      onTap: () {
        mobileLoginController.navigateToBack();
      },
      borderRadius: BorderRadius.circular(50),
      splashColor: AppColors.splashBackgroundColor,
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: AppColors.whiteLight,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_sharp,
          color: AppColors.black800,
          size: 28,
        ),
      ),
    );
  }

  // Title and subtitle section
  Widget _buildTitleAndSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: localizationController.translate('verify_mobile_number'),
          color: AppColors.black,
          fontWeight: FontWeight.w500,
          fontSize: Get.height * 0.03,
        ),
        SizedBox(height: Get.height * 0.01),
        CustomTextWidget(
          title: localizationController.translate("enter_the_code_for_verify"),
          fontSize: Get.height * 0.02,
          color: AppColors.lightGrey,
          maxLines: 2,
        )
      ],
    );
  }

  // OTP input section using Pinput
  Widget _buildOtpInput() {
    return Pinput(
      length: 6,
      controller: otpController,
      keyboardType: TextInputType.number,
      onCompleted: (pin) {
        // You can handle OTP verification here when the user completes the input
        debugPrint("Entered OTP: $pin");
      },
      onChanged: (pin) {
        // You can handle changes to the OTP input here
        debugPrint("Current OTP: $pin");
      },
      defaultPinTheme: PinTheme(
        width: 50,
        height: 50,
        textStyle: TextStyle(
          fontSize: Get.height * 0.03,
          color: AppColors.black,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.lightGrey),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Full width verify button at the bottom
  Widget _buildVerifyButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: Get.height * 0.005),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: () {
          mobileLoginController.navigateToHome();
        },
        child: CustomTextWidget(
          title: localizationController.translate('verify'),
          fontSize: Get.height * 0.02,
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
