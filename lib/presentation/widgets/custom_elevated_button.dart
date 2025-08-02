import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../core/constants/custom_size.dart';
import '../../core/theme/app_colors.dart';

class CustomButtonWidget extends StatelessWidget {
  const CustomButtonWidget({
    super.key,
    required this.buttonTitle,
    this.buttonColor,
    this.buttonHeight,
    this.buttonWidth,
    this.buttonTextColor,
    this.onPressed,
    this.fontWeight,
    this.fontSize,
    this.childWidgetLoader = false,
    this.buttonShape,
    this.borderColor, 
  });
  final String buttonTitle;
  final Color? buttonColor;
  final Color? buttonTextColor;
  final Color? borderColor;
  final double? buttonHeight;
  final double? buttonWidth;
  final VoidCallback? onPressed;
  final FontWeight? fontWeight;
  final double? fontSize;
  final String? buttonShape;

  final bool childWidgetLoader;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: buttonHeight ?? screenHeight5,
      width: buttonWidth ?? double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          shape: buttonShape == "rect"
              ? WidgetStatePropertyAll<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    side: BorderSide(
                        color: borderColor ?? Colors.transparent, width: .5),
                    borderRadius: BorderRadius.circular(
                        12), // Adjust the radius as needed
                  ),
                )
              : null,
          backgroundColor: WidgetStateProperty.all<Color>(
              buttonColor ?? AppColors.secondaryColor),
        ),
        child: childWidgetLoader
            ? Padding(
                padding: EdgeInsets.all(screenHeight1),
                child: Center(
                  child: LoadingAnimationWidget.threeRotatingDots(
                    size: 20,
                    color: buttonTextColor ?? AppColors.primaryColor,
                  ),
                ),
              )
            : CustomTextWidget(
                title: buttonTitle,
                fontSize: fontSize ?? popularPlaceTitle,
                fontWeight: FontWeight.w600,
                color: buttonTextColor ?? AppColors.white,
              ),
      ),
    );
  }
}
