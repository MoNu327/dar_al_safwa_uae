import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_text_widget.dart';

class CustomStackBoxWidget extends StatelessWidget {
  const CustomStackBoxWidget({
    super.key,
    required this.title,
  });
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: Get.height * 0.018,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: FittedBox(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.002,
            horizontal: screenWidth2,
          ),
          child: CustomTextWidget(
            title: title,
            color: AppColors.black,
            fontSize: Get.height * 0.01,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
