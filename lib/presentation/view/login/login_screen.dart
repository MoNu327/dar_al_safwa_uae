import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/presentation/view/dashboard/widgets/technician_dashboard.dart';
import 'package:majan/presentation/view/property_details/controller/property_details_controller.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import '../../view_model/firebase_auth_controller.dart';
import '../../view_model/localization_controller.dart';
import '../../view_model/login_controller.dart';
import '../../widgets/language_text_button.dart';
class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final LocalizationController localizationController = Get.find();
  final LoginController loginController = Get.put(LoginController());
  final AuthService authService = Get.put(AuthService());

  @override
  Widget build(BuildContext context) {
    debugPrint("🔄 LoginScreen build started.");

    // Set the status bar icon color
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light, // For Android
      statusBarBrightness: Brightness.light, // For iOS
    ));

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            spacing: Get.height * 0.01,
            children: [
              Obx(() {
                final imageUrl = loginController.image.value;
                debugPrint("📸 Login image URL: $imageUrl");
                if (imageUrl == null || imageUrl.isEmpty) {
                  debugPrint("⚠ No image found. Showing empty container.");
                  return Container(
                    width: double.infinity,
                    height: Get.height * 0.5,
                  );
                }

                return CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: Get.height * 0.5,
                  fit: BoxFit.cover,
                );
              }),
              Stack(
                children: [
                  Center(
                    child: Image.asset(
                      "assets/logo/launcher.png",
                      width: Get.width * 0.3,
                      height: Get.height * 0.1,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    top: 0,
                    right: 0,
                    child: LanguageTextButton(
                      localizationController: localizationController,
                    ),
                  ),
                ],
              ),
              CustomButton(
                textSize: H18,
                color: AppColors.black,
                titleColor: AppColors.white,
                title: localizationController
                    .translate('continue_with_mobile_number'),
                onPressed: () {
                  debugPrint("➡ Continue with Mobile Number clicked.");
                  loginController.navigateToMobileLogin();
                },
              ),
              CustomTextWidget(
                title: localizationController.translate('OR'),
                color: AppColors.black600,
                fontWeight: FontWeight.w700,
              ),
              if (Platform.isIOS) ...[
                // iOS: Both Apple and Google logos in same Row
                Row(
                  children: [
                    // Apple Sign In Button (Icon only)
                    Expanded(
                      child: Obx(() {
                        return CustomButton(
                          color: AppColors.black,
                          titleColor: AppColors.white,
                          textSize: tagTitle,
                          title: 'Apple Sign In', // No text, just icon
                          onPressed: () {
                            if (!authService.isSignInApple.value) {
                              authService.signInWithApple();
                            }
                          },
                          customIconWidget: authService.isSignInApple.value
                              ? CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                )
                              : Image.asset(
                                  "assets/images/apple.png",
                                  width: Get.height * 0.025,
                                  height: Get.height * 0.025,
                                  fit: BoxFit.cover,
                                ),
                        );
                      }),
                    ),

                    SizedBox(width: 12),

                    // Google Sign In Button (Icon only)
                    Expanded(
                      child: Obx(() {
                        return CustomButton(
                          textSize: tagTitle,
                          title: 'Google Sign in', // No text, just icon
                          onPressed: () {
                            if (!authService.isSignInGoogle.value &&
                                !loginController.isGoogleSigningIn.value) {
                              loginController.isGoogleSigningIn.value = true;
                              authService.signInWithGoogle().whenComplete(() {
                                loginController.isGoogleSigningIn.value = false;
                              });
                            }
                          },
                          customIconWidget:
                              loginController.isGoogleLoading.value
                                  ? CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    )
                                  : Image.asset(
                                      "assets/logo/google.png",
                                      width: Get.height * 0.035,
                                      height: Get.height * 0.035,
                                      fit: BoxFit.cover,
                                    ),
                        );
                      }),
                    ),
                  ],
                ),
              ] else ...[
                // Android: Google Sign In with full text
                Obx(() {
                  debugPrint(
                      "🔄 Google Login Loading: ${loginController.isGoogleLoading.value}");
                  return CustomButton(
                    textSize: H18,
                    title: authService.isSignInGoogle.value
                        ? localizationController.translate('loading')
                        : localizationController.translate('login_with_google'),
                    onPressed: () {
                      if (!authService.isSignInGoogle.value &&
                          !loginController.isGoogleSigningIn.value) {
                        loginController.isGoogleSigningIn.value = true;
                        authService.signInWithGoogle().whenComplete(() {
                          loginController.isGoogleSigningIn.value = false;
                        });
                      }
                    },
                    customIconWidget: loginController.isGoogleLoading.value
                        ? const SizedBox.shrink()
                        : Image.asset(
                            "assets/logo/google.png",
                            width: Get.height * 0.035,
                            height: Get.height * 0.035,
                            fit: BoxFit.cover,
                          ),
                  );
                }),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: CustomButton(
                      iconSize: 14,
                      title: "Continue As Guest",
                      textSize: tagTitle,
                      onPressed: () {
                        debugPrint("➡ Continue As Guest clicked.");
                        authService.navigateGuestToHome();
                      },
                      customIconWidget: const Icon(Icons.person),
                    ),
                  ),
                  // const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      iconSize: 14,
                      customIconWidget: const Icon(Icons.build),
                      title: "Technician Login",
                      textSize: tagTitle,
                      onPressed: () {
                        debugPrint("➡ Technician Login clicked.");
                        loginController.navigateToTechnicianLogin();
                      },
                    ),
                  ),
                ],
              ),
              kHeight(0.005),
              _buildSignupTextButton(),
              kHeight(0.005),
            ],
          ),
        ),
      ),
    );
  }

  // reusable widget for signup text button
  Widget _buildSignupTextButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomTextWidget(
          title: "Are you an agent?",
          color: AppColors.black,
          fontSize: popularPlaceTitle,
        ),
        InkWell(
          onTap: () {
            debugPrint("➡ Agent Login/Signup clicked.");
            loginController.navigateToAgentLogin();
          },
          child: CustomTextWidget(
            title: "  Log In / Sign Up",
            color: AppColors.blueColor,
            fontSize: Get.height * 0.015,
          ),
        )
      ],
    );
  }
}

class CustomButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final Color? color;
  final double? textSize;
  final double? iconSize;
  final Color? titleColor;
  final Widget? customIconWidget;

  const CustomButton({
    required this.title,
    required this.onPressed,
    super.key,
    this.color,
    this.titleColor,
    this.customIconWidget,
    this.iconSize = 25,
    this.textSize,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint("🔘 Building CustomButton with title: $title");
    return InkWell(
      onTap: () {
        debugPrint("🔘 Button clicked: $title");
        onPressed();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          height: Get.height * 0.07,
          decoration: ShapeDecoration(
            color: color ?? AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
              side: const BorderSide(color: AppColors.black),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              customIconWidget ??
                  Icon(
                    Icons.phone_android_rounded,
                    size: iconSize,
                  ),
              const SizedBox(width: 3),
              CustomTextWidget(
                title: title,
                fontSize: textSize ?? Get.height * 0.03,
                color: titleColor ?? AppColors.black,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}