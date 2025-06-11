// import 'package:country_code_picker/country_code_picker.dart';
// import 'package:dar_al_safwa/presentation/view_model/localization_controller.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:dar_al_safwa/presentation/view_model/localization_controller.dart';
import 'package:dar_al_safwa/presentation/view_model/mobile_login_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/language_text_button.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/custom_size.dart';
import '../../view_model/firebase_auth_controller.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_formfield_widget.dart';

class MobileLoginScreen extends StatelessWidget {
  MobileLoginScreen({super.key});

  final LocalizationController _localizationController = Get.find();
  final MobileLoginController _mobileLoginController =
      Get.put(MobileLoginController());
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();

  final AuthService authService = Get.put(AuthService());
  final FirebaseAuth auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    final screenHeight = Get.height;
    final screenWidth = Get.width;
    final horizontalPadding = screenWidth * 0.05;
    final verticalPadding = screenHeight * 0.05;

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
                  minHeight: constraints.maxHeight - verticalPadding * 2,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: screenHeight2,
                    children: [
                      _buildHeader(),
                      const Divider(),
                      _buildTitleAndSubtitle(screenHeight),
                      // CustomTextFieldWidget(
                      //   hintText:
                      //       _localizationController.translate('full_name'),
                      //   labelText:
                      //       _localizationController.translate('full_name'),
                      //   keyboardType: TextInputType.name,
                      //   controller: authService.fullNameController,
                      //   // inputFormatters: const [],
                      //   // obscureText: false,
                      //   // suffixIcon: false,
                      //   // validator: (value) {},
                      //   // onChanged: (value) {},
                      //   labelTextColor: AppColors.black,
                      // ),
                      _buildMobileInputField(screenWidth, screenHeight),
                      kHeight(0.01),
                      Obx(() {
                        return CustomButtonWidget(
                          childWidgetLoader: authService.isSignInPhone.value,
                          buttonTextColor: AppColors.primaryColor,
                          buttonColor: AppColors.black,
                          buttonTitle: 'Sign In',
                          onPressed: () {
                            final phoneNumber =
                                '${_mobileLoginController.selectedCountryCode.value}${_mobileNumberController.text.trim()}';
                            debugPrint("mobile no:$phoneNumber");
                            authService.isSignInPhone.value
                                ? null
                                : authService.signInWithPhone(
                                    phoneNumber: phoneNumber,
                                    onVerificationCompleted:
                                        (PhoneAuthCredential credential) {},
                                    onVerificationFailed:
                                        (FirebaseAuthException e) {
                                      Get.snackbar('Error',
                                          e.message ?? 'Verification failed');
                                    },
                                    onCodeSent: (String verificationId,
                                        int? resendToken) {
                                      authService.isSignInPhone(false);
                                      // Navigate to OTP screen
                                      Get.toNamed(AppRoute.mobileLoginOtp,
                                          arguments: {
                                            'verificationId': verificationId,
                                            'phoneNumber': phoneNumber,
                                            'resendToken': resendToken,
                                          });
                                    },
                                    onCodeAutoRetrievalTimeout:
                                        (String verificationId) {
                                      // Handle timeout if needed
                                    },
                                  );
                          },
                        );
                      }),
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
          title: _localizationController.translate('login_with_mobile_number'),
          color: AppColors.black,
          fontWeight: FontWeight.w500,
          fontSize: screenHeight * 0.03,
        ),
        SizedBox(height: screenHeight * 0.01),
        CustomTextWidget(
          title: _localizationController
              .translate("please_enter_your_mobile_number_correctly"),
          fontSize: screenHeight * 0.02,
          color: AppColors.lightGrey,
        ),
      ],
    );
  }

  Widget _buildMobileInputField(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: _localizationController.translate("mobile_number"),
          color: AppColors.black,
          fontSize: popularPlaceTitle,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: screenHeight * 0.005),
        Row(
          children: [
            Obx(
              () => Container(
                width: screenWidth * 0.25,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.black500),
                ),
                child: CountryCodePicker(
                  initialSelection:
                      _mobileLoginController.selectedCountryCode.value.isEmpty
                          ? '+968' // Default to Oman if no selection
                          : _mobileLoginController.selectedCountryCode.value,
                  onChanged: _mobileLoginController.changeCountryCode,
                  // Only these two countries will be shown
                  countryFilter: const ['OM', 'AE', 'US'],
                  // These will appear at the top (though only these exist)
                  // favorite: const ['+968', '+971'],
                  // UI configurations

                  hideSearch: true,
                  showDropDownButton: true,
                  padding: EdgeInsets.zero,
                  showFlag: true,
                  showFlagDialog: true,
                  showCountryOnly: false,
                  showOnlyCountryWhenClosed: false,
                  flagWidth: screenWidth * 0.05,
                  headerText: 'Select Country Code',
                  headerTextStyle: GoogleFonts.poppins(
                    color: AppColors.black,
                    fontSize: screenHeight * 0.01,
                  ),
                  textStyle: GoogleFonts.poppins(
                    color: AppColors.black,
                    fontSize: screenHeight * 0.012,
                  ),
                  headerAlignment: MainAxisAlignment.spaceBetween,
                  textOverflow: TextOverflow.clip,
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Expanded(
              child: TextField(
                controller: _mobileNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: _localizationController.translate('mobile_number'),
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
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.redColor,
                      width: 1.0,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.redColor,
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget _buildLoginButton(double screenHeight) {
  //   return SizedBox(
  //     width: double.infinity,
  //     child: ElevatedButton(
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: AppColors.black,
  //         padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //       ),
  //       onPressed: _mobileLoginController.navigateToMobileLoginOtp,
  //       child: CustomTextWidget(
  //         title: _localizationController.translate('login'),
  //         fontSize: screenHeight * 0.02,
  //         color: AppColors.white,
  //         fontWeight: FontWeight.w600,
  //       ),
  //     ),
  //   );
  // }
}

// import 'package:dar_al_safwa/presentation/view_model/mobile_login_controller.dart';
// import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
// import 'package:dar_al_safwa/presentation/widgets/language_text_button.dart';
// import 'package:dar_al_safwa/core/theme/app_colors.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';

// class MobileLoginScreen extends StatelessWidget {
//   MobileLoginScreen({super.key});

//   final LocalizationController localizationController = Get.find();
//   final MobileLoginController mobileLoginController =
//       Get.put(MobileLoginController());

//   final TextEditingController mobileNumberController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.symmetric(
//             horizontal: Get.width * 0.05,
//             vertical: Get.height * 0.05,
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildHeader(),
//               SizedBox(height: Get.height * 0.01),
//               const Divider(),
//               SizedBox(height: Get.height * 0.02),
//               _buildTitleAndSubtitle(),
//               SizedBox(height: Get.height * 0.02),
//               _buildMobileInputField(
//                   hintText: localizationController.translate('mobile_number'),
//                   mobileNumberController: mobileNumberController),
//               const Spacer(),
//               _buildLoginButton(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Header with back button and language button
//   Widget _buildHeader() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         _buildBackButton(),
//         LanguageTextButton(localizationController: localizationController),
//       ],
//     );
//   }

//   // Reusable method to build back button
//   Widget _buildBackButton() {
//     return InkWell(
//       onTap: () {
//         mobileLoginController.navigateToBack();
//       },
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

//   // Title and subtitle section
//   Widget _buildTitleAndSubtitle() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         CustomTextWidget(
//           title: localizationController.translate('login_with_mobile_number'),
//           color: AppColors.black,
//           fontWeight: FontWeight.w500,
//           fontSize: Get.height * 0.03,
//         ),
//         SizedBox(height: Get.height * 0.01),
//         CustomTextWidget(
//           title: localizationController
//               .translate("please_enter_your_mobile_number_correctly"),
//           fontSize: Get.height * 0.02,
//           color: AppColors.lightGrey,
//         )
//       ],
//     );
//   }

//   Widget _buildMobileInputField({
//     required String hintText,
//     required TextEditingController mobileNumberController,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         SizedBox(height: Get.height * 0.005),
//         Row(
//           children: [
//             Obx(
//               () => Container(
//                 width: Get.width * 0.27,
//                 // padding: EdgeInsets.symmetric(horizontal: Get.width * 0.0),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: AppColors.lightGrey),
//                 ),
//                 child: CountryCodePicker(
//                   initialSelection:
//                       mobileLoginController.selectedCountryCode.value.isEmpty
//                           ? '+1'
//                           : mobileLoginController.selectedCountryCode.value,
//                   onChanged: (CountryCode code) {
//                     mobileLoginController.changeCountryCode(code);
//                   },
//                   showDropDownButton: true,
//                   padding: EdgeInsets.zero,
//                   showFlag: true,
//                   showFlagDialog: true,
//                   showCountryOnly: false,
//                   showOnlyCountryWhenClosed: false,
//                   // alignLeft: true,
//                   flagWidth: Get.width * 0.05,
//                   headerText: 'Select Country Code',
//                   headerTextStyle: GoogleFonts.poppins(
//                     color: AppColors.black,
//                     fontSize: Get.height * 0.02,
//                   ),
//                   textStyle: GoogleFonts.poppins(
//                     color: AppColors.black,
//                     fontSize: Get.height * 0.02,
//                   ),
//                   headerAlignment: MainAxisAlignment.spaceBetween,
//                   textOverflow: TextOverflow.clip,
//                 ),
//               ),
//             ),
//             SizedBox(width: Get.width * 0.02),
//             Expanded(
//               child: TextField(
//                 controller: mobileNumberController,
//                 keyboardType: TextInputType.phone,
//                 decoration: InputDecoration(
//                   hintText: hintText,
//                   hintStyle: GoogleFonts.poppins(
//                     color: AppColors.lightGrey,
//                   ),
//                   contentPadding: EdgeInsets.symmetric(
//                     vertical: Get.height * 0.015,
//                     horizontal: Get.width * 0.05,
//                   ),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: const BorderSide(color: AppColors.lightGrey),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: const BorderSide(color: AppColors.primaryColor),
//                   ),
//                 ),
//               ),
//             )
//           ],
//         )
//       ],
//     );
//   }

//   // Full width login button at the bottom
//   Widget _buildLoginButton() {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.symmetric(vertical: Get.height * 0.005),
//       decoration: BoxDecoration(
//         color: AppColors.black,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: TextButton(
//         onPressed: () {
//           mobileLoginController.navigateToMobileLoginOtp();
//         },
//         child: CustomTextWidget(
//           title: localizationController.translate('login'),
//           fontSize: Get.height * 0.02,
//           color: AppColors.white,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }
// }
