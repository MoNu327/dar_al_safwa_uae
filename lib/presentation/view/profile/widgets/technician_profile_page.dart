import 'package:cached_network_image/cached_network_image.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/widgets/notification_navigation_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_text_widget.dart';

class TechnicianProfileScreen extends StatelessWidget {
  const TechnicianProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.white,
        title: CustomTextWidget(
          title: 'Profile Details',
          fontSize: 20,
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
        actions: [notificationNavigation()],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: screenHeight3, vertical: Get.height * 0.02),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Image and Name
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue[50],
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: "https://i.postimg.cc/VLRdMxPK/profileimage.png",
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) {
                      return const Icon(
                        Icons.person,
                        color: Colors.blue,
                        size: 50,
                      );
                    },
                  ),
                ),
              ),
              kHeight(0.02),
              const CustomTextWidget(
                title: 'John Mathew',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              const CustomTextWidget(
                title: 'Certified Plumber',
                fontSize: 16,
                color: AppColors.black800,
              ),
              kHeight(0.03),

              // Contact Info
              Container(
                padding: EdgeInsets.all(screenWidth3),
                decoration: BoxDecoration(
                    color: AppColors.whiteLight,
                    borderRadius: BorderRadius.all(Radius.circular(14))),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoRow(
                            Icons.phone_outlined, '+91 (123) 456 7890'),
                        Container(
                          height: screenHeight * 0.020,
                          width: screenWidth * 0.14,
                          child: Center(
                            child: CustomTextWidget(
                              title: "Online",
                              color: AppColors.white,
                              fontSize: tagTitle,
                            ),
                          ),
                          decoration: BoxDecoration(
                              color: AppColors.onlineGreenDark,
                              borderRadius:
                                  BorderRadius.circular(screenWidth2)),
                        )
                      ],
                    ),
                    _buildInfoRow(Icons.location_on_outlined, 'Kochi, Kerala'),
                    _buildInfoRow(Icons.email_outlined, 'johnmathew@gmail.com'),
                    _buildInfoRow(
                        Icons.badge_outlined, 'Technician ID: TXN90423'),
                  ],
                ),
              ),
              kHeight(0.02),

              // Skills Section
              const Align(
                alignment: Alignment.centerLeft,
                child: CustomTextWidget(
                  title: 'Skills',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              kHeight(0.01),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSkillChip('Plumbing'),
                    _buildSkillChip('Regaining'),
                    _buildSkillChip('Cleaning'),
                    _buildSkillChip('Electrical'),
                    _buildSkillChip('AC Repair'),
                  ],
                ),
              ),
              kHeight(0.03),

              // Ratings and Stats
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: Get.width * 0.04, vertical: Get.height * 0.02),
                decoration: BoxDecoration(
                  color: AppColors.whiteLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CustomTextWidget(
                              title: '4.4',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            const Icon(Icons.star,
                                color: Colors.amber, size: 24),
                            CustomTextWidget(
                              title: '(120 reviews)',
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                        kHeight(0.01),
                        const CustomTextWidget(
                          title: 'Based on 220 hits',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const CustomTextWidget(
                          title: '120+ jobs',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        CustomTextWidget(
                          title: 'Jobs Completed',
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        kHeight(0.01),
                        const CustomTextWidget(
                          title: '1.2 Hours',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        CustomTextWidget(
                          title: 'Avg. Time Per Job',
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              kHeight(0.03),

              // Action Buttons
              CustomButtonWidget(
                buttonTitle: 'Edit Profile',
                buttonShape: "rect",
                buttonColor: AppColors.secondaryColor,
                buttonWidth: Get.width * 0.9,
                buttonTextColor: Colors.white,
                onPressed: () {
                  // Add edit profile functionality
                },
              ),
              kHeight(0.02),
              CustomButtonWidget(
                buttonTitle: 'Logout',
                buttonShape: "rect",
                buttonColor: Colors.white,
                buttonWidth: Get.width * 0.9,
                borderColor: Colors.red,
                buttonTextColor: Colors.red,
                onPressed: () {
                  Get.defaultDialog(
                    title: "Logout",
                    middleText: "Are you sure you want to log out?",
                    textConfirm: "Yes",
                    textCancel: "No",
                    buttonColor: Colors.red,
                    confirmTextColor: Colors.white,
                    onConfirm: () {
                      // Add logout functionality
                      Get.back();
                    },
                  );
                },
              ),
              kHeight(0.02),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.black),
          kWidth(0.03),
          CustomTextWidget(
            title: text,
            fontSize: screenHeight * 0.016,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Chip(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      label: CustomTextWidget(
        title: skill,
        fontSize: 14,
        color: AppColors.secondaryColor,
      ),
      backgroundColor: AppColors.secondaryColorLight.withValues(alpha: 0.1),
    );
  }
}
