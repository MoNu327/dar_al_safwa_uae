import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    debugPrint('📱 Edit Screen: isLoading = ${_profileController.isLoading.value}');
    debugPrint('📱 Edit Screen: phoneNumber.value = "${_profileController.phoneNumber.value}"');
    
    // Populate controllers for editing
    _profileController.populateControllersForEdit();
    
    debugPrint('📱 Edit Screen: phoneController.text = "${_profileController.phoneController.text}"');
    
    _preparePhoneNumber();
    
    debugPrint('📱 Edit Screen: After prepare = "${_profileController.phoneController.text}"');
  });
}

  /// Remove +971 prefix from phone number for display
  void _preparePhoneNumber() {
    String phone = _profileController.phoneController.text;
    
    if (phone.startsWith('+971')) {
      _profileController.phoneController.text = phone.substring(4);
    } else if (phone.startsWith('971')) {
      _profileController.phoneController.text = phone.substring(3);
    } else if (phone.startsWith('0') && phone.length == 10) {
      _profileController.phoneController.text = phone.substring(1);
    }
  }

  @override
  void dispose() {
    // FIXED: Don't call toggleEdit() here - just dispose local controllers
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
                    // Profile Picture Section (Read-only)
                    Center(
                      child: Container(
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

                    // Phone Field with Fixed UAE Country Code
                    SizedBox(height: screenHeight05),
                    Row(
                      children: [
                        Container(
                          height: Get.height * 0.058,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03,
                            vertical: screenHeight * 0.01,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.lightGrey,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.whiteLight,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🇦🇪', style: TextStyle(fontSize: 20)),
                              SizedBox(width: screenWidth * 0.015),
                              Text(
                                '+971',
                                style: GoogleFonts.poppins(
                                  fontSize: detailContentTitle,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: screenWidth5),
                        Expanded(
                          child: CustomTextFieldWidget(
                            isBoldTextNeeded: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(9),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Please enter phone number";
                              }
                              if (value.length != 9) {
                                return "Phone number must be 9 digits";
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

                    SizedBox(height: screenHeight3),

                    Obx(() => CustomButtonWidget(
                          buttonTitle: "Update Profile",
                          onPressed: _profileController.isSaving.value
                              ? null
                              : _saveProfile,
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
      String phone = _profileController.phoneController.text.trim();
      String originalPhone = phone;
      
      if (phone.isNotEmpty && !phone.startsWith('+971')) {
        _profileController.phoneController.text = '+971$phone';
      }
      
      await _profileController.saveProfile();
      
      _profileController.phoneController.text = originalPhone;
    }
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