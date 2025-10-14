import 'package:cached_network_image/cached_network_image.dart';
import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/routes/app_route.dart';
import 'package:majan/presentation/view/property_details/widgets/about_content.dart';
import 'package:majan/presentation/view/property_details/widgets/gallery.dart';
import 'package:majan/presentation/view/property_details/widgets/reviews.dart';
import 'package:majan/presentation/view/property_details/widgets/user_details_submission.dart';
import 'package:majan/presentation/view/property_details/widgets/view_360.dart';
import 'package:majan/presentation/view_model/localization_controller.dart';
import 'package:majan/presentation/view/property_details/controller/property_details_controller.dart';
import 'package:majan/presentation/view_model/login_controller.dart';
import 'package:majan/presentation/view_model/video_controller.dart';
import 'package:majan/presentation/widgets/custom_elevated_button.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/core/theme/app_colors.dart'; 
import 'package:majan/presentation/widgets/loader_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../view_model/firebase_auth_controller.dart';

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
    // Get the arguments passed from the previous screen
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final propertyId = int.tryParse(args['propertyId']?.toString() ?? '0') ?? 0;
    final unitId = int.tryParse(args['unitId']?.toString() ?? '0') ?? 0;
    final unitType = args['unitType'] as int? ?? 0;
    final propertyType = args['propertyType'] as String? ?? 'residential';
    final propertyTitle = args['propertyTitle'] as String? ?? 'Unknown Property';
    
    // Debug print to verify arguments
    print('PropertyDetailsScreen - Received arguments:');
    print('propertyId: $propertyId');
    print('unitId: $unitId');
    print('unitType: $unitType');
    print('propertyType: $propertyType');
    print('propertyTitle: $propertyTitle'); 
    
  
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
                                    onPressed: () => _handleBookNowPressed(
                                      propertyId,
                                      unitId,
                                      unitType,
                                      propertyType,
                                      property.title?.en ?? "Unknown Property",
                                    ),
                                    borderColor: AppColors.white,
                                    buttonTextColor: AppColors.secondaryColor,
                                    buttonHeight: screenHeight * 0.04,
                                    buttonWidth: screenWidth * 0.35,
                                    buttonTitle: "Book Now !",
                                    buttonColor: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                      ],
                    ),
                    
                    // Property Type Indicator (Optional - to show current property type)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenHeight * 0.01,
                      ),
                      decoration: BoxDecoration(
                        color: unitType == 1 ? AppColors.secondaryColor.withOpacity(0.1) : AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: unitType == 1 ? AppColors.secondaryColor : AppColors.primaryColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            unitType == 1 ? Icons.business : Icons.home,
                            color: unitType == 1 ? AppColors.secondaryColor : AppColors.secondaryColor,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          CustomTextWidget(
                            title: propertyType.toUpperCase(),
                            color: unitType == 1 ? AppColors.secondaryColor : AppColors.secondaryColor,
                            fontSize: Get.height * 0.014,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
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
                    ]
                    )
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

  // Handle Book Now button press with unit type selection
void _handleBookNowPressed(int propertyId, int unitId, int unitType, String propertyType, String propertyName) {
  if (auth.userRole == null || auth.userRole == "guest") {
    Get.snackbar(
      "Login Required",
      "You are a guest. Please login to book this property.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primaryColor,
      colorText: AppColors.black,
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(12),
    );

    final loginController = Get.put(LoginController());
    loginController.postLoginRedirectArgs = {
      'redirectToBooking': true,
      'propertyId': propertyId,
      'unitId': unitType,
      // 'unitType': unitType,
      'propertyType': propertyType,
      'propertyTitle': propertyName, // Add this line
    };
    Get.toNamed(AppRoute.login);
  } else {
    _showUnitTypeBottomSheetForBooking(propertyId, unitId, unitType, propertyType, propertyName);
  }
}

  // Show unit type bottom sheet for booking
 void _showUnitTypeBottomSheetForBooking(int propertyId, int unitId, int initialUnitType, String propertyType, String propertyName) {
  final unitTypes = propertyDetailsController.property.value?.unitTypes?.data ?? [];

  if (unitTypes.isEmpty) {
    Get.snackbar(
      "No Unit Types",
      "No unit types available for this property.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.black,
    );
    return;
  }

  // Reset selection state in controller
  propertyDetailsController.selectedUnitTypeIndex.value = -1;
  propertyDetailsController.selectedCount.value = 1;

  Get.bottomSheet(
    Container(
      height: Get.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomTextWidget(
                  title: "Select Unit Type for Booking",
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryColor,
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Unit Type Selection
                  const Text(
                    "Choose Unit Type:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Unit Types List
                  ...unitTypes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final unitType = entry.value;
                    final title = unitType.unitType?.name?.en ?? "Unknown";
                    final subtitle = unitType.unitType?.description?.en ?? "";
                    // Check if this unit type is commercial based on the name or any flag
                    final isCommercial = title.toLowerCase().contains('commercial') || 
                                       title.toLowerCase().contains('office') || 
                                       title.toLowerCase().contains('shop') ||
                                       title.toLowerCase().contains('warehouse');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Obx(() => InkWell(
                        onTap: () {
                          propertyDetailsController.selectedUnitTypeIndex.value = index;
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: propertyDetailsController.selectedUnitTypeIndex.value == index
                                  ? AppColors.primaryColor
                                  : Colors.grey[300]!,
                              width: propertyDetailsController.selectedUnitTypeIndex.value == index ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: propertyDetailsController.selectedUnitTypeIndex.value == index
                                ? AppColors.primaryColor.withOpacity(0.1)
                                : Colors.white,
                          ),
                          child: Row(
                            children: [
                              // Icon based on type
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: propertyDetailsController.selectedUnitTypeIndex.value == index
                                      ? AppColors.primaryColor
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  isCommercial ? Icons.business : Icons.home,
                                  color: propertyDetailsController.selectedUnitTypeIndex.value == index
                                      ? Colors.white
                                      : Colors.grey[600],
                                  size: 20,
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: propertyDetailsController.selectedUnitTypeIndex.value == index
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: propertyDetailsController.selectedUnitTypeIndex.value == index
                                            ? AppColors.primaryColor
                                            : Colors.black87,
                                      ),
                                    ),
                                    if (subtitle.isNotEmpty) ...[
                                      SizedBox(height: 4),
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              // Selection indicator
                              Icon(
                                propertyDetailsController.selectedUnitTypeIndex.value == index
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: propertyDetailsController.selectedUnitTypeIndex.value == index
                                    ? AppColors.primaryColor
                                    : Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      )),
                    );
                  }).toList(),

                  // Quantity Selection (show only when unit type is selected)
                  Obx(() => propertyDetailsController.selectedUnitTypeIndex.value != -1
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            const Text(
                              "Select Quantity:",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(10, (index) {
                                final count = index + 1;
                                return Obx(() => InkWell(
                                  onTap: () {
                                    propertyDetailsController.selectedCount.value = count;
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: propertyDetailsController.selectedCount.value == count
                                            ? AppColors.primaryColor
                                            : Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      color: propertyDetailsController.selectedCount.value == count
                                          ? AppColors.primaryColor
                                          : Colors.white,
                                    ),
                                    child: Text(
                                      count.toString(),
                                      style: TextStyle(
                                        color: propertyDetailsController.selectedCount.value == count
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: propertyDetailsController.selectedCount.value == count
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ));
                              }),
                            ),
                          ],
                        )
                      : const SizedBox()),
                ],
              ),
            ),
          ),

          // Bottom action button
          Obx(() => propertyDetailsController.selectedUnitTypeIndex.value != -1
              ? Container(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButtonWidget(
                      onPressed: () {
                        Get.back(); // Close bottom sheet
                        _proceedToBooking(propertyId, unitId, propertyName);
                      },
                      buttonColor: AppColors.secondaryColor,
                      buttonTextColor: Colors.white,
                      buttonHeight: Get.height * 0.06,
                      buttonTitle: _getBookingButtonText(unitTypes),
                    ),
                  ),
                )
              : const SizedBox()),
        ],
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true
  );
}

  // Build unit type option widget
  Widget _buildUnitTypeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required int value,
    required int selectedValue,
    required VoidCallback onTap,
  }) {
    final bool isSelected = value == selectedValue;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.secondaryColor : AppColors.lightGrey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryColor : AppColors.lightGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.white : AppColors.black,
                size: 24,
              ),
            ),
            
            SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextWidget(
                    title: title,
                    fontSize: Get.height * 0.018,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primaryColor : AppColors.secondaryColor,
                  ),
                  SizedBox(height: 4),
                  CustomTextWidget(
                    title: subtitle,
                    fontSize: Get.height * 0.014,
                    fontWeight: FontWeight.w400,
                    color: AppColors.lightGrey,
                  ),
                ],
              ),
            ),
            
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primaryColor,
                size: 24,
              ),
          ],
        ),
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
  final args = Get.arguments as Map<String, dynamic>? ?? {};
  final propertyTitle = args['propertyTitle'] as String? ?? title;
  
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
          title: propertyTitle, // Use the property title from arguments
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

String _getBookingButtonText(List<dynamic> unitTypes) {
  final propertyDetailsController = Get.find<PropertyDetailsController>();
  if (propertyDetailsController.selectedUnitTypeIndex.value == -1) {
    return "Select Unit Type";
  }
  
  final selectedUnitType = unitTypes[propertyDetailsController.selectedUnitTypeIndex.value];
  final unitTypeName = selectedUnitType.unitType?.name?.en ?? 'Selection';
  return "Continue Booking $unitTypeName (${propertyDetailsController.selectedCount.value})";
}

// Proceed to booking with selected unit type
void _proceedToBooking(int propertyId, int unitId, String propertyName) {
  final propertyDetailsController = Get.find<PropertyDetailsController>();
  final unitTypes = propertyDetailsController.property.value?.unitTypes?.data ?? [];
  final selectedUnitType = unitTypes[propertyDetailsController.selectedUnitTypeIndex.value];
  final unitTypeId = selectedUnitType.unitType?.id ?? 0;
  final unitTypeName = selectedUnitType.unitType?.name?.en ?? "";
  
  final isCommercial = unitTypeName.toLowerCase().contains('commercial') || 
                      unitTypeName.toLowerCase().contains('office') || 
                      unitTypeName.toLowerCase().contains('shop') ||
                      unitTypeName.toLowerCase().contains('warehouse');
  
  Get.to(
    () => UserDetailsSubmission(),
    arguments: {
      'propertyId': propertyId.toString(),
      'unitId': unitTypeId,//unitId means the selected unittype ID thatmeans if it is 5bhk,
      // 'unitTypeId': unitTypeId,
      'selectedCount': propertyDetailsController.selectedCount.value,
      'propertyName': propertyName, // This is the title passed from homepage
      'propertyType': isCommercial ? 'commercial' : 'residential',
    },
  );
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