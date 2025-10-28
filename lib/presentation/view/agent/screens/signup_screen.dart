import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/presentation/view/login/login_screen.dart';
import 'package:majan/presentation/view_model/localization_controller.dart';
import 'package:majan/presentation/view_model/signup_controller.dart';
import 'package:majan/presentation/widgets/custom_elevated_button.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/presentation/widgets/language_text_button.dart';
import 'package:majan/core/theme/app_colors.dart';
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
                child: SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Get.width * 0.05,
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
                              color: AppColors.darkGrey,
                              fontSize: Get.height * 0.018,
                            ),
                            SizedBox(height: Get.height * 0.03),
                  
                            // Full Name Field
                            CustomTextFieldWidget(
                                isBorderNeeded: true,
                                textFieldColor: AppColors.white,
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
                                  if (value.startsWith(' ')) {
                                    return 'Name should not start with a space';
                                  }
                                  if (!RegExp(r'^[a-zA-Z ]+$')
                                      .hasMatch(value)) {
                                    return 'Name should contain only letters and spaces';
                                  }
                                  if (value.length < 2) {
                                    return 'Name should be at least 2 characters';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  _formKey.currentState!.validate();
                                },
                                labelTextColor: AppColors.black),
                  
                            // Email Field
                            CustomTextFieldWidget(
                                isBorderNeeded: true,
                                textFieldColor: AppColors.white,
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
                                  if (value.startsWith(' ')) {
                                    return 'Email should not start with a space';
                                  }
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  _formKey.currentState!.validate();
                                },
                                inputFormatters: [
                                  FilteringTextInputFormatter.deny(
                                      RegExp(r'\s')),
                                ],
                                labelTextColor: AppColors.black),
                  
                            // Mobile Number Field
                            CustomTextFieldWidget(
                                isBorderNeeded: true,
                                textFieldColor: AppColors.white,
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
                                  if (value.startsWith(' ')) {
                                    return 'Mobile number should not start with a space';
                                  }
                                  if (value.length != 10) {
                                    return 'Mobile number must be 8 digits';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  _formKey.currentState!.validate();
                                },
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                  FilteringTextInputFormatter.deny(
                                      RegExp(r'\s')),
                                ],
                                labelTextColor: AppColors.black),
                  
                            // Gender Selection Field
                            _buildGenderSelection(),
                  
                            // Date of Birth Field
                            _buildDateOfBirthField(),
                  
                            // Location Field
                            CustomTextFieldWidget(
                                isBorderNeeded: true,
                                textFieldColor: AppColors.white,
                                hintText: localizationController
                                        .translate('location') ??
                                    'Location',
                                labelText: localizationController
                                        .translate('location') ??
                                    'Location',
                                keyboardType: TextInputType.text,
                                controller: authService.locationController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Location is required';
                                  }
                                  if (value.startsWith(' ')) {
                                    return 'Location should not start with a space';
                                  }
                                  if (value.length < 2) {
                                    return 'Location should be at least 2 characters';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  _formKey.currentState!.validate();
                                },
                                labelTextColor: AppColors.black),
                  
                            // WhatsApp Availability Checkbox
                            _buildWhatsAppAvailabilityField(),
                  
                            // Conditional WhatsApp Number Field
                            Obx(() {
                              return authService.selectedWhatsAppStatus.value
                                  ? Container()
                                  : CustomTextFieldWidget(
                                      isBorderNeeded: true,
                                      textFieldColor: AppColors.white,
                                      hintText: localizationController
                                              .translate('whatsapp_number') ??
                                          'WhatsApp Number',
                                      labelText: localizationController
                                              .translate('whatsapp_number') ??
                                          'WhatsApp Number',
                                      keyboardType: TextInputType.phone,
                                      controller:
                                          authService.whatsAppNumberController,
                                      validator: (value) {
                                        if (!authService
                                            .selectedWhatsAppStatus.value) {
                                          if (value == null || value.isEmpty) {
                                            return 'WhatsApp number is required';
                                          }
                                          if (value.startsWith(' ')) {
                                            return 'WhatsApp number should not start with a space';
                                          }
                                          if (value.length != 8) {
                                            return 'WhatsApp number must be 8 digits';
                                          }
                                        }
                                        return null;
                                      },
                                      onChanged: (value) {
                                        _formKey.currentState!.validate();
                                      },
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                        FilteringTextInputFormatter.deny(
                                            RegExp(r'\s')),
                                      ],
                                      labelTextColor: AppColors.black);
                            }),
                  
                            // Password Field
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
                                    if (!RegExp(r'[a-z]').hasMatch(value)) {
                                      return 'Password must contain at least one lowercase letter';
                                    }
                                    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
                                      return 'Password must contain at least one letter';
                                    }
                                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                                      return 'Password must contain at least one number';
                                    }
                                    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]')
                                        .hasMatch(value)) {
                                      return 'Password must contain at least one special character';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    _formKey.currentState!.validate();
                                  },
                                  inputFormatters: [
                                    FilteringTextInputFormatter.deny(
                                        RegExp(r'\s')),
                                  ],
                                  labelTextColor: AppColors.black);
                            }),
                  
                            SizedBox(height: Get.height * 0.01),
                  
                            kHeight(0.03),
                            _buildSignupButton(),
                            kHeight(0.02),
                            _buildLoginTextButton(),
                            kHeight(0.02),
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

  // Gender Selection Widget
  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: Get.height * 0.01),
          child: Text(
            localizationController.translate('gender'),
            style: GoogleFonts.poppins(
              color: AppColors.black,
              fontSize: tagTitle,
            ),
          ),
        ),
        Obx(() => Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: Get.width * 0.04,
                vertical: Get.height * 0.004,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightGrey),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.white,
              ),
              child: DropdownButton<String>(
                value: authService.selectedGender.value.isEmpty
                    ? null
                    : authService.selectedGender.value,
                hint: Text(
                  localizationController.translate('select_gender') ??
                      'Select Gender',
                  style: GoogleFonts.poppins(
                      color: AppColors.black,
                      fontSize: tagTitle,
                      fontWeight: FontWeight.w500),
                ),
                isExpanded: true,
                underline: Container(),
                items: ['Male', 'Female', 'Others']
                    .map((gender) => DropdownMenuItem<String>(
                          value: gender,
                          child: Text(
                            gender,
                            style: GoogleFonts.poppins(
                                color: AppColors.black,
                                fontSize: tagTitle,
                                fontWeight: FontWeight.w500),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    authService.selectedGender.value = value;
                  }
                },
              ),
            )),
        // SizedBox(height: Get.height * 0.01),
      ],
    );
  }

  // Date of Birth Selection Widget
  Widget _buildDateOfBirthField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: Get.height * 0.01),
          child: Text(
            localizationController.translate('date_of_birth') ??
                'Date of Birth',
            style: GoogleFonts.poppins(
              color: AppColors.black,
              fontSize: tagTitle,
            ),
          ),
        ),
        Obx(() => GestureDetector(
              onTap: () => _selectDate(),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: Get.width * 0.04,
                  vertical: Get.height * 0.018,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lightGrey),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      authService.selectedDate.value.isEmpty
                          ? (localizationController
                                  .translate('select_date_of_birth') ??
                              'Select Date of Birth')
                          : authService.selectedDate.value,
                      style: GoogleFonts.poppins(
                          color: AppColors.black,
                          fontSize: tagTitle,
                          fontWeight: FontWeight.w500),
                    ),
                    Icon(
                      Icons.calendar_today,
                      color: AppColors.lightGrey,
                      size: Get.height * 0.02,
                    ),
                  ],
                ),
              ),
            )),
        SizedBox(height: Get.height * 0.01),
      ],
    );
  }

  // WhatsApp Availability Checkbox Widget
  Widget _buildWhatsAppAvailabilityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() => CheckboxListTile(
              title: Text(
                localizationController
                        .translate('whatsapp_available_on_provided_phone') ??
                    'Is WhatsApp available on the provided phone number?',
                style: GoogleFonts.poppins(
                  color: AppColors.black,
                  fontSize: tagTitle,
                  fontWeight: FontWeight.w500,
                ),
              ),
              value: authService.selectedWhatsAppStatus.value,
              onChanged: (value) {
                authService.selectedWhatsAppStatus.value = value ?? false;
                if (value == true) {
                  // Clear WhatsApp number field if same number is used
                  authService.whatsAppNumberController.clear();
                }
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.secondaryColor,
            )),
        SizedBox(height: Get.height * 0.01),
      ],
    );
  }

  // Date Picker Function
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate:
          DateTime.now().subtract(Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1950),
      lastDate:
          DateTime.now().subtract(Duration(days: 6570)), // Minimum 18 years
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      authService.selectedDate.value =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
    }
  }

  // widget for mobile input field
  Widget _buildMobileInputField({
    required String label,
    required String hintText,
    required TextEditingController mobileNumberController,
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
      child: Obx(() {
        return CustomButtonWidget(
          childWidgetLoader: authService.isRegisterAgent.value,
          buttonTitle: localizationController.translate('sign_up'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Additional validation for required fields
              if (authService.selectedGender.value.isEmpty) {
                Get.snackbar('Error', 'Please select gender');
                return;
              }
              if (authService.selectedDate.value.isEmpty) {
                Get.snackbar('Error', 'Please select date of birth');
                return;
              }

              if (!authService.isRegisterAgent.value) {
                FocusManager.instance.primaryFocus?.unfocus();
                if (!authService.isRegisterAgent.value) {
                  // Call the setAgentRole method with all required parameters
                  authService.registerAgent();
                  // setAgentRole(
                  //   authService.fullNameController.text,
                  //   authService.mobileNoController.text,
                  //   authService.selectedGender.value,
                  //   authService.profilePictureUrl.value.isEmpty
                  //       ? null
                  //       : authService.profilePictureUrl.value,
                  //   authService.selectedDate.value,
                  //   authService.selectedWhatsAppStatus.value,
                  //   authService.selectedWhatsAppStatus.value
                  //       ? authService.mobileNoController.text
                  //       : authService.whatsAppNumberController.text,
                  //   authService.locationController.text,
                  // );
                }
              }
            }
          },
          fontSize: packageTitle,
          buttonTextColor: AppColors.white,
          buttonColor: AppColors.black,
        );
      }),
    );
  }

// reusable widget for login text button
  Widget _buildLoginTextButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomTextWidget(
          title: localizationController.translate('already_have_an_account'),
          color: AppColors.black800,
          fontWeight: FontWeight.w500,
          fontSize: H18,
        ),
        kWidth(0.01),
        InkWell(
          onTap: () {
            signupController.navigateToSignin();
          },
          child: CustomTextWidget(
            title: localizationController.translate('login'),
            color: AppColors.blueColor,
            fontSize: H18,
          ),
        )
      ],
    );
  }
}
