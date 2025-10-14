import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/presentation/view/login/login_screen.dart';
import 'package:majan/presentation/view_model/localization_controller.dart';
import 'package:majan/presentation/view_model/signin_controller.dart';
import 'package:majan/presentation/widgets/custom_snackbar.dart';
import 'package:majan/presentation/widgets/custom_text_formfield_widget.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/presentation/widgets/language_text_button.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../view_model/firebase_auth_controller.dart';
import '../../../widgets/custom_elevated_button.dart';

class SigninScreen extends StatelessWidget {
  SigninScreen({super.key});

  final LocalizationController localizationController = Get.find();
  final SigninController signinController = Get.put(SigninController());
  final AuthService authService = Get.put(AuthService());
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final isAgentSignIn = Get.arguments?['isAgentSignIn'] ?? false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SizedBox(
          height: screenHeight,
          child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Get.width * 0.05,
                        // vertical: Get.height * 0.05,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: Get.height * 0.005,
                          children: [
                            _buildHeader(),
                            Center(
                              child: Image.asset(
                                "assets/logo/launcher.jpg",
                                width: Get.width * 0.3,
                                height: Get.height * 0.1,
                                fit: BoxFit.cover,
                              ),
                            ),
                            CustomTextWidget(
                              title: localizationController
                                  .translate('welcome_back'),
                              color: AppColors.darkGrey,
                              fontSize: Get.height * 0.018,
                            ),
                            // kHeight(0.005),
                            !isAgentSignIn
                                ? CustomTextWidget(
                                    title: localizationController
                                        .translate('Technician Login'),
                                    color: AppColors.secondaryColor,
                                    fontSize: Get.height * 0.018,
                                  )
                                : SizedBox.shrink(),
                            kHeight(0.01),
                            // authService.userRole == 'technician' ?
                            CustomTextFieldWidget(
                                textFieldColor: AppColors.white,
                                isBorderNeeded: true,
                                hintText: localizationController
                                    .translate('email_address'),
                                labelText: localizationController
                                    .translate('email_address'),
                                keyboardType: TextInputType.emailAddress,
                                controller: authService.emailController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  // Trigger validation on change
                                  _formKey.currentState!.validate();
                                },
                                inputFormatters: [
                                  FilteringTextInputFormatter.deny(
                                      RegExp(r'\s')),
                                ],
                                labelTextColor: AppColors.black),
                            Obx(() {
                              return CustomTextFieldWidget(
                                  isBorderNeeded: true,
                                  textFieldColor: AppColors.white,
                                  hintText: localizationController
                                      .translate('password'),
                                  labelText: localizationController
                                      .translate('password'),
                                  keyboardType: TextInputType.text,
                                  controller: authService.passwordController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    }
                                    if (value.length < 8) {
                                      return 'Password must be at least 8 characters';
                                    }
                                    // Check for at least one lowercase letter
                                    if (!RegExp(r'[a-z]').hasMatch(value)) {
                                      return 'Password must contain at least one lowercase letter';
                                    }
                                    // Check for at least one uppercase letter
                                    // if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                    //   return 'Password must contain at least one uppercase letter';
                                    // }
                                    // Check for at least one letter
                                    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
                                      return 'Password must contain at least one letter';
                                    }
                                    // Check for at least one number
                                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                                      return 'Password must contain at least one number';
                                    }
                                    // Check for at least one special character
                                    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]')
                                        .hasMatch(value)) {
                                      return 'Password must contain at least one special character';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    // Trigger validation on change
                                    _formKey.currentState!.validate();
                                  },
                                  inputFormatters: [
                                    FilteringTextInputFormatter.deny(
                                        RegExp(r'\s')),
                                  ],
                                  obscureText:
                                      signinController.isPasswordVisible.value,
                                  suffixIcon: true,
                                  suffixIconOnTap: () {
                                    signinController.togglePasswordVisibility();
                                  },
                                  labelTextColor: AppColors.black);
                            }),

                            Align(
                              alignment: Alignment.center,
                              child: TextButton(
                                onPressed: () {},
                                child: CustomTextWidget(
                                  title:
                                      "${localizationController.translate('forgot_password')} !",
                                  color: AppColors.redColor,
                                  fontSize: H18,
                                ),
                              ),
                            ),
                            // _buildLoginButton(),

                            Obx(() {
                              return CustomButtonWidget(
                                  buttonShape: 'rect',
                                  childWidgetLoader:
                                      authService.isSignInAgent.value,
                                  buttonColor: !isAgentSignIn
                                      ? AppColors.secondaryColor
                                      : AppColors.black,
                                  buttonTitle: 'Login',
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      // Always unfocus keyboard first
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();

                                      if (isAgentSignIn) {
                                        if (!authService.isSignInAgent.value) {
                                          authService.signInAsAgent();
                                        } else {
                                          // Handle case where agent is already signed in
                                          // Get.snackbar('Info', 'Agent already signed in');
                                        }
                                      } else {
                                        if (!authService
                                            .isSignInTechnician.value) {
                                          authService.signInAsTechnician();
                                        } else {
                                          // Handle case where technician is already signed in
                                          // Get.snackbar('Info', 'Technician already signed in');
                                        }
                                      }
                                    }
                                  });
                            }),
                            kHeight(0.01),
                            !isAgentSignIn
                                ? SizedBox.shrink()
                                : _buildSignupTextButton()
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // Header with back button and language button
 Widget _buildBackButton() {
  return IconButton(
    onPressed: () {
      Get.back();
    },
    icon: Icon(
      Icons.arrow_back_ios,
      color: AppColors.black,
      size: Get.height * 0.025,
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
  Widget _buildDummyText() {
    return const Text('');
  }

  // Reusable input field widget
  Widget _buildInputField({
    required String label,
    required String hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.black,
            fontSize: Get.height * 0.02,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: Get.height * 0.005),
        TextField(
          obscureText: obscureText,
          keyboardType: keyboardType ?? TextInputType.text,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(color: AppColors.lightGrey),
            contentPadding: EdgeInsets.symmetric(
              vertical: Get.height * 0.015,
              horizontal: Get.width * 0.05,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryColor),
            ),
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: suffixIcon,
                    onPressed: signinController.togglePasswordVisibility)
                : null,
          ),
        ),
      ],
    );
  }

  // Full width login button at the bottom
  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: Get.height * 0.005),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: authService.signInAsAgent,
        child: CustomTextWidget(
          title: localizationController.translate('login'),
          fontSize: Get.height * 0.02,
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // reusable widget for login text button
  Widget _buildSignupTextButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomTextWidget(
          title: localizationController.translate('dont_have_an_account'),
          color: AppColors.black800,
          fontSize: H18,
        ),
        kWidth(0.01),
        InkWell(
          onTap: signinController.navigateToSignUp,
          child: CustomTextWidget(
            title: localizationController.translate('sign_up'),
            color: AppColors.blueColor,
            fontSize: H18,
          ),
        )
      ],
    );
  }
}
