import 'package:cached_network_image/cached_network_image.dart';
import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomListWidget extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String subtitle;
  final String type;
  final String propertyDeal;
  final String location;
  final int bedrooms;
  final int bathrooms;
  final String? area;

  const CustomListWidget({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.subtitle,
    required this.type,
    required this.location,
    required this.propertyDeal,
    required this.bedrooms,
    required this.bathrooms,
    this.area,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.locale?.languageCode == 'ar';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight1),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.015,
          horizontal: screenWidth * 0.025,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.black600, width: 0.5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: screenWidth * 0.39,
                  height: screenWidth * 0.43,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    width: screenWidth * 0.39,
                    height: screenWidth * 0.43,
                  ),
                  errorWidget: (context, url, error) => Image.network(
                    'https://i.postimg.cc/Y90PCDgF/no-image-icon-6.png',
                    width: screenWidth * 0.39,
                    height: screenWidth * 0.43,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            kWidth(0.025),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomRichTextWidget(
                    title: "$title : ",
                    subTitle: price,
                    fontSize: Get.height * 0.018,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryColor,
                    subTextColor: AppColors.secondaryColor,
                    fontWeight2: FontWeight.w500,
                  ),
                  CustomTextWidget(
                    title: subtitle,
                    fontWeight: FontWeight.w500,
                    maxLines: 2,
                  ),
                  kHeight(0.005),
                  CustomRichTextWidget(
                    title: type,
                    fontWeight: FontWeight.w500,
                    subTitle: " | $location",
                    fontSize: Get.height * 0.012,
                    subTextColor: AppColors.black600,
                  ),
                  kHeight(0.005),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Get.width * 0.025,
                      vertical: Get.height * 0.004,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColorLight,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_offer,
                          color: Colors.white,
                          size: Get.width * 0.028,
                        ),
                        kWidth(0.01),
                        CustomTextWidget(
                          title: propertyDeal,
                          fontSize: screenHeight * 0.012,
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ],
                    ),
                  ),
                  kHeight(0.005),
                  FittedBox(
                    child: Row(
                      spacing: Get.height * 0.01,
                      children: [
                        const Icon(
                          Icons.dashboard_rounded,
                          color: AppColors.black600,
                        ),
                        CustomTextWidget(
                          title: area,
                          color: AppColors.black800,
                          fontSize: Get.height * 0.015,
                        ),
                      ],
                    ),
                  ),
                  FittedBox(
                    child: Row(
                      spacing: Get.height * 0.01,
                      children: [
                        const Icon(
                          Icons.bathtub_rounded,
                          color: AppColors.black600,
                        ),
                        CustomTextWidget(
                          title: bathrooms?.toString(),
                          color: AppColors.black800,
                          fontSize: Get.height * 0.015,
                        ),
                        const Icon(
                          Icons.bed_rounded,
                          color: AppColors.black600,
                        ),
                        CustomTextWidget(
                          title: bedrooms?.toString(),
                          color: AppColors.black800,
                          fontSize: Get.height * 0.015,
                        ),
                      ],
                    ),
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
