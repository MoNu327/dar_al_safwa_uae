import 'package:cached_network_image/cached_network_image.dart';
import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/controllers/network_controller.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/dashboard_tile_widget.dart';
import 'package:dar_al_safwa/presentation/view/profile/widgets/edit_profile_widget.dart';
import 'package:dar_al_safwa/presentation/view/profile/widgets/testimonial_section.dart';
import 'package:dar_al_safwa/presentation/view_model/firebase_auth_controller.dart';
import 'package:dar_al_safwa/presentation/view_model/localization_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_elevated_button.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/language_text_button.dart';
import 'package:dar_al_safwa/presentation/widgets/no_internet_widegt.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../search/screens/search_screen.dart';
import '../controller/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LocalizationController localizationController =
        Get.put(LocalizationController());
    final AuthService authService = Get.put(AuthService());
    final NetworkController networkController = Get.put(NetworkController());
    final ProfileController profileController = Get.put(ProfileController());
    final FirebaseAuth auth = FirebaseAuth.instance;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          showExitConfirmation();
        }
      },
      child: Obx(() => profileController.isEditing.value
          ? EditProfileScreen(
              controller: profileController,
              localizationController: localizationController)
          : ProfileViewScreen(
              localizationController: localizationController,
              authService: authService,
              networkController: networkController,
              profileController: profileController,
              auth: auth,
            )),
    );
  }
}

// Profile View Screen (Your existing design)
class ProfileViewScreen extends StatelessWidget {
  final LocalizationController localizationController;
  final AuthService authService;
  final NetworkController networkController;
  final ProfileController profileController;
  final FirebaseAuth auth;

  const ProfileViewScreen({
    Key? key,
    required this.localizationController,
    required this.authService,
    required this.networkController,
    required this.profileController,
    required this.auth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        automaticallyImplyLeading: false,
        toolbarHeight: Get.height * 0.05,
        title: Obx(() {
          return CustomTextWidget(
            title: localizationController.translate('My Profile'),
            fontSize: Get.height * 0.025,
            color: AppColors.black,
            fontWeight: FontWeight.w600,
          );
        }),
        actions: [
          TextButton(
              onPressed: profileController.toggleEdit,
              child: CustomTextWidget(
                title: localizationController.translate('Edit'),
                color: AppColors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              )),
          // LanguageTextButton(localizationController: localizationController),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: Get.width * 0.03, vertical: Get.height * 0.02),
        child: Center(child: Obx(() {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: !networkController.isConnected.value
                ? NoInternetWidegt()
                : Column(
                    spacing: screenHeight1,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Profile Image Section
                      CircleAvatar(
                        radius: screenHeight5,
                        backgroundColor: AppColors.primaryColor,
                        child: ClipOval(
                            child: CachedNetworkImage(
                          imageUrl: auth.currentUser?.photoURL ??
                              "https://i.postimg.cc/VLRdMxPK/profileimage.png",
                          useOldImageOnUrlChange: false,
                          width: screenHeight10,
                          height: screenHeight10,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) {
                            return const Icon(
                              Icons.error,
                              color: AppColors.primaryColor,
                            );
                          },
                        )),
                      ),

                      // Name Section
                      Obx(() {
                        return profileController.isLoading.value
                            ? LoadingAnimationWidget.threeRotatingDots(
                                size: screenHeight2,
                                color: AppColors.primaryColor,
                              )
                            : CustomTextWidget(
                                title: profileController.displayName,
                                fontSize: H18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              );
                      }),

                      // Email Section
                      CustomTextWidget(
                        title: auth.currentUser?.email ?? "",
                        fontSize: H18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),

                      // Professional Info Section (New)
                      _buildProfessionalInfo(),
                      kHeight(0.02),
                      // Stats Section (New)
                      _buildStatsRow(),

                      kHeight(0.01),

                      TestimonialSection(),
                      kHeight(0.01),
                      // Menu Items Section
                      _buildBottomTabs(),

                      SizedBox(height: Get.height * 0.02),

                      // Logout Button
                      CustomButtonWidget(
                        buttonTitle: localizationController.translate('logout'),
                        buttonShape: "rect",
                        buttonColor: AppColors.white,
                        buttonWidth: screenWidth * 0.4,
                        borderColor: AppColors.error,
                        buttonTextColor: AppColors.secondaryColor,
                        onPressed: () {
                          Get.defaultDialog(
                            title: "Logout",
                            middleText: "Are you sure you want to log out?",
                            textConfirm: "Yes",
                            textCancel: "No",
                            buttonColor: AppColors.secondaryColor,
                            confirmTextColor: Colors.white,
                            onConfirm: () {
                              authService.signOut();
                              Get.back();
                            },
                          );
                        },
                      ),

                      SizedBox(height: Get.height * 0.02),
                    ],
                  ),
          );
        })),
      ),
    );
  }

  Widget _buildBottomTabs() {
    return Column(
      children: [
        buildMenuTile(
          leading: Icon(HugeIcons.strokeRoundedDocumentValidation),
          title: localizationController.translate('terms_and_condition'),
          onTap: () {},
        ),
        kHeight(0.01),
        buildMenuTile(
          leading: Icon(HugeIcons.strokeRoundedSecurityCheck),
          title: localizationController.translate('privacy_policy'),
          onTap: () {},
        ),
        kHeight(0.01),
        buildMenuTile(
          leading: Icon(HugeIcons.strokeRoundedAlert01),
          title: localizationController.translate('disclaimers'),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildProfessionalInfo() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified,
              color: AppColors.blueColor,
              size: smallIconSize,
            ),
            kWidth(0.01),
            CustomTextWidget(
              title: 'Verified Real Estate Agent',
              fontSize: H18,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ],
        ),
        kHeight(0.01),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              width: Get.width * 0.15,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.whiteLight),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.orange,
                    size: smallIconSize,
                  ),
                  kWidth(0.01),
                  Text(
                    '4.8',
                    style: TextStyle(
                      fontSize: tagTitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black600,
                    ),
                  ),
                ],
              ),
            ),
            kWidth(0.01),
            CustomTextWidget(
              title: '(120 reviews)',
              fontSize: tagTitle,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGrey,
            ),
          ],
        ),
        kHeight(0.01),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on,
              color: AppColors.black,
              size: smallIconSize,
            ),
            kWidth(0.01),
            CustomTextWidget(
              title: 'Kerala, India',
              fontSize: tagTitle,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth8, vertical: screenWidth2),
      margin: EdgeInsets.symmetric(horizontal: screenWidth2),
      decoration: BoxDecoration(
        color: AppColors.whiteLight,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem('24', 'Listings'),
          _buildStatItem('14', 'Sold Property'),
          _buildStatItem('5Y', 'Experience'),
          _buildStatItem('48L', 'Sales'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        CustomTextWidget(
          title: value,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        kHeight(0.002),
        CustomTextWidget(
          title: label,
          fontSize: tagTitle,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      ],
    );
  }
}
