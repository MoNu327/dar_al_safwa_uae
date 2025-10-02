import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_code_picker/country_code_picker.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_text_widget.dart';
import '../../../widgets/custom_text_formfield_widget.dart';
import '../controller/profile_controller.dart';

class EditTenantProfileScreen extends StatefulWidget {
  const EditTenantProfileScreen({super.key});

  @override
  State<EditTenantProfileScreen> createState() =>
      _EditTenantProfileScreenState();
}

class _EditTenantProfileScreenState extends State<EditTenantProfileScreen> {
  final ProfileController _profileController = Get.find<ProfileController>();
  FirebaseAuth auth = FirebaseAuth.instance;
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String _selectedCountryCode = '+971';
  String _selectedCountryFlag = 'AED';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _profileController.toggleEdit();
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _profileController.toggleEdit();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        surfaceTintColor: AppColors.white,
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
        title: CustomTextWidget(
          title: "Edit Profile",
          fontSize: Get.height * 0.022,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        actions: [
          Obx(() => TextButton(
                onPressed:
                    _profileController.isSaving.value ? null : _saveProfile,
                child: CustomTextWidget(
                  title: "Save",
                  fontSize: Get.height * 0.018,
                  fontWeight: FontWeight.w600,
                  color: _profileController.isSaving.value
                      ? AppColors.grey
                      : AppColors.black,
                ),
              )),
        ],
      ),
      body: Obx(() {
        if (_profileController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Picture Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: Get.width * 0.25,
                          height: Get.width * 0.25,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.lightGrey,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(Get.width * 0.125),
                            child: auth.currentUser?.photoURL != null
                                ? Image.network(
                                    auth.currentUser?.photoURL ?? '',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildDefaultProfileIcon();
                                    },
                                  )
                                : _buildDefaultProfileIcon(),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _changeProfilePicture,
                            child: Container(
                              width: Get.width * 0.08,
                              height: Get.width * 0.08,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: AppColors.white,
                                size: Get.width * 0.04,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight2),

                  // Personal Information Section
                  CustomTextWidget(
                    title: "Personal Informations",
                    fontSize: Get.height * 0.02,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),

                  SizedBox(height: screenHeight1),

                  // Name Field
                  CustomTextFieldWidget(
                    isBoldTextNeeded: true,
                    hintText: "Enter your full name",
                    keyboardType: TextInputType.name,
                    controller: _profileController.fullNameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter your full name";
                      }
                      return null;
                    },
                  ),

                  // Email Field
                  CustomTextFieldWidget(
                    isBoldTextNeeded: true,
                    hintText: "Enter your email address",
                    keyboardType: TextInputType.emailAddress,
                    controller: _profileController.emailController,
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter your email address";
                      }
                      if (!GetUtils.isEmail(value)) {
                        return "Please enter a valid email address";
                      }
                      return null;
                    },
                  ),

                  // Phone Field with Country Code
                  SizedBox(height: screenHeight05),
                  Row(
                    children: [
                      Container(
                        height: Get.height * 0.058,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.white,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.whiteLight,
                        ),
                        child: CountryCodePicker(
  onChanged: (CountryCode countryCode) {
    setState(() {
      _selectedCountryCode = countryCode.dialCode!; // +968 for Oman
      _selectedCountryFlag = countryCode.code!; // OM
    });
  },
  initialSelection: 'AED', // ISO code for Oman
  favorite: const ['+971', 'AED', '+971', 'AE'],
  showCountryOnly: false,
  showOnlyCountryWhenClosed: false,
  alignLeft: false,
  textStyle: GoogleFonts.poppins(
    fontSize: detailContentTitle,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  ),
),
                      ),
                      SizedBox(width: screenWidth5),
                      Expanded(
                        child: CustomTextFieldWidget(
                          isBoldTextNeeded: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter phone number";
                            }
                            if (value.length < 8) {
                              return "Phone number must be 8 digits";
                            }
                            return null;
                          },
                          hintText: "Enter Phone Number",
                          keyboardType: TextInputType.number,
                          controller: _profileController.phoneController,
                          suffixIcon: false,
                        ),
                      ),
                    ],
                  ),

                  // Location Field
                  CustomTextFieldWidget(
                    keyboardType: TextInputType.text,
                    isBoldTextNeeded: true,
                    hintText: "Enter your location",
                    controller: _profileController.locationController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter your location";
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: screenHeight2),

                  // // Security Section
                  // CustomTextWidget(
                  //   title: "Security",
                  //   fontSize: Get.height * 0.02,
                  //   fontWeight: FontWeight.w600,
                  //   color: AppColors.black,
                  // ),

                  // SizedBox(height: screenHeight1),

                  // // Current Password Field
                  // CustomTextFieldWidget(
                  //   hintText: "Enter current password",
                  //   labelText: "Current Password",
                  //   isBoldTextNeeded: true,
                  //   keyboardType: TextInputType.visiblePassword,
                  //   controller: _currentPasswordController,
                  //   obscureText: !_isCurrentPasswordVisible,
                  //   suffixIcon: true,
                  //   suffixIconOnTap: () {
                  //     setState(() {
                  //       _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                  //     });
                  //   },
                  // ),

                  // // New Password Field
                  // CustomTextFieldWidget(
                  //   isBoldTextNeeded: true,
                  //   hintText: "Enter new password",
                  //   labelText: "New Password",
                  //   keyboardType: TextInputType.visiblePassword,
                  //   controller: _newPasswordController,
                  //   obscureText: !_isNewPasswordVisible,
                  //   suffixIcon: true,
                  //   suffixIconOnTap: () {
                  //     setState(() {
                  //       _isNewPasswordVisible = !_isNewPasswordVisible;
                  //     });
                  //   },
                  //   validator: (value) {
                  //     if (_currentPasswordController.text.isNotEmpty &&
                  //         (value == null || value.isEmpty)) {
                  //       return "Please enter new password";
                  //     }
                  //     if (value != null &&
                  //         value.isNotEmpty &&
                  //         value.length < 6) {
                  //       return "Password must be at least 6 characters";
                  //     }
                  //     return null;
                  //   },
                  // ),

                  // // Confirm Password Field
                  // CustomTextFieldWidget(
                  //   isBoldTextNeeded: true,
                  //   hintText: "Confirm new password",
                  //   labelText: "Confirm Password",
                  //   keyboardType: TextInputType.visiblePassword,
                  //   controller: _confirmPasswordController,
                  //   obscureText: !_isConfirmPasswordVisible,
                  //   suffixIcon: true,
                  //   suffixIconOnTap: () {
                  //     setState(() {
                  //       _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  //     });
                  //   },
                  //   validator: (value) {
                  //     if (_newPasswordController.text.isNotEmpty &&
                  //         (value == null || value.isEmpty)) {
                  //       return "Please confirm your password";
                  //     }
                  //     if (value != _newPasswordController.text) {
                  //       return "Passwords do not match";
                  //     }
                  //     return null;
                  //   },
                  // ),

                  SizedBox(height: screenHeight3),

                  Obx(() => CustomButtonWidget(
                        buttonTitle: "Update Profile",
                        onPressed: _profileController.isSaving.value
                            ? null
                            : _saveProfile,
                        // isLoading: _profileController.isSaving.value,
                      )),

                  SizedBox(height: screenHeight2),

                  Center(
                    child: TextButton(
                      onPressed: _showDeleteAccountDialog,
                      child: CustomTextWidget(
                        title: "Delete Account",
                        fontSize: Get.height * 0.016,
                        fontWeight: FontWeight.w500,
                        color: AppColors.redColor,
                        underline: true,
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight2),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDefaultProfileIcon() {
    return Container(
      color: AppColors.lightGrey,
      child: Icon(
        Icons.person,
        size: Get.width * 0.1,
        color: AppColors.black500,
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Validate passwords if they are being changed
      if (_currentPasswordController.text.isNotEmpty ||
          _newPasswordController.text.isNotEmpty ||
          _confirmPasswordController.text.isNotEmpty) {
        if (_currentPasswordController.text.isEmpty) {
          Get.snackbar(
            'Error',
            'Please enter current password to change password',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        if (_newPasswordController.text != _confirmPasswordController.text) {
          Get.snackbar(
            'Error',
            'New passwords do not match',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        // Here you would typically verify current password and update to new password
        // This would require additional methods in your ProfileController
      }

      // Call the controller's save method
      await _profileController.saveProfile();
    }
  }

  void _changeProfilePicture() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: Get.height * 0.2,
          padding: EdgeInsets.all(screenWidth1),
          child: Column(
            children: [
              CustomTextWidget(
                title: "Change Profile Picture",
                fontSize: Get.height * 0.02,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: screenHeight1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      // _profileController.updateProfilePicture();
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(screenWidth1),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: AppColors.primaryColor,
                            size: Get.width * 0.08,
                          ),
                        ),
                        SizedBox(height: screenHeight05),
                        CustomTextWidget(
                          title: "Gallery",
                          fontSize: Get.height * 0.014,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    Get.dialog(
      AlertDialog(
        title: CustomTextWidget(
          title: "Delete Account",
          fontSize: Get.height * 0.02,
          fontWeight: FontWeight.w600,
          color: AppColors.redColor,
        ),
        content: CustomTextWidget(
          title:
              "Are you sure you want to delete your account? This action cannot be undone.",
          fontSize: Get.height * 0.016,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: CustomTextWidget(
              title: "Cancel",
              color: AppColors.black500,
              fontSize: Get.height * 0.016,
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final confirmed = await _confirmDeleteWithPassword();
              if (confirmed) {
                // await _profileController.deleteAccount();
              }
            },
            child: CustomTextWidget(
              title: "Delete",
              color: AppColors.redColor,
              fontSize: Get.height * 0.016,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDeleteWithPassword() async {
    final passwordController = TextEditingController();
    bool passwordVisible = false;

    return await Get.dialog<bool>(
          AlertDialog(
            title: CustomTextWidget(
              title: "Confirm Deletion",
              fontSize: Get.height * 0.02,
              fontWeight: FontWeight.w600,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextWidget(
                  title:
                      "Please enter your password to confirm account deletion",
                  fontSize: Get.height * 0.016,
                ),
                SizedBox(height: screenHeight1),
                TextField(
                  controller: passwordController,
                  obscureText: !passwordVisible,
                  decoration: InputDecoration(
                    labelText: "Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        Get.back();
                        _confirmDeleteWithPassword();
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Get.back(result: true);
                },
                child: Text("Confirm"),
              ),
            ],
          ),
        ) ??
        false;
  }
}
