import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextWidget extends StatelessWidget {
  const CustomTextWidget({
    super.key,
    this.title,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textAlign,
    this.fontStyle,
    this.strikethrough = false,
    this.underline = false,
  });
  final String? title;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextAlign? textAlign;
  final FontStyle? fontStyle;
  final bool strikethrough;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    // Use GetX utilities to get screen size
    final screenWidth = Get.width;
    final screenHeight = Get.height;

    // Check if the device is mobile based on screen width
    final isMobile = screenWidth > 600; // Typical mobile screen width is < 600

    // Detect landscape mode based on height and width ratio
    final isLandscape =
        screenWidth > screenHeight; // Detect landscape using Get.isLandscape

    // Dynamically calculate font size based on screen size and orientation
    double calculatedFontSize = fontSize ?? screenHeight * 0.018;

    if (isMobile && isLandscape) {
// In landscape mode, increase font size for mobile
      calculatedFontSize *= 2;
    }
    // Combine decorations if both strikethrough and underline are true
    TextDecoration combinedDecoration = TextDecoration.none;
    if (strikethrough && underline) {
      combinedDecoration = TextDecoration.combine([
        TextDecoration.lineThrough,
        TextDecoration.underline,
      ]);
    } else if (strikethrough) {
      combinedDecoration = TextDecoration.lineThrough;
    } else if (underline) {
      combinedDecoration = TextDecoration.underline;
    }
    return Text(
      title ?? "",
      style: GoogleFonts.lato(
        color: color ?? AppColors.black,
        fontSize: calculatedFontSize,
        fontWeight: fontWeight ?? FontWeight.w500,
        fontStyle: fontStyle ?? FontStyle.normal,
        decoration: combinedDecoration, // No decoration if false
        decorationColor: color ?? AppColors.black, // Color of the strikethrough
        decorationThickness: 2, // Thickness of the strikethrough line
      ),
      maxLines: maxLines, // Allows text to wrap onto multiple lines
      overflow: overflow ??
          TextOverflow.ellipsis, // Ensure long text doesn't overflow
      softWrap: softWrap ?? false, // Enables wrapping of long text
      textAlign: textAlign ?? TextAlign.start,

      // overflow: TextOverflow.ellipsis,
      // maxLines: 1,
    );
  }
}

class CustomRichTextWidget extends StatelessWidget {
  const CustomRichTextWidget({
    super.key,
    this.title,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.subTitle,
    this.subTextColor,
    this.fontWeight2, // Adding condition parameter
  });

  final String? title;
  final String? subTitle;
  final double? fontSize;
  final FontWeight? fontWeight;
  final FontWeight? fontWeight2;
  final Color? color;
  final Color? subTextColor;

  @override
  Widget build(BuildContext context) {
    final screenWidth = Get.width;
    final screenHeight = Get.height;

    // Check if the device is mobile based on screen width
    final isMobile = screenWidth > 600; // Typical mobile screen width is < 600

    // Detect landscape mode based on height and width ratio
    final isLandscape =
        screenWidth > screenHeight; // Detect landscape using Get.isLandscape

    // Dynamically calculate font size based on screen size and orientation
    double calculatedFontSize = fontSize ?? screenHeight * 0.018;

    if (isMobile && isLandscape) {
      // In landscape mode, increase font size for mobile
      calculatedFontSize *= 2;
    }
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: title ?? "",
            style: GoogleFonts.lato(
              color: color ?? AppColors.black,
              fontSize: calculatedFontSize,
              fontWeight: fontWeight ?? FontWeight.normal,
            ),
          ),
          TextSpan(
            text: subTitle ?? '', // Red asterisk
            style: GoogleFonts.poppins(
              color:
                  subTextColor ?? AppColors.black, // Red color for the asterisk
              fontSize: calculatedFontSize,
              fontWeight: fontWeight2 ?? FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
