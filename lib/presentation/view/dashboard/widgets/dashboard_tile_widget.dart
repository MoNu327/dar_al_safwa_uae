import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

Widget buildMenuTile({
  required Widget leading,
  required String title,
  required VoidCallback onTap,
}) {
  return Container(
    margin: EdgeInsets.symmetric(
      // horizontal: screenWidth5,
      vertical: screenHeight1,
    ),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth5,
            vertical: screenHeight2,
          ),
          child: Row(
            children: [
              Container(
                  width: iconSize * 1.2,
                  height: iconSize * 1.2,
                  // decoration: BoxDecoration(
                  //   color: AppColors.secondaryColor.withOpacity(0.1),
                  //   borderRadius: BorderRadius.circular(8),
                  // ),
                  child: leading

                  // Icon(
                  //   icon,
                  //   color: AppColors.secondaryColor,
                  //   size: iconSize * 0.8,
                  // ),
                  ),
              kWidth(0.04),
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
                Icons.arrow_forward_ios,
                color: AppColors.black600,
                size: smallIconSize,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
