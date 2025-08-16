import 'package:cached_network_image/cached_network_image.dart';
import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/presentation/view/profile/controller/profile_controller.dart';
import 'package:majan/presentation/view_model/localization_controller.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class EditProfileScreen extends StatelessWidget {
  final ProfileController controller;
  final LocalizationController localizationController;

  const EditProfileScreen({
    Key? key,
    required this.controller,
    required this.localizationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () {
            controller.toggleEdit();
          },
        ),
        title: Text(
          localizationController.translate('edit_profile') ?? 'Edit Profile',
          style: TextStyle(
            color: AppColors.black,
            fontSize: appBarTitles,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Obx(() => TextButton(
                onPressed: controller.isSaving.value
                    ? null
                    : () => controller.saveProfile(),
                child: controller.isSaving.value
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.black),
                        ),
                      )
                    : CustomTextWidget(
                        title:
                            localizationController.translate('save') ?? 'Save',
                        color: AppColors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
              )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileImage(),
              kHeight(0.03),
              _buildBasicInformation(),
              kHeight(0.03),
              _buildContactDetails(),
              // if (controller.userRole.value == 'agent') ...[
              //   kHeight(0.03),
              //   _buildProfessionalDetails(),
              // ],
              kHeight(0.05),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          Obx(() => CircleAvatar(
                radius: screenWidth10,
                backgroundColor: AppColors.lightGrey2,
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: controller.profilePicUrl.value.isNotEmpty
                        ? controller.profilePicUrl.value
                        : FirebaseAuth.instance.currentUser?.photoURL ??
                            "https://i.postimg.cc/VLRdMxPK/profileimage.png",
                    width: screenWidth * 0.2,
                    height: screenWidth * 0.2,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) {
                      return Icon(
                        Icons.person,
                        size: screenWidth10,
                        color: AppColors.grey,
                      );
                    },
                  ),
                ),
              )),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                // TODO: Implement image picker functionality
                Get.snackbar(
                    'Info', 'Image picker functionality to be implemented');
              },
              child: Container(
                padding: EdgeInsets.all(screenWidth1),
                decoration: BoxDecoration(
                  color: AppColors.blueColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: AppColors.white,
                  size: smallIconSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizationController.translate('basic_info') ?? 'Basic Information',
          style: TextStyle(
            fontSize: H18,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        kHeight(0.02),
        _buildTextField(
          hint: localizationController.translate('enter_full_name') ??
              'Enter full name',
          controller: controller.fullNameController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Full name is required';
            }
            return null;
          },
        ),
        kHeight(0.015),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                hint: localizationController.translate('gender') ?? 'Gender',
                value: controller.gender.value,
                items: ['Male', 'Female', 'Others'],
                onChanged: (value) {
                  if (value != null) {
                    controller.gender.value = value;
                  }
                },
              ),
            ),
            kWidth(0.03),
            Expanded(
              child: _buildDateField(
                hint: localizationController.translate('date_of_birth') ??
                    'Date of Birth',
                value: controller.dateOfBirth.value,
                onTap: () => controller.selectDate(),
              ),
            ),
          ],
        ),
        kHeight(0.015),
        _buildTextField(
          hint: localizationController.translate('location') ?? 'Location',
          controller: controller.locationController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Location is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizationController.translate('contact_info') ?? 'Contact Details',
          style: TextStyle(
            fontSize: H18,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        kHeight(0.02),
        _buildTextField(
          hint: localizationController.translate('phone_number') ??
              'Phone number',
          controller: controller.phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Phone number is required';
            }
            if (value.length != 10) {
              return 'Phone number must be 10 digits';
            }
            return null;
          },
        ),
        kHeight(0.015),
        _buildTextField(
          hint: localizationController.translate('email_address') ??
              'Email address',
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: false, // Email should not be editable
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email is required';
            }
            return null;
          },
        ),
        kHeight(0.015),
        _buildTextField(
          hint: localizationController.translate('whatsapp_number') ??
              'WhatsApp number',
          controller: controller.whatsappController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: (value) {
            if (value != null && value.isNotEmpty && value.length != 10) {
              return 'WhatsApp number must be 10 digits';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildProfessionalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizationController.translate('professional_details') ??
              'Professional Details',
          style: TextStyle(
            fontSize: H18,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        kHeight(0.02),
        _buildTextField(
          hint:
              localizationController.translate('agency_name') ?? 'Agency name',
          controller: controller.agencyNameController,
        ),
        kHeight(0.015),
        _buildTextField(
          hint: localizationController.translate('agent_license_number') ??
              'Agent License Number',
          controller: controller.licenseController,
        ),
        kHeight(0.015),
        _buildTextField(
          hint: localizationController.translate('years_of_experience') ??
              'Years of Experience',
          controller: controller.experienceController,
          keyboardType: TextInputType.number,
        ),
        kHeight(0.015),
        _buildTextField(
          hint: localizationController.translate('working_cities') ??
              'Working Cities',
          controller: controller.citiesController,
        ),
        kHeight(0.015),
        // Display agent status (read-only)
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(screenWidth4),
          decoration: BoxDecoration(
            color: AppColors.lightGrey2,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                localizationController.translate('status') ?? 'Status: ',
                style: TextStyle(
                  fontSize: tagTitle,
                  color: AppColors.black500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Obx(() => Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(controller.agentStatus.value),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      controller.agentStatus.value.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return AppColors.grey;
    }
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.lightGrey2
            : AppColors.lightGrey2.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        enabled: enabled,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.black500,
            fontSize: tagTitle,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(screenWidth4),
        ),
        style: TextStyle(
          fontSize: tagTitle,
          color: enabled ? AppColors.black : AppColors.black500,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String hint,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        value: value.isEmpty ? null : value,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.black500,
            fontSize: tagTitle,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(screenWidth4),
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: tagTitle,
                      color: AppColors.black,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        style: TextStyle(
          fontSize: tagTitle,
          color: AppColors.black,
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String hint,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: TextEditingController(text: value),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.black500,
            fontSize: tagTitle,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(screenWidth4),
          suffixIcon: Icon(
            Icons.calendar_today,
            color: AppColors.black500,
            size: smallIconSize,
          ),
        ),
        style: TextStyle(
          fontSize: tagTitle,
          color: AppColors.black,
        ),
        readOnly: true,
        onTap: onTap,
      ),
    );
  }
}
