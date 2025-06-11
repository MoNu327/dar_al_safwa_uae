import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/presentation/view/login/login_screen.dart';
import 'package:dar_al_safwa/presentation/view_model/localization_controller.dart';
import 'package:dar_al_safwa/presentation/view_model/signup_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_elevated_button.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/language_text_button.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../view_model/firebase_auth_controller.dart';
import '../../../widgets/custom_text_formfield_widget.dart';

class SignUpScreen extends StatelessWidget {
  SignUpScreen({super.key});

  final LocalizationController localizationController = Get.find();
  final SignupController signupController = Get.put(SignupController());

  final TextEditingController mobileController = TextEditingController();

  final AuthService authService = Get.put(AuthService());
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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
                          children: [
                            Align(
                                alignment: Alignment.topRight,
                                child: _buildHeader()),
                            kHeight(0.005),
                            Center(
                              child: Image.asset(
                                "assets/logo/launcher.png",
                                width: Get.width * 0.3,
                                height: Get.height * 0.1,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(height: Get.height * 0.005),
                            CustomTextWidget(
                              textAlign: TextAlign.center,
                              title: localizationController.translate(
                                  'create_an_account_with_easy_and_fast_methods'),
                              color: AppColors.lightGrey,
                              fontSize: Get.height * 0.018,
                            ),
                            SizedBox(height: Get.height * 0.03),
                            CustomTextFieldWidget(
                                hintText: localizationController
                                    .translate('full_name'),
                                labelText: localizationController
                                    .translate('full_name'),
                                keyboardType: TextInputType.name,
                                controller: authService.fullNameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Name is required';
                                  }
                                  //first letter should  not be space
                                  if (value.startsWith(' ')) {
                                    return 'Name should not start with a space';
                                  }
                                  // Check for only letters (allowing spaces between names)
                                  if (!RegExp(r'^[a-zA-Z ]+$')
                                      .hasMatch(value)) {
                                    return 'Name should contain only letters and spaces';
                                  }

                                  // Check minimum length (optional)
                                  if (value.length < 2) {
                                    return 'Name should be at least 2 characters';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  // Trigger validation on change
                                  _formKey.currentState!.validate();
                                },
                                labelTextColor: AppColors.black),
                            CustomTextFieldWidget(
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
                                  //first letter should  not be space
                                  if (value.startsWith(' ')) {
                                    return 'Name should not start with a space';
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
                            CustomTextFieldWidget(
                                hintText: localizationController
                                    .translate('mobile_number'),
                                labelText: localizationController
                                    .translate('mobile_number'),
                                keyboardType: TextInputType.phone,
                                controller: authService.mobileNoController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Mobile number is required';
                                  }
                                  //first letter should  not be space
                                  if (value.startsWith(' ')) {
                                    return 'Name should not start with a space';
                                  }
                                  if (value.length != 10) {
                                    return 'Mobile number must be 10 digits';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  // Trigger validation on change
                                  _formKey.currentState!.validate();
                                },
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                  FilteringTextInputFormatter.deny(
                                      RegExp(r'\s')),
                                ],
                                labelTextColor: AppColors.black),
                            Obx(() {
                              return CustomTextFieldWidget(
                                  hintText: localizationController
                                      .translate('password'),
                                  labelText: localizationController
                                      .translate('password'),
                                  keyboardType: TextInputType.text,
                                  controller: authService.passwordController,
                                  obscureText:
                                      signupController.isPasswordObscured.value,
                                  suffixIcon: true,
                                  suffixIconOnTap: () {
                                    signupController.togglePasswordVisibility();
                                  },
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
                                  labelTextColor: AppColors.black);
                            }),

                            SizedBox(height: Get.height * 0.01),
                            // Row(
                            //   children: [
                            //     Obx(
                            //       () => Checkbox(
                            //         value: signupController.isTermsAccepted.value,
                            //         onChanged: (value) {
                            //           signupController.toggleTermsAcceptance(value);
                            //         },
                            //         activeColor: AppColors.blueColor,
                            //         checkColor: AppColors.white,
                            //         splashRadius: 20,
                            //         side: const BorderSide(
                            //           width: 1,
                            //           color: AppColors.lightGrey,
                            //         ),
                            //         materialTapTargetSize:
                            //             MaterialTapTargetSize.shrinkWrap,
                            //       ),
                            //     ),
                            //     Flexible(
                            //         child: Text(
                            //       localizationController
                            //           .translate('accept_terms_and_conditions'),
                            //       style: GoogleFonts.poppins(
                            //         color: AppColors.black600,
                            //         fontSize: Get.height * 0.018,
                            //         fontWeight: FontWeight.w500,
                            //       ),
                            //     ))
                            //   ],
                            // ),
                            kHeight(0.01),
                            _buildSignupButton(),
                            kHeight(0.02),
                            _buildLoginTextButton(),
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
  Widget _buildHeader() {
    return LanguageTextButton(localizationController: localizationController);
  }

  // // Reusable input field widget
  // Widget _buildInputField({
  //   required String label,
  //   required String hintText,
  //   TextInputType? keyboardType,
  //   bool obscureText = false,
  //   Widget? suffixIcon,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: GoogleFonts.poppins(
  //           color: AppColors.black,
  //           fontSize: Get.height * 0.02,
  //           fontWeight: FontWeight.w400,
  //         ),
  //       ),
  //       SizedBox(height: Get.height * 0.005),
  //       TextField(
  //         obscureText: obscureText,
  //         keyboardType: keyboardType ?? TextInputType.text,
  //         decoration: InputDecoration(
  //           hintText: hintText,
  //           hintStyle: GoogleFonts.poppins(color: AppColors.lightGrey),
  //           contentPadding: EdgeInsets.symmetric(
  //             vertical: Get.height * 0.015,
  //             horizontal: Get.width * 0.05,
  //           ),
  //           border: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(12),
  //             borderSide: const BorderSide(color: AppColors.lightGrey),
  //           ),
  //           focusedBorder: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(12),
  //             borderSide: const BorderSide(color: AppColors.primaryColor),
  //           ),
  //           suffixIcon: suffixIcon,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // widget for mobile input field
  Widget _buildMobileInputField({
    required String label,
    required String hintText,
    required TextEditingController mobileNumberController,
    // required String selectedCountryCode,
    // required ValueChanged<String?> onCountryCodeChanged,
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
        Row(
          children: [
            Obx(
              () => Container(
                width: Get.width * 0.23,
                padding: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightGrey),
                ),
                child: DropdownButton<String>(
                  value: signupController.selectedCountryCode.value,
                  onChanged: signupController.changeCountryCode,
                  isExpanded: true,
                  items: signupController.countryCodes
                      .map((code) => DropdownMenuItem<String>(
                            value: code,
                            child: Text(code),
                          ))
                      .toList(),
                  hint: Text(
                    'Select Country Code',
                    style: GoogleFonts.poppins(
                      color: AppColors.lightGrey,
                    ),
                  ),
                  dropdownColor: AppColors.white,
                  menuMaxHeight: Get.height * 0.3,
                  underline: Container(),
                ),
              ),
            ),
            SizedBox(width: Get.width * 0.02),
            Expanded(
              child: TextField(
                controller: mobileNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: GoogleFonts.poppins(
                    color: AppColors.lightGrey,
                  ),
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
                ),
              ),
            )
          ],
        )
      ],
    );
  }

  // signup button reusable widget
  Widget _buildSignupButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: screenHeight05),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Obx(
     () {
          return CustomButtonWidget(
            childWidgetLoader: authService.isRegisterAgent.value,
            buttonTitle: localizationController.translate('sign_up'),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                if (!authService.isRegisterAgent.value) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  if (!authService.isRegisterAgent.value) {
                    authService.registerAgent();
                  }
                }
              }
              // authService.isRegisterAgent.value
              //     ? null
              //     : authService.registerAgent();
            },
            fontSize: packageTitle,
            buttonTextColor: AppColors.white,
            buttonColor: AppColors.black,
          );
        }
      ),
    );
  }

// reusable widget for login text button
  Widget _buildLoginTextButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomTextWidget(
          title: localizationController.translate('already_have_an_account'),
          color: AppColors.lightGrey,
          fontSize: popularPlaceTitle,
        ),
        kWidth(0.01),
        InkWell(
          onTap: () {
            signupController.navigateToSignin();
          },
          child: CustomTextWidget(
            title: localizationController.translate('login'),
            color: AppColors.blueColor,
            fontSize: popularPlaceTitle,
          ),
        )
      ],
    );
  }
}
