import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../../widgets/custom_text_widget.dart';

Widget buildPropertyCard({
  required String imageUrl,
  required String title,
  required String location,
  required String status,
  required Color statusColor,
  required String listedDate,
  required String price,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: () {
      onTap();
    },
    child: Container(
      margin: EdgeInsets.only(bottom: screenHeight2),
      decoration: BoxDecoration(
        color: AppColors.whiteLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Row(
          children: [
            // Property Image
            Container(
              width: screenWidth * 0.25,
              height: screenHeight * 0.12,
              decoration: BoxDecoration(
                color: AppColors.secondaryColor.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Property Details
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(screenWidth3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: CustomTextWidget(
                          title: title,
                          fontSize: H18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        )),
                        Icon(
                          Icons.more_vert,
                          color: AppColors.black,
                          size: iconSize * 0.8,
                        ),
                      ],
                    ),
                    kHeight(0.001),
                    CustomTextWidget(
                      title: location,
                      fontSize: tagTitle,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                    kHeight(0.01),
                    Row(
                      children: [
                        CustomTextWidget(
                          title: 'Status: ',
                          fontSize: tagTitle,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black800,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth2,
                            vertical: screenHeight05,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CustomTextWidget(
                            title: status,
                            fontSize: tagTitle * 0.9,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    // kHeight(0.01),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomTextWidget(
                          title: listedDate,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                        Container(
                            padding: EdgeInsets.all(screenWidth3),
                            child: CustomTextWidget(
                              title: price,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Price
          ],
        ),
      ),
    ),
  );
}
