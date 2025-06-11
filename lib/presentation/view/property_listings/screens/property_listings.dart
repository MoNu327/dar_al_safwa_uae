import 'package:cached_network_image/cached_network_image.dart';
import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/data/model/search_property_model.dart';
import 'package:dar_al_safwa/presentation/view/login/login_screen.dart';
import 'package:dar_al_safwa/presentation/view_model/localization_controller.dart';
import 'package:dar_al_safwa/presentation/view_model/property_listing_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_elevated_button.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/loader_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
          if (controller.isLoadingSearchResults.value) {
            return const Center(child: CustomLoaderWidget());
          }

          if (controller.searchResultErrorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomTextWidget(
                    title: controller.searchResultErrorMessage.value,
                  ),
                  kHeight(0.01),
                  CustomButtonWidget(
                    buttonTitle: localizationController.translate('retry'),
                    onPressed: controller.fetchSearchResult,
                    buttonHeight: screenHeight * 0.06,
                    buttonWidth: screenWidth * 0.4,
                  )
                ],
              ),
            );
          }

          final properties = controller.searchResults.value?.data ?? [];
          if (properties.isEmpty) {
            return Center(
              child: CustomTextWidget(
                title: localizationController.translate('no_properties_found'),
              ),
            );
          }

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
                imageUrl: property.propertyImage ?? '',
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
          title: isArabic
              ? property.propertyTitle?.arabic
              : property.propertyTitle?.english,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryColor,
        ),
        CustomTextWidget(
          title: isArabic
              ? property.propertyType?.arabic
              : property.propertyType?.english,
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
          title: isArabic
              ? property.propertyLocation?.arabic
              : property.propertyLocation?.english,
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
                  '${isArabic ? property.propertySqft?.arabic : property.propertySqft?.english ?? '0'} ${localizationController.translate('sq_ft')}',
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
              title: '${property.propertyBed}',
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
              title: '${property.propertyBath}',
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
                title: '${property.propertyRating ?? '0.0'}/5',
                fontSize: screenHeight * 0.015,
                color: AppColors.black,
                fontWeight: FontWeight.w600,
              ),
              CustomTextWidget(
                title:
                    '(${property.propertyReviews ?? 0} ${localizationController.translate('review')})',
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
    final price = property.propertyPrice;
    final formattedPrice = isArabic
        ? (price?.formatted?.arabic?.isNotEmpty ?? false
            ? price!.formatted!.arabic
            : '${price?.raw ?? 0} OMR')
        : (price?.formatted?.english?.isNotEmpty ?? false
            ? price!.formatted!.english
            : '${price?.raw ?? 0} OMR');

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
