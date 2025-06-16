import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:country_code_picker/country_code_picker.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_text_formfield_widget.dart';

class EditTenantProfileScreen extends StatefulWidget {
  const EditTenantProfileScreen({super.key});

  @override
  State<EditTenantProfileScreen> createState() =>
      _EditTenantProfileScreenState();
}

class _EditTenantProfileScreenState extends State<EditTenantProfileScreen> {
  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Password visibility states
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Country code
  String _selectedCountryCode = '+91';
  String _selectedCountryFlag = '🇮🇳';

  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize with current user data (you can pass this from previous screen)
    _nameController.text = "John Abraham";
    _emailController.text = "john.abraham@gmail.com";
    _phoneController.text = "(123) 456 789";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomTextWidget(
          title: "Edit Profile",
          fontSize: Get.height * 0.022,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _saveProfile();
            },
            child: CustomTextWidget(
              title: "Save",
              fontSize: Get.height * 0.018,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ],
      ),
      body: Form(
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
                          child: Image.network(
                            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.lightGrey,
                                child: Icon(
                                  Icons.person,
                                  size: Get.width * 0.1,
                                  color: AppColors.black500,
                                ),
                              );
                            },
                          ),
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
                  controller: _nameController,
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
                  controller: _emailController,
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
                    // Country Code Picker
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
                            _selectedCountryCode = countryCode.dialCode!;
                            _selectedCountryFlag =
                                countryCode.flagUri ?? '🇮🇳';
                          });
                        },
                        initialSelection: 'IN',
                        favorite: const ['+91', 'IN', '+1', 'US'],
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        alignLeft: false,
                        textStyle: GoogleFonts.poppins(
                          fontSize: detailContentTitle,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                        dialogTextStyle: GoogleFonts.poppins(
                          fontSize: detailContentTitle,
                          color: AppColors.black,
                        ),
                        searchStyle: GoogleFonts.poppins(
                          fontSize: popularPlaceTitle,
                          color: AppColors.black,
                        ),
                        dialogSize: Size(Get.width * 0.9, Get.height * 0.55),
                        padding: EdgeInsets.zero,
                        margin: EdgeInsets.zero,
                        flagDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth5),
                    // Phone Number Field

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
                          if (value.length < 10) {
                            return "Phone number must be 10 digits";
                          }
                          return null;
                        },
                        hintText: "Enter Phone Number",
                        keyboardType: TextInputType.number,
                        controller: _phoneController,
                        suffixIcon: false,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight2),

                // Security Section
                CustomTextWidget(
                  title: "Security",
                  fontSize: Get.height * 0.02,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),

                SizedBox(height: screenHeight1),

                // Current Password Field
                CustomTextFieldWidget(
                  hintText: "Enter current password",
                  labelText: "Current Password",
                  isBoldTextNeeded: true,
                  keyboardType: TextInputType.visiblePassword,
                  controller: _currentPasswordController,
                  obscureText: !_isCurrentPasswordVisible,
                  suffixIcon: true,
                  suffixIconOnTap: () {
                    setState(() {
                      _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                    });
                  },
                ),

                // New Password Field
                CustomTextFieldWidget(
                  isBoldTextNeeded: true,
                  hintText: "Enter new password",
                  labelText: "New Password",
                  keyboardType: TextInputType.visiblePassword,
                  controller: _newPasswordController,
                  obscureText: !_isNewPasswordVisible,
                  suffixIcon: true,
                  suffixIconOnTap: () {
                    setState(() {
                      _isNewPasswordVisible = !_isNewPasswordVisible;
                    });
                  },
                  validator: (value) {
                    if (_currentPasswordController.text.isNotEmpty &&
                        (value == null || value.isEmpty)) {
                      return "Please enter new password";
                    }
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),

                // Confirm Password Field
                CustomTextFieldWidget(
                  isBoldTextNeeded: true,
                  hintText: "Confirm new password",
                  labelText: "Confirm Password",
                  keyboardType: TextInputType.visiblePassword,
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  suffixIcon: true,
                  suffixIconOnTap: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                  validator: (value) {
                    if (_newPasswordController.text.isNotEmpty &&
                        (value == null || value.isEmpty)) {
                      return "Please confirm your password";
                    }
                    if (value != _newPasswordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),

                SizedBox(height: screenHeight3),

                CustomButtonWidget(
                  buttonTitle: "Update Profile",
                  onPressed: () {
                    _saveProfile();
                  },
                ),

                // Update Profile Button

                SizedBox(height: screenHeight2),

                // Delete Account Option
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
      ),
    );
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
                      // Implement camera functionality
                      _showSuccessMessage("Camera selected");
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
                          title: "Camera",
                          fontSize: Get.height * 0.014,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      // Implement gallery functionality
                      _showSuccessMessage("Gallery selected");
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
                            Icons.photo_library,
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

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // Validate passwords if they are being changed
      if (_currentPasswordController.text.isNotEmpty ||
          _newPasswordController.text.isNotEmpty ||
          _confirmPasswordController.text.isNotEmpty) {
        if (_currentPasswordController.text.isEmpty) {
          _showErrorMessage("Please enter current password to change password");
          return;
        }

        if (_newPasswordController.text != _confirmPasswordController.text) {
          _showErrorMessage("New passwords do not match");
          return;
        }
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context); // Close loading dialog

        // Clear password fields after successful update
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        _showSuccessMessage("Profile updated successfully!");

        // Navigate back to profile screen
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      });
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
              onPressed: () => Navigator.pop(context),
              child: CustomTextWidget(
                title: "Cancel",
                color: AppColors.black500,
                fontSize: Get.height * 0.016,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showErrorMessage("Account deletion feature not implemented");
              },
              child: CustomTextWidget(
                title: "Delete",
                color: AppColors.redColor,
                fontSize: Get.height * 0.016,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomTextWidget(
          title: message,
          color: AppColors.white,
          fontSize: Get.height * 0.016,
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomTextWidget(
          title: message,
          color: AppColors.white,
          fontSize: Get.height * 0.016,
        ),
        backgroundColor: AppColors.redColor,
      ),
    );
  }
}
