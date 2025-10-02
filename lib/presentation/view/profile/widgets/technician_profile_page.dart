import 'package:cached_network_image/cached_network_image.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/domain/controller/technician_controller.dart';
import 'package:majan/presentation/view/profile/widgets/tenant_edit_profile_widget.dart';
import 'package:majan/presentation/widgets/notification_navigation_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_text_widget.dart';

class TechnicianProfileScreen extends StatefulWidget {
  const TechnicianProfileScreen({super.key});

  @override
  State<TechnicianProfileScreen> createState() =>
      _TechnicianProfileScreenState();
}

class _TechnicianProfileScreenState extends State<TechnicianProfileScreen> {
  final TechnicianController controller = Get.find<TechnicianController>();

  @override
  void initState() {
    super.initState();
    debugPrint(
        "👤 [TechnicianProfileScreen] Current user: ${controller.currentUser?.toJson()}");
    // If you want to re-fetch fresh data, uncomment:
    // if (controller.currentUser?.uid != null) {
    //   controller.fetchTechnicianProfile(controller.currentUser!.uid);
    // }
  }

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
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final technician = controller.currentUser;
        if (technician == null) {
          return const Center(child: Text("No technician details available"));
        }

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenHeight3,
            vertical: Get.height * 0.02,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Profile Image and Name
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue[50],
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: technician.photoURL.isNotEmpty
                          ? technician.photoURL
                          : "https://i.postimg.cc/VLRdMxPK/profileimage.png",
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
                CustomTextWidget(
                  title: technician.fullName,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                CustomTextWidget(
                  title: technician.role,
                  fontSize: 16,
                  color: AppColors.black800,
                ),
                kHeight(0.03),

                // Contact Info
                Container(
                  padding: EdgeInsets.all(screenWidth3),
                  decoration: BoxDecoration(
                    color: AppColors.whiteLight,
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoRow(Icons.phone_outlined, technician.mobile),
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
                              borderRadius: BorderRadius.circular(screenWidth2),
                            ),
                          )
                        ],
                      ),
                      _buildInfoRow(Icons.location_on_outlined,
                          "Location: ${technician.location}"),
                      _buildInfoRow(Icons.email_outlined, technician.email),
                      _buildInfoRow(
                          Icons.badge_outlined, 'UID: ${technician.uid}'),
                    ],
                  ),
                ),
                kHeight(0.02),

                // Skills Section (Dummy)
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

                // Ratings and Stats (Dummy)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Get.width * 0.04,
                    vertical: Get.height * 0.02,
                  ),
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
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Get.width * 0.02,
                              vertical: Get.height * 0.005,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                CustomTextWidget(
                                  title: '4.4 ',
                                  fontSize: screenHeight * 0.02,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                                Icon(Icons.star,
                                    color: Colors.amber,
                                    size: screenHeight * 0.02),
                                CustomTextWidget(
                                  title: '(120 reviews)',
                                  fontSize: screenHeight * 0.016,
                                  color: AppColors.darkGrey,
                                ),
                              ],
                            ),
                          ),
                          kHeight(0.005),
                          CustomTextWidget(
                            title: 'Based on 220 hits',
                            fontSize: screenHeight * 0.014,
                            color: AppColors.darkGrey,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CustomTextWidget(
                            title: '120+ jobs',
                            fontSize: screenHeight * 0.018,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          CustomTextWidget(
                            title: 'Jobs Completed',
                            fontSize: screenHeight * 0.014,
                            color: Colors.grey[600],
                          ),
                          kHeight(0.01),
                          CustomTextWidget(
                            title: '1.2 Hours',
                            fontSize: screenHeight * 0.018,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          CustomTextWidget(
                            title: 'Avg. Time Per Job',
                            fontSize: screenHeight * 0.014,
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
                   Get.to(() => EditTenantProfileScreen());
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
                        Get.back(); // Perform logout
                      },
                    );
                  },
                ),
                kHeight(0.02),
              ],
            ),
          ),
        );
      }),
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
