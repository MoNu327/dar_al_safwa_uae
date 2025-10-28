
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';

class CustomAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final Color backButtonColor;
  final Color backButtonBackgroundColor;
  final Color titleColor;
  final double titleFontSize;
  final FontWeight titleFontWeight;
  final double elevation;
  final bool centerTitle;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const CustomAppBarWidget({
    super.key,
    required this.title,
    this.backgroundColor = AppColors.primaryColor,
    this.backButtonColor = AppColors.secondaryColor,
    this.backButtonBackgroundColor = AppColors.white,
    this.titleColor = AppColors.secondaryColor,
    this.titleFontSize = 0.02,
    this.titleFontWeight = FontWeight.bold,
    this.elevation = 1.0,
    this.centerTitle = false,
    this.actions,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => Size.fromHeight(Get.height * 0.07);

  @override
  Widget build(BuildContext context) {
    final double responsiveFontSize =
        titleFontSize <= 1.0 ? Get.height * titleFontSize : titleFontSize;

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: elevation,
      automaticallyImplyLeading: false,
      centerTitle: centerTitle,
      titleSpacing: 0,
      title: Align(
        alignment: centerTitle ? Alignment.center : Alignment.centerLeft,
        child: CustomTextWidget(
          title: title,
          color: titleColor,
          fontSize: responsiveFontSize,
          fontWeight: titleFontWeight,
        ),
      ),
      leading: buildBackButton(context),
      actions: actions,
    );
  }

  Widget buildBackButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: screenHeight1,
        horizontal: screenWidth3,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onBackPressed ?? () => Get.back(),
        child: Container(
          decoration: BoxDecoration(
              color: backButtonBackgroundColor, shape: BoxShape.circle),
          padding: EdgeInsets.symmetric(
              vertical: screenHeight05, horizontal: screenWidth1),
          child: Icon(
            Icons.arrow_back,
            color: backButtonColor,
            size: screenHeight2,
          ),
        ),
      ),
    );
  }
}
