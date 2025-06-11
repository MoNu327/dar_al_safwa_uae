import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/view_model/localization_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/loader_widget.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../../../../data/model/property_banner_model.dart';

class PropertyBannerSlider extends StatelessWidget {
  final List<PropertyBannerModel> banners;
  final double height;
  final bool showIndicators;
  final ValueChanged<int>? onBannerSelected;

  const PropertyBannerSlider({
    super.key,
    required this.banners,
    this.height = 200,
    this.showIndicators = true,
    this.onBannerSelected,
  });

  @override
  Widget build(BuildContext context) {
    final currentIndex = 0.obs;
    final isArabic = Get.locale?.languageCode == 'ar';
    final LocalizationController localizationController =
        Get.put(LocalizationController());

    if (banners.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: CustomLoaderWidget(),
        ),
      );
    }

    return Column(
      spacing: screenHeight2,
      children: [
        CarouselSlider.builder(
          options: CarouselOptions(
            height: height,
            viewportFraction: 1,
            enableInfiniteScroll: banners.length > 1,
            autoPlay: banners.length > 1,
            onPageChanged: (index, _) => currentIndex.value = index,
          ),
          itemCount: banners.length,
          itemBuilder: (context, index, _) {
            final banner = banners[index];
            return BannerCard(
              imageUrl: banner.propertyImage ?? '',
              title: (isArabic
                      ? banner.propertyTitle?.ar
                      : banner.propertyTitle?.en) ??
                  'No Title',
              price: (isArabic
                      ? banner.propertyPrice?.formatted?.ar
                      : banner.propertyPrice?.formatted?.en) ??
                  'N/A',
              location: (isArabic
                      ? banner.propertyLocation?.ar
                      : banner.propertyLocation?.en) ??
                  'Unknown Location',
              features:
                  '${banner.propertyBed} ${localizationController.translate("bed")} | '
                  '${banner.propertyBath} ${localizationController.translate("bath")} | '
                  '${isArabic ? banner.propertySqft?.ar : banner.propertySqft?.en}',
            );
          },
        ),
        if (showIndicators && banners.length > 1)
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(banners.length, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentIndex.value == index
                          ? AppColors.secondaryColor
                          : AppColors.primaryColor,
                    ),
                  );
                }),
              )),
      ],
    );
  }
}

class BannerCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String location;
  final String features;

  const BannerCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.location,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.grey[200]),
              errorWidget: (_, __, ___) => Container(color: Colors.grey[300]),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Content
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextWidget(
                    title: title,
                    color: AppColors.white,
                    fontSize: popularPlaceTitle,
                    fontWeight: FontWeight.w600,
                  ),
                  CustomTextWidget(
                    title: price,
                    color: AppColors.white,
                    fontSize: tagTitle,
                    fontWeight: FontWeight.w600,
                  ),
                  CustomTextWidget(
                    title: location,
                    color: AppColors.white,
                    fontSize: tagTitle,
                    fontWeight: FontWeight.w600,
                  ),
                  CustomTextWidget(
                    title: features,
                    color: AppColors.white,
                    fontSize: tagTitle,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
