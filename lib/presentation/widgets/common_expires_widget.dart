import 'package:flutter/material.dart';
import 'package:majan/core/theme/app_colors.dart';

import '../../core/constants/custom_size.dart';
import 'custom_text_widget.dart';

Widget commonExpiresWidget(String data, VoidCallback? onTap) {
  return InkWell(
    onTap: () => onTap,
    child: Container(
        width: screenWidth * 0.4,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth1,
          vertical: screenHeight1,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: CustomTextWidget(
            title: data,
            color: AppColors.secondaryColor,
            fontSize: tagTitle,
            fontWeight: FontWeight.w600,
          ),
        )),
  );
}
