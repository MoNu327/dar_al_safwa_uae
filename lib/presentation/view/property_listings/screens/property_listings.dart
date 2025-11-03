import 'package:cached_network_image/cached_network_image.dart';
import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/data/model/search_property_model.dart';
import 'package:majan/presentation/view_model/localization_controller.dart';
import 'package:majan/presentation/view_model/property_listing_controller.dart';
import 'package:majan/presentation/widgets/custom_elevated_button.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/presentation/widgets/loader_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class PropertyListings extends StatelessWidget {
  PropertyListings({super.key});

  final LocalizationController localizationController = Get.find();

  @override
  Widget build(BuildContext context) {
    final PropertyListingController controller =
        Get.put(PropertyListingController());
    final bool isArabic = Get.locale?.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Obx(() {
          // Loading state
          if (controller.isLoadingSearchResults.value) {
            return const Center(child: CustomLoaderWidget());
          }

          // Error state with back button
          if (controller.searchResultErrorMessage.isNotEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: screenHeight * 0.25,
                      child: Lottie.asset(
                        fit: BoxFit.contain,
                        "assets/lottie/NotFoundLottie.json",
                      ),
                    ),
                    kHeight(0.02),
                    CustomTextWidget(
                      title: controller.searchResultErrorMessage.value,
                      textAlign: TextAlign.center,
                      fontSize: screenHeight * 0.022,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryColor,
                    ),
                    kHeight(0.01),
                    CustomTextWidget(
                      title: localizationController.translate('adjust_search_filters') ?? 
                             'Try adjusting your search filters',
                      textAlign: TextAlign.center,
                      fontSize: screenHeight * 0.018,
                      color: Colors.grey,
                    ),
                    kHeight(0.04),
                    // Action buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Back button
                        ElevatedButton.icon(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.arrow_back, size: 20),
                          label: CustomTextWidget(
                            title: localizationController.translate('back') ?? 'Back',
                            color: Colors.white,
                            fontSize: screenHeight * 0.018,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                              vertical: screenHeight * 0.018,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.04),
                        // Retry button
                        ElevatedButton.icon(
                          onPressed: controller.fetchSearchResult,
                          icon: const Icon(Icons.refresh, size: 20),
                          label: CustomTextWidget(
                            title: localizationController.translate('retry') ?? 'Retry',
                            color: Colors.white,
                            fontSize: screenHeight * 0.018,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                              vertical: screenHeight * 0.018,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          // Empty results state with back button
          final properties = controller.searchResults.value?.data ?? [];
          if (properties.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Get.width * 0.05,
                vertical: Get.height * 0.05,
              ),
              child: Column(
                children: [
                  _buildHeaderWithoutProperty(isArabic),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: screenHeight * 0.25,
                              child: Lottie.asset(
                                fit: BoxFit.contain,
                                "assets/lottie/NotFoundLottie.json",
                              ),
                            ),
                            kHeight(0.02),
                            CustomTextWidget(
                              title: localizationController.translate('no_properties_found') ?? 
                                     'No properties found matching your criteria',
                              textAlign: TextAlign.center,
                              fontSize: screenHeight * 0.022,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryColor,
                            ),
                            kHeight(0.01),
                            CustomTextWidget(
                              title: localizationController.translate('try_different_filters') ?? 
                                     'Try different search filters or criteria',
                              textAlign: TextAlign.center,
                              fontSize: screenHeight * 0.018,
                              color: Colors.grey,
                            ),
                            kHeight(0.04),
                            // Action buttons row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Back to Search button
                                ElevatedButton.icon(
                                  onPressed: () => Get.back(),
                                  icon: const Icon(Icons.arrow_back, size: 20),
                                  label: CustomTextWidget(
                                    title: localizationController.translate('back_to_search') ?? 'Back to Search',
                                    color: Colors.white,
                                    fontSize: screenHeight * 0.018,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondaryColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.05,
                                      vertical: screenHeight * 0.018,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.04),
                                // New Search button
                                ElevatedButton.icon(
                                  onPressed: () => Get.back(),
                                  icon: const Icon(Icons.search, size: 20),
                                  label: CustomTextWidget(
                                    title: localizationController.translate('new_search') ?? 'New Search',
                                    color: Colors.white,
                                    fontSize: screenHeight * 0.018,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.05,
                                      vertical: screenHeight * 0.018,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Property list with results
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: Get.width * 0.05,
              vertical: Get.height * 0.05,
            ),
            child: Column(
              children: [
                _buildHeader(properties.first, isArabic),
                SizedBox(height: Get.height * 0.02),
                _buildPropertyList(properties, isArabic),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader(Property property, bool isArabic) {
    final controller = Get.find<PropertyListingController>();

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: Get.height * 0.005,
      ),
      decoration: BoxDecoration(
        color: AppColors.whiteLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightGrey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.black600,
              size: Get.height * 0.02,
            ),
            onPressed: () => Get.back(),
          ),
          Expanded(
            child: CustomTextWidget(
              fontSize: tagTitle,
              title: isArabic
                  ? '${controller.propertyTypeName} | ${controller.propertyLocationName} | ${controller.propertyBedsBathName}'
                  : '${controller.propertyTypeName} | ${controller.propertyLocationName} | ${controller.propertyBedsBathName}',
              fontWeight: FontWeight.w500,
              color: AppColors.black600,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderWithoutProperty(bool isArabic) {
    final controller = Get.find<PropertyListingController>();

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: Get.height * 0.005,
      ),
      decoration: BoxDecoration(
        color: AppColors.whiteLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightGrey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.black600,
              size: Get.height * 0.02,
            ),
            onPressed: () => Get.back(),
          ),
          Expanded(
            child: CustomTextWidget(
              fontSize: tagTitle,
              title: isArabic
                  ? '${controller.propertyTypeName} | ${controller.propertyLocationName} | ${controller.propertyBedsBathName}'
                  : '${controller.propertyTypeName} | ${controller.propertyLocationName} | ${controller.propertyBedsBathName}',
              fontWeight: FontWeight.w500,
              color: AppColors.black600,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyList(List<Property> properties, bool isArabic) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return _buildPropertyItem(property, isArabic);
      },
    );
  }

  Widget _buildPropertyItem(Property property, bool isArabic) {
    final controller = Get.find<PropertyListingController>();

    return GestureDetector(
      onTap: () => controller.navigateToPropertyDetails(property),
      child: Container(
        margin: EdgeInsets.only(bottom: Get.height * 0.02),
        padding: EdgeInsets.all(Get.width * 0.03),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: .5, color: AppColors.lightGrey),
          boxShadow: [
            BoxShadow(
              color: AppColors.lightGrey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Property Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: property.image ?? '',
                width: Get.width * 0.35,
                height: Get.height * 0.23,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.secondaryColor,
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.error,
                  color: AppColors.lightGrey,
                ),
              ),
            ),
            SizedBox(width: Get.width * 0.05),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPropertyTitle(property, isArabic),
                  _buildPropertyDetails(property, isArabic),
                  kHeight(0.01),
                  _buildRatingSection(property, isArabic),
                  kHeight(0.01),
                  _buildPriceSection(property, isArabic),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyTitle(Property property, bool isArabic) {
    return Column(
      spacing: screenHeight1,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: isArabic ? property.title?.ar : property.title?.en,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryColor,
        ),
        CustomTextWidget(
          title: isArabic ? property.type?.ar : property.type?.en,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      ],
    );
  }

  Widget _buildPropertyDetails(Property property, bool isArabic) {
    return Column(
      spacing: screenHeight1,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: isArabic ? property.location?.ar : property.location?.en,
          fontWeight: FontWeight.w400,
          color: AppColors.black500,
        ),
        Row(
          children: [
            Icon(
              Icons.dashboard,
              color: AppColors.black,
              size: Get.height * 0.02,
            ),
            SizedBox(width: Get.width * 0.02),
            CustomTextWidget(
              title:
                  '${isArabic ? property.specs?.area?.ar : property.specs?.area?.en ?? '0'} ${localizationController.translate('sq_ft')}',
              fontWeight: FontWeight.w500,
              color: AppColors.black600,
            ),
          ],
        ),
        Row(
          children: [
            Icon(
              Icons.bed,
              color: AppColors.black,
              size: Get.height * 0.02,
            ),
            SizedBox(width: Get.width * 0.02),
            CustomTextWidget(
              title: '${property.specs?.beds ?? 0}',
              fontWeight: FontWeight.w500,
              color: AppColors.black600,
            ),
            SizedBox(width: Get.width * 0.05),
            Icon(
              Icons.bathtub,
              color: AppColors.black,
              size: Get.height * 0.02,
            ),
            SizedBox(width: Get.width * 0.02),
            CustomTextWidget(
              title: '${property.specs?.baths ?? 0}',
              fontWeight: FontWeight.w500,
              color: AppColors.black600,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingSection(Property property, bool isArabic) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: screenHeight * 0.003,
      ),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 247, 230, 179),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.005),
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star_rounded,
              color: const Color.fromARGB(255, 252, 228, 158),
              size: screenHeight * 0.02,
            ),
          ),
          SizedBox(width: Get.width * 0.015),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextWidget(
                title: '${property.rating?.average ?? '0.0'}/5',
                fontSize: screenHeight * 0.015,
                color: AppColors.black,
                fontWeight: FontWeight.w600,
              ),
              CustomTextWidget(
                title:
                    '(${property.rating?.count ?? 0} ${localizationController.translate('review')})',
                fontSize: screenHeight1,
                color: AppColors.black,
                fontWeight: FontWeight.w500,
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(Property property, bool isArabic) {
    final price = property.price;
    final formattedPrice = isArabic
        ? (price?.formatted?.ar?.isNotEmpty ?? false
            ? price!.formatted!.ar
            : '${price?.raw ?? 0} AED')
        : (price?.formatted?.en?.isNotEmpty ?? false
            ? price!.formatted!.en
            : '${price?.raw ?? 0} AED');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title:
              '$formattedPrice/${localizationController.translate('per_section')}',
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryColor,
        ),
      ],
    );
  }
}