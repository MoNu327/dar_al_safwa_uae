import 'package:cached_network_image/cached_network_image.dart';
import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:dar_al_safwa/presentation/view/property_details/widgets/about_content.dart';
import 'package:dar_al_safwa/presentation/view/property_details/widgets/gallery.dart';
import 'package:dar_al_safwa/presentation/view/property_details/widgets/reviews.dart';
import 'package:dar_al_safwa/presentation/view/property_details/widgets/user_details_submission.dart';
import 'package:dar_al_safwa/presentation/view/property_details/widgets/view_360.dart';
import 'package:dar_al_safwa/presentation/view_model/localization_controller.dart';
import 'package:dar_al_safwa/presentation/view/property_details/controller/property_details_controller.dart';
import 'package:dar_al_safwa/presentation/view_model/login_controller.dart';
import 'package:dar_al_safwa/presentation/view_model/video_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_elevated_button.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/widgets/loader_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../view_model/firebase_auth_controller.dart';
import '../widgets/property_unit_selector_widget.dart';

class PropertyDetailsScreen extends StatelessWidget {
  PropertyDetailsScreen({super.key});

  final LocalizationController localizationController = Get.find();
  final PropertyDetailsController propertyDetailsController =
      Get.put(PropertyDetailsController());

  final AuthService auth = Get.find();
  final VideoController videoController = Get.put(VideoController());
  final isArabic = Get.locale?.languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Obx(() {
          final isLoading = propertyDetailsController.isLoading.value;
          final errorMessage = propertyDetailsController.errorMessage.value;
          final property = propertyDetailsController.property.value;
          // Loading state
          if (isLoading) {
            return const Center(child: CustomLoaderWidget());
          }
          // Error state
          if (errorMessage != null) {
            return _buildErrorState(errorMessage);
          }
          // Error state
          if (propertyDetailsController.errorMessage.value != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  CustomTextWidget(
                    title: 'Failed to load property details',
                    fontSize: tagTitle,
                  ),
                  CustomTextWidget(
                    title: propertyDetailsController.errorMessage.value ??
                        'Unknown error',
                    fontSize: tagTitle,
                    textAlign: TextAlign.center,
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        propertyDetailsController.fetchPropertyDetails(
                            propertyDetailsController.idParams.value),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Success state
          if (property != null) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Get.width * 0.03,
                  vertical: Get.height * 0.02,
                ),
                child: Column(
                  spacing: screenHeight * 0.01,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: screenHeight3,
                        bottom: screenHeight1,
                      ),
                      child: _buildHeader((isArabic
                              ? property.title?.ar
                              : property.title?.en) ??
                          "Unknown"),
                    ),
                    Stack(
                      children: [
                        // Main Image Display
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: (property.highlightImages != null &&
                                    property.highlightImages!.isNotEmpty
                                ? property.highlightImages![
                                    propertyDetailsController
                                        .currentIndex.value]
                                : propertyDetailsController.imageUrls[
                                    propertyDetailsController
                                        .currentIndex.value]),
                            width: double.infinity,
                            height: screenHeight * 0.25,
                            fit: BoxFit.fill,
                            placeholder: (context, url) => Container(
                              color: AppColors.white,
                              child: const Center(
                                child: CustomLoaderWidget(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.white,
                              child: const Icon(Icons.error),
                            ),
                          ),
                        ),

                        // Thumbnail List
                        if ((property.highlightImages != null &&
                                property.highlightImages!.length > 1) ||
                            (property.highlightImages == null &&
                                propertyDetailsController.imageUrls.length > 1))
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.01,
                                vertical: screenHeight * 0.01,
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.02,
                                  vertical: screenHeight * 0.005,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                ),
                                height: Get.height * 0.06,
                                child: const ImageListView(),
                              ),
                            ),
                          ),

                        auth.userRole == "agent"
                            ? SizedBox.shrink()
                            : Positioned(
                                top: 0,
                                right: 0,
                                child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.01,
                                      vertical: screenHeight * 0.01,
                                    ),
                                      child: CustomButtonWidget(
  onPressed: () {
    if (auth.userRole == null || auth.userRole == "guest") {
      // Show Snackbar
      Get.snackbar(
        "Login Required",
        "You are a guest. Please login to book this property.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.black,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(12),
      );

      // Set redirect and navigate to login
      final loginController = Get.put(LoginController());
      loginController.postLoginRedirectArgs = {
        'redirectToBooking': true,
        'propertyId': property?.id ?? 0,
      };
      Get.toNamed(AppRoute.login);
    } else {
      // User is logged in, proceed to booking
      Get.to(
        () => UserDetailsSubmission(),
        arguments: {
          'propertyId': property?.id?.toString() ?? '0',
          'unitId': "1",
        },
      );
    }
  },
  borderColor: AppColors.white,
  buttonTextColor: AppColors.secondaryColor,
  buttonHeight: screenHeight * 0.04,
  buttonWidth: screenWidth * 0.35,
  buttonTitle: "Book Now !",
  buttonColor: AppColors.primaryColor,
)
),
                              ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // _buildTagContainer(
                            //   label: localizationController
                            //       .translate('property_type'),
                            // ),
                            // kWidth(0.02),
                            _buildTagContainer(
                              label: isArabic
                                  ? property.dealType?.ar
                                  : property.dealType?.en ??
                                      localizationController
                                          .translate('property_status'),
                            )
                          ],
                        ),
                        Row(
                          spacing: screenWidth * 0.005,
                          children: [
                            Icon(
                              Icons.star,
                              color: AppColors.primaryColor,
                              size: screenHeight2,
                            ),
                            _buildReviewTextWidget(
                                label: property.reviews?.overall?.rating
                                        ?.toString() ??
                                    '0'),
                            _buildReviewTextWidget(
                                label: property.reviews?.overall?.count !=
                                            null ||
                                        property.reviews?.overall?.count == 0
                                    ? '(${property.reviews?.overall?.count?.toString()} Reviews)'
                                    : '(No Reviews)')
                          ],
                        )
                      ],
                    ),
                    CustomTextWidget(
                      title: isArabic
                          ? property.title?.ar
                          : property.title?.en ?? "Unknown",
                      color: AppColors.secondaryColor,
                      fontSize: Get.height * 0.02,
                      fontWeight: FontWeight.w500,
                    ),
                    CustomTextWidget(
                      title: isArabic
                          ? property.location?.address?.full?.ar
                          : property.location?.address?.full?.en ??
                              localizationController.translate('address'),
                      color: AppColors.lightGrey,
                      fontSize: Get.height * 0.015,
                      fontWeight: FontWeight.w500,
                    ),
                    CustomTabBar(tabs: [
                      localizationController.translate('about'),
                      localizationController.translate('gallery'),
                      localizationController.translate('360view'),
                      localizationController.translate('review'),
                    ])
                  ],
                ),
              ),
            );
          }
          return _buildEmptyState();
        }),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          CustomTextWidget(
            title: 'Failed to load property details',
            fontSize: tagTitle,
          ),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
          ),
          ElevatedButton(
            onPressed: () => propertyDetailsController
                .fetchPropertyDetails(propertyDetailsController.idParams.value),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.house_outlined, size: 48, color: Colors.grey),
          CustomTextWidget(
            title: 'No property data available',
            fontSize: tagTitle,
          ),
          ElevatedButton(
            onPressed: () => propertyDetailsController.fetchPropertyDetails(1),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // Header Section with back button and search result
  Widget _buildHeader(String title) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Get.width * 0.05,
        vertical: Get.height * 0.02,
      ),
      decoration: BoxDecoration(
        color: AppColors.whiteLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightGrey.withValues(alpha: .2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: propertyDetailsController.navigateToBack,
            borderRadius: BorderRadius.circular(50),
            splashColor: AppColors.splashBackgroundColor,
            child: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.black600,
              size: Get.height * 0.02,
            ),
          ),
          SizedBox(width: Get.width * 0.03),
          CustomTextWidget(
            fontSize: tagTitle,
            title: title,
            fontWeight: FontWeight.w500,
            color: AppColors.black600,
          ),
        ],
      ),
    );
  }

// Reusable widget for tags
  Widget _buildTagContainer({required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Get.width * 0.025,
        vertical: Get.height * 0.005,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.all(
          Radius.circular(12),
        ),
      ),
      child: CustomTextWidget(
        title: label,
        color: AppColors.black,
        fontSize: Get.height * 0.015,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  _buildReviewTextWidget({required String label}) {
    return CustomTextWidget(
      title: label,
      color: AppColors.black,
      fontSize: Get.height * 0.015,
      fontWeight: FontWeight.w500,
    );
  }
}

//Highlight image view
class ImageListView extends StatelessWidget {
  const ImageListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PropertyDetailsController>();

    return Obx(() {
      final property = controller.property.value;
      final images = property?.highlightImages ?? [];

      // Don't show if there's less than 2 images
      if (images.length <= 1) {
        return const SizedBox.shrink();
      }

      return ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        physics: images.length > 3
            ? const BouncingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final isSelected = index == controller.currentIndex.value;

          return Padding(
            padding: EdgeInsets.only(right: Get.width * 0.01),
            child: Center(
              child: GestureDetector(
                onTap: () => controller.changeImage(index),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(
                                color: AppColors.primaryColor,
                                width: 2,
                              )
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: _buildImage(images[index]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: Get.height * 0.05,
      height: Get.height * 0.05,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(child: CustomLoaderWidget()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.error, size: 20),
      ),
    );
  }
}

class CustomTabBar extends StatefulWidget {
  final List<String> tabs;

  const CustomTabBar({super.key, required this.tabs});

  @override
  _CustomTabBarState createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          isScrollable: false,
          controller: _tabController,
          tabs: widget.tabs
              .map((tab) => Tab(
                    text: tab,
                  ))
              .toList(),
          labelColor: AppColors.blueColor,
          unselectedLabelColor: AppColors.black,
          labelStyle: GoogleFonts.poppins(
            fontSize: Get.height * 0.015,
            fontWeight: FontWeight.w500,
          ),
          indicatorColor: AppColors.blueColor,
          indicatorWeight: 3.0,
        ),
        SizedBox(
          height: Get.height * 0.5,
          child: TabBarView(
            controller: _tabController,
            children: [
              // About Tab
              AboutContent(),

              // Gallery Tab
              Gallery(),

              // 360 view tab
              View360(
                imageUrls: [
                  "https://media.istockphoto.com/id/2214948492/video/kitchen-renovation-before-and-after.mp4?s=mp4-640x640-is&k=20&c=XHAhvly5dK0UyfMa8BVL7ROf-6ZprI-hcTPnBMgml3s="
                ],
                // videoUrls: [
                //   "https://videos.pexels.com/video-files/7578554/7578554-uhd_2560_1440_30fps.mp4",
                //   // "https://videos.pexels.com/video-files/15887134/15887134-uhd_2560_1440_30fps.mp4"
                //   "https://videos.pexels.com/video-files/15353502/15353502-sd_640_360_24fps.mp4"
                // ],
              ),

              // Review Tab
              Reviews(),
            ],
          ),
        ),
      ],
    );
  }
}
