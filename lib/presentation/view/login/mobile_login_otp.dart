// import 'package:dar_al_safwa/core/constants/custom_size.dart';
// import 'package:dar_al_safwa/presentation/view_model/localization_controller.dart';
// import 'package:dar_al_safwa/presentation/view_model/mobile_login_controller.dart';
// import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
// import 'package:dar_al_safwa/presentation/widgets/language_text_button.dart';
// import 'package:dar_al_safwa/core/theme/app_colors.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:pinput/pinput.dart';

// import '../../widgets/custom_elevated_button.dart';

// class MobileOtpScreen extends StatelessWidget {
//   MobileOtpScreen({super.key});

//   final LocalizationController _localizationController = Get.find();
//   final MobileLoginController _mobileLoginController = Get.find();
  
//   // Get phone number from arguments
//   final String phoneNumber = Get.arguments?['phoneNumber'] ?? '';

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = Get.height;
//     final screenWidth = Get.width;
//     final horizontalPadding = screenWidth * 0.05;
//     final verticalPadding = screenHeight * 0.05;

//     return Scaffold(
//       backgroundColor: AppColors.white,
//       body: SafeArea(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return SingleChildScrollView(
//               padding: EdgeInsets.symmetric(
//                 horizontal: horizontalPadding,
//                 vertical: verticalPadding,
//               ),
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(
//                   minHeight: constraints.maxHeight - verticalPadding * 2,
//                 ),
//                 child: IntrinsicHeight(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     spacing: screenHeight * 0.03,
//                     children: [
//                       _buildHeader(),
//                       const Divider(),
//                       _buildTitleAndSubtitle(screenHeight),
//                       _buildNameInputField(screenWidth, screenHeight),
//                       _buildOtpInputField(screenHeight),
//                       _buildResendSection(screenHeight),
//                       kHeight(0.01),
//                       Obx(() {
//                         return CustomButtonWidget(
//                           childWidgetLoader: _mobileLoginController.isLoading.value,
//                           buttonTextColor: AppColors.primaryColor,
//                           buttonColor: AppColors.black,
//                           buttonTitle: 'Verify OTP',
//                           onPressed: _mobileLoginController.isLoading.value
//                               ? null
//                               : _mobileLoginController.verifyOtp,
//                         );
//                       }),
//                       const Spacer(),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         _buildBackButton(),
//         LanguageTextButton(localizationController: _localizationController),
//       ],
//     );
//   }

//   Widget _buildBackButton() {
//     return InkWell(
//       onTap: _mobileLoginController.navigateToBack,
//       borderRadius: BorderRadius.circular(50),
//       splashColor: AppColors.splashBackgroundColor,
//       child: Container(
//         width: 50,
//         height: 50,
//         decoration: const BoxDecoration(
//           color: AppColors.whiteLight,
//           shape: BoxShape.circle,
//         ),
//         child: const Icon(
//           Icons.arrow_back_sharp,
//           color: AppColors.black800,
//           size: 28,
//         ),
//       ),
//     );
//   }

//   Widget _buildTitleAndSubtitle(double screenHeight) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         CustomTextWidget(
//           title: 'Verify OTP',
//           color: AppColors.black,
//           fontWeight: FontWeight.w500,
//           fontSize: screenHeight * 0.03,
//         ),
//         SizedBox(height: screenHeight * 0.01),
//         CustomTextWidget(
//           title: 'We have sent a verification code to\n$phoneNumber',
//           fontSize: screenHeight * 0.018,
//           color: AppColors.lightGrey,
//         ),
//       ],
//     );
//   }

//   Widget _buildNameInputField(double screenWidth, double screenHeight) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         CustomTextWidget(
//           title: 'Full Name (for new users)',
//           color: AppColors.black,
//           fontSize: popularPlaceTitle,
//           fontWeight: FontWeight.w500,
//         ),
//         SizedBox(height: screenHeight * 0.005),
//         TextField(
//           controller: _mobileLoginController.fullNameController,
//           keyboardType: TextInputType.name,
//           textCapitalization: TextCapitalization.words,
//           decoration: InputDecoration(
//             hintText: 'Enter your full name',
//             hintStyle: GoogleFonts.poppins(
//               color: AppColors.lightGrey,
//             ),
//             contentPadding: EdgeInsets.symmetric(
//               vertical: screenHeight * 0.015,
//               horizontal: screenWidth * 0.05,
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: AppColors.lightGrey),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: AppColors.primaryColor),
//             ),
//           ),
//         ),
//         SizedBox(height: screenHeight * 0.005),
//         CustomTextWidget(
//           title: 'Only required for first-time registration',
//           fontSize: screenHeight * 0.014,
//           color: AppColors.lightGrey,
//         ),
//       ],
//     );
//   }

//   Widget _buildOtpInputField(double screenHeight) {
//     final defaultPinTheme = PinTheme(
//       width: 56,
//       height: 60,
//       textStyle: GoogleFonts.poppins(
//         fontSize: 22,
//         color: AppColors.black,
//         fontWeight: FontWeight.w600,
//       ),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.lightGrey),
//       ),
//     );

//     final focusedPinTheme = defaultPinTheme.copyWith(
//       decoration: defaultPinTheme.decoration?.copyWith(
//         border: Border.all(color: AppColors.primaryColor, width: 2),
//       ),
//     );

//     final submittedPinTheme = defaultPinTheme.copyWith(
//       decoration: defaultPinTheme.decoration?.copyWith(
//         color: AppColors.primaryColor.withOpacity(0.1),
//         border: Border.all(color: AppColors.primaryColor),
//       ),
//     );

//     final errorPinTheme = defaultPinTheme.copyWith(
//       decoration: defaultPinTheme.decoration?.copyWith(
//         border: Border.all(color: AppColors.redColor),
//       ),
//     );

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         CustomTextWidget(
//           title: 'Enter OTP',
//           color: AppColors.black,
//           fontSize: popularPlaceTitle,
//           fontWeight: FontWeight.w500,
//         ),
//         SizedBox(height: screenHeight * 0.01),
//         Pinput(
//           controller: _mobileLoginController.otpController,
//           length: 6,
//           defaultPinTheme: defaultPinTheme,
//           focusedPinTheme: focusedPinTheme,
//           submittedPinTheme: submittedPinTheme,
//           errorPinTheme: errorPinTheme,
//           keyboardType: TextInputType.number,
//           inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//           hapticFeedbackType: HapticFeedbackType.lightImpact,
//           onCompleted: (pin) {
//             debugPrint('OTP entered: $pin');
//           },
//           onChanged: (value) {
//             debugPrint('OTP changed: $value');
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildResendSection(double screenHeight) {
//     return Obx(() {
//       final canResend = _mobileLoginController.canResend;
//       final secondsRemaining = _mobileLoginController.resendSecondsRemaining;

//       return Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CustomTextWidget(
//             title: "Didn't receive the code? ",
//             fontSize: screenHeight * 0.016,
//             color: AppColors.lightGrey,
//           ),
//           if (canResend)
//             InkWell(
//               onTap: _mobileLoginController.resendOtp,
//               child: CustomTextWidget(
//                 title: "Resend",
//                 fontSize: screenHeight * 0.016,
//                 color: AppColors.primaryColor,
//                 fontWeight: FontWeight.w600,
//               ),
//             )
//           else
//             CustomTextWidget(
//               title: "Resend in ${secondsRemaining}s",
//               fontSize: screenHeight * 0.016,
//               color: AppColors.lightGrey,
//             ),
//         ],
//       );
//     });
//   }
// }



import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/presentation/view_model/localization_controller.dart';
import 'package:majan/presentation/view_model/mobile_login_controller.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/presentation/widgets/language_text_button.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

import '../../widgets/custom_elevated_button.dart';

class MobileOtpScreen extends StatelessWidget {
  MobileOtpScreen({super.key});

  final LocalizationController _localizationController = Get.find();
  final MobileLoginController _mobileLoginController = Get.find();
  
  // Get phone number from arguments
  final String phoneNumber = Get.arguments?['phoneNumber'] ?? '';

  @override
  Widget build(BuildContext context) {
    final screenHeight = Get.height;
    final screenWidth = Get.width;
    final horizontalPadding = screenWidth * 0.05;
    final verticalPadding = screenHeight * 0.06;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - verticalPadding * 3,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: screenHeight * 0.03,
                    children: [
                      _buildHeader(),
                      const Divider(),
                      _buildTitleAndSubtitle(screenHeight),
                      _buildNameInputField(screenWidth, screenHeight),
                      _buildOtpInputField(screenHeight),
                      _buildResendSection(screenHeight),
                      kHeight(0.01),
                      Obx(() {
                        return CustomButtonWidget(
                          childWidgetLoader: _mobileLoginController.isVerifying.value,
                          buttonTextColor: AppColors.primaryColor,
                          buttonColor: AppColors.black,
                          buttonTitle: 'Verify OTP',
                          onPressed: _mobileLoginController.isVerifying.value
                              ? null
                              : _mobileLoginController.verifyOtp,
                        );
                      }),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildBackButton(),
        LanguageTextButton(localizationController: _localizationController),
      ],
    );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: _mobileLoginController.navigateToBack,
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

  Widget _buildTitleAndSubtitle(double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: 'Verify OTP',
          color: AppColors.black,
          fontWeight: FontWeight.w500,
          fontSize: screenHeight * 0.03,
        ),
        SizedBox(height: screenHeight * 0.01),
        CustomTextWidget(
          title: 'We have sent a verification code to\n$phoneNumber',
          fontSize: screenHeight * 0.018,
          color: AppColors.lightGrey,
        ),
      ],
    );
  }

  Widget _buildNameInputField(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: 'Full Name (for new users)',
          color: AppColors.black,
          fontSize: popularPlaceTitle,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: screenHeight * 0.005),
        TextField(
          controller: _mobileLoginController.fullNameController,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            hintStyle: GoogleFonts.poppins(
              color: AppColors.lightGrey,
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.015,
              horizontal: screenWidth * 0.05,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryColor),
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.005),
        CustomTextWidget(
          title: 'Only required for first-time registration',
          fontSize: screenHeight * 0.014,
          color: AppColors.lightGrey,
        ),
      ],
    );
  }

  Widget _buildOtpInputField(double screenHeight) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: GoogleFonts.poppins(
        fontSize: 22,
        color: AppColors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: AppColors.primaryColor, width: 2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: AppColors.primaryColor.withOpacity(0.1),
        border: Border.all(color: AppColors.primaryColor),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: AppColors.redColor),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: 'Enter OTP',
          color: AppColors.black,
          fontSize: popularPlaceTitle,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: screenHeight * 0.01),
        Pinput(
          controller: _mobileLoginController.otpController,
          length: 6,
          defaultPinTheme: defaultPinTheme,
          focusedPinTheme: focusedPinTheme,
          submittedPinTheme: submittedPinTheme,
          errorPinTheme: errorPinTheme,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          hapticFeedbackType: HapticFeedbackType.lightImpact,
          onCompleted: (pin) {
            debugPrint('OTP entered: $pin');
          },
          onChanged: (value) {
            debugPrint('OTP changed: $value');
          },
        ),
      ],
    );
  }

  Widget _buildResendSection(double screenHeight) {
    return Obx(() {
      final canResend = _mobileLoginController.canResend.value;
      final secondsRemaining = _mobileLoginController.resendSecondsRemaining.value;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomTextWidget(
            title: "Didn't receive the code? ",
            fontSize: screenHeight * 0.016,
            color: AppColors.lightGrey,
          ),
          if (canResend)
            InkWell(
              onTap: _mobileLoginController.resendOtp,
              child: CustomTextWidget(
                title: "Resend",
                fontSize: screenHeight * 0.016,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            CustomTextWidget(
              title: "Resend in ${secondsRemaining}s",
              fontSize: screenHeight * 0.016,
              color: AppColors.lightGrey,
            ),
        ],
      );
    });
  }
}