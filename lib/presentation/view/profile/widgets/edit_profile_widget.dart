import 'package:cached_network_image/cached_network_image.dart';
import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/dashboard_tile_widget.dart';
import 'package:dar_al_safwa/presentation/view/profile/controller/profile_controller.dart';
import 'package:dar_al_safwa/presentation/view_model/localization_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

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
          onPressed: controller.toggleEdit,
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.black,
            fontSize: appBarTitles,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () {},
              child: CustomTextWidget(
                title: localizationController.translate('Save'),
                color: AppColors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileImage(),
            kHeight(0.03),
            _buildBasicInformation(),
            kHeight(0.03),
            _buildContactDetails(),
            kHeight(0.03),
            _buildProfessionalDetails(),
            kHeight(0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: screenWidth10,
            backgroundColor: AppColors.lightGrey2,
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: FirebaseAuth.instance.currentUser?.photoURL ??
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
          ),
          Positioned(
            bottom: 0,
            right: 0,
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
        ],
      ),
    );
  }

  Widget _buildBasicInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Informations',
          style: TextStyle(
            fontSize: H18,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        kHeight(0.02),
        _buildTextField('Enter full name', controller.fullName.value),
        kHeight(0.015),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField('Gender', controller.gender.value),
            ),
            kWidth(0.03),
            Expanded(
              child: _buildDateField('DOB', controller.dateOfBirth.value),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Details',
          style: TextStyle(
            fontSize: H18,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        kHeight(0.02),
        _buildTextField('Phone number', controller.phoneNumber.value),
        kHeight(0.015),
        _buildTextField('Email address', controller.email!),
        kHeight(0.015),
        _buildTextField('WhatsApp number', controller.whatsappNumber.value),
      ],
    );
  }

  Widget _buildProfessionalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Professional Details',
          style: TextStyle(
            fontSize: H18,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        kHeight(0.02),
        _buildTextField('Agency name', controller.agencyName.value),
        kHeight(0.015),
        _buildTextField('Agent License Number', controller.licenseNumber.value),
        kHeight(0.015),
        _buildTextField(
            'Years of Experience', controller.yearsOfExperience.value),
        kHeight(0.015),
        _buildTextField('Working Cities', controller.workingCities.value),
      ],
    );
  }

  Widget _buildTextField(String hint, String value) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        initialValue: value,
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
          color: AppColors.black,
        ),
      ),
    );
  }

  Widget _buildDropdownField(String hint, String value) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(screenWidth4),
        ),
        items: ['Male', 'Female', 'Other']
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (val) {
          if (val != null) controller.gender.value = val;
        },
      ),
    );
  }

  Widget _buildDateField(String hint, String value) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        initialValue: value,
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
        onTap: () {
          // Handle date picker
        },
      ),
    );
  }
}
