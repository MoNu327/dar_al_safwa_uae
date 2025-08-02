import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/constants/custom_size.dart';
import '../../core/theme/app_colors.dart'; // Adjust the import path

class CustomSnackbar {
  static void show(
      {required String title,
      required String message,
      IconData? icon,
      Color? backgroundColor,
      Color? textColor,
      int? durationInSeconds,
      SnackPosition? snackPosition,
      bool isDismissible = true,
      DismissDirection dismissDirection = DismissDirection.horizontal,
      String? actionLabel,
      bool isPersistent = false,
      VoidCallback? onActionPressed,
      int? status}) {
    Get.snackbar(
      title,
      message,
      padding: EdgeInsets.symmetric(
          horizontal: screenHeight4, vertical: screenHeight2),
      snackPosition: snackPosition ??= SnackPosition.TOP,
      backgroundColor: status == 0
          ? AppColors.error
          : status == 1
              ? AppColors.warning
              : AppColors.whiteLight,
      colorText: AppColors.black,
      borderRadius: 12,
      duration: Duration(
          seconds:
              durationInSeconds ?? 2), // Auto-hide after X secs (default: 2)
      icon: Icon(
          title == "Success"
              ? HugeIcons.strokeRoundedTick03
              : status == 0
                  ? HugeIcons.strokeRoundedAlert01
                  : HugeIcons.strokeRoundedInformationCircle,
          color: AppColors.black,
          size: screenHeight4),
      shouldIconPulse: true,
      forwardAnimationCurve: Curves.easeOutBack,
      isDismissible: isDismissible,
      dismissDirection: dismissDirection,
      borderWidth: .3,
      borderColor:AppColors.black.withValues(alpha: .8),
    );
  }
}
