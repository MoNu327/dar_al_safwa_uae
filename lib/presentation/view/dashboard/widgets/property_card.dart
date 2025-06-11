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
}) {
  return Container(
    margin: EdgeInsets.only(bottom: screenHeight2),
    decoration: BoxDecoration(
      color: AppColors.lightGrey2,
      borderRadius: BorderRadius.circular(12),
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
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: H18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                      ),
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
                      Text(
                        'Status: ',
                        style: TextStyle(
                          fontSize: tagTitle,
                          color: AppColors.black600,
                        ),
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
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: tagTitle * 0.9,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
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
  );
}
