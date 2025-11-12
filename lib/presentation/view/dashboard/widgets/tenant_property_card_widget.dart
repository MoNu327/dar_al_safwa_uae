import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/custom_size.dart';

class TenantPropertyCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String location;
  final String expiryDate;
  final String sqft;
  final String bedrooms;
  final bool isExpiringSoon;
  final VoidCallback onTap;
  final int unit_address_id;
  final String unit_type;
  final String UnitNumber;

  const TenantPropertyCard({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.location,
    required this.expiryDate,
    required this.sqft,
    required this.bedrooms,
    required this.onTap,
    required this.UnitNumber,
    this.isExpiringSoon = false,
    this.unit_address_id = 0,
    this.unit_type = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: screenHeight2),
        decoration: BoxDecoration(
          color: AppColors.whiteLight,
          borderRadius: BorderRadius.circular(screenWidth4),
          boxShadow: [
            BoxShadow(
              color: AppColors.lightGrey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Unit Number Badge
            Stack(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 8, left: 8, right: 8),
                  height: screenHeight * 0.20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenWidth4),
                    image: DecorationImage(
                      image: NetworkImage(
                        imageUrl.isNotEmpty
                            ? imageUrl
                            : 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                // Unit Number Badge (Top Right)
                if (UnitNumber.isNotEmpty)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenHeight * 0.008,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.home,
                            size: 14,
                            color: AppColors.white,
                          ),
                          SizedBox(width: 4),
                          CustomTextWidget(
                            title: 'Unit $UnitNumber',
                            fontSize: detailContentTitle,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Content Section
            Padding(
              padding: EdgeInsets.all(screenWidth4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CustomTextWidget(
                          title: title,
                          fontSize: H18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      CustomTextWidget(
                        title: price,
                        fontSize: H18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryColor,
                      ),
                    ],
                  ),
                  kHeight(0.005),

                  // Location
                  CustomTextWidget(
                    title: location,
                    fontSize: detailContentTitle,
                    color: AppColors.darkGrey,
                    fontWeight: FontWeight.w600,
                  ),
                  kHeight(0.01),

                  // Expiry Date with Warning
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppColors.primaryColor,
                        ),
                        child: CustomTextWidget(
                          title: expiryDate,
                          fontSize: detailContentTitle,
                          color: isExpiringSoon
                              ? AppColors.secondaryColor
                              : AppColors.secondaryColor,
                          fontWeight: isExpiringSoon
                              ? FontWeight.w600
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  kHeight(0.015),

                  // Property Details Row
                  Row(
                    children: [
                      // Square Feet
                      Row(
                        children: [
                          Icon(
                            Icons.crop_free,
                            size: smallIconSize,
                            color: AppColors.black,
                          ),
                          kWidth(0.01),
                          CustomTextWidget(
                            title: sqft,
                            fontSize: detailContentTitle,
                            color: AppColors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                      kWidth(0.06),

                      // Bedrooms
                      Row(
                        children: [
                          Icon(
                            Icons.bed_outlined,
                            size: smallIconSize,
                            color: AppColors.black,
                          ),
                          kWidth(0.01),
                          CustomTextWidget(
                            title: bedrooms,
                            fontSize: detailContentTitle,
                            color: AppColors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ],
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

// ============================================
// ALTERNATIVE DESIGN OPTIONS
// ============================================

// Option 2: Unit Number Below Location
class TenantPropertyCardOption2 extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String location;
  final String expiryDate;
  final String sqft;
  final String bedrooms;
  final bool isExpiringSoon;
  final VoidCallback onTap;
  final int unit_address_id;
  final String unit_type;
  final String UnitNumber;

  const TenantPropertyCardOption2({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.location,
    required this.expiryDate,
    required this.sqft,
    required this.bedrooms,
    required this.onTap,
    required this.UnitNumber,
    this.isExpiringSoon = false,
    this.unit_address_id = 0,
    this.unit_type = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: screenHeight2),
        decoration: BoxDecoration(
          color: AppColors.whiteLight,
          borderRadius: BorderRadius.circular(screenWidth4),
          boxShadow: [
            BoxShadow(
              color: AppColors.lightGrey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Container(
              margin: EdgeInsets.only(top: 8, left: 8, right: 8),
              height: screenHeight * 0.20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(screenWidth4),
                image: DecorationImage(
                  image: NetworkImage(
                    imageUrl.isNotEmpty
                        ? imageUrl
                        : 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Content Section
            Padding(
              padding: EdgeInsets.all(screenWidth4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CustomTextWidget(
                          title: title,
                          fontSize: H18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      CustomTextWidget(
                        title: price,
                        fontSize: H18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryColor,
                      ),
                    ],
                  ),
                  kHeight(0.005),

                  // Location and Unit Number Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CustomTextWidget(
                          title: location,
                          fontSize: detailContentTitle,
                          color: AppColors.darkGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (UnitNumber.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primaryColor,
                              width: 1,
                            ),
                          ),
                          child: CustomTextWidget(
                            title: 'Unit $UnitNumber',
                            fontSize: detailContentTitle,
                            color: AppColors.secondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  kHeight(0.01),

                  // Expiry Date with Warning
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppColors.primaryColor,
                        ),
                        child: CustomTextWidget(
                          title: expiryDate,
                          fontSize: detailContentTitle,
                          color: AppColors.secondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  kHeight(0.015),

                  // Property Details Row
                  Row(
                    children: [
                      // Square Feet
                      Row(
                        children: [
                          Icon(
                            Icons.crop_free,
                            size: smallIconSize,
                            color: AppColors.black,
                          ),
                          kWidth(0.01),
                          CustomTextWidget(
                            title: sqft,
                            fontSize: detailContentTitle,
                            color: AppColors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                      kWidth(0.06),

                      // Bedrooms
                      Row(
                        children: [
                          Icon(
                            Icons.bed_outlined,
                            size: smallIconSize,
                            color: AppColors.black,
                          ),
                          kWidth(0.01),
                          CustomTextWidget(
                            title: bedrooms,
                            fontSize: detailContentTitle,
                            color: AppColors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ],
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