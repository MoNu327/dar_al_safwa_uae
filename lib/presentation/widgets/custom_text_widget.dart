import 'package:majan/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/core.dart';



class CustomTextWidget extends StatelessWidget {
  const CustomTextWidget({
    super.key,
    this.title,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.maxLines = 1,  // Default to single line
    this.overflow = TextOverflow.ellipsis,  // Default to ellipsis
    this.softWrap = false,  // Disable softWrap by default
    this.textAlign,
    this.fontStyle,
    this.strikethrough = false,
    this.underline = false,
    this.lineHeight,
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
  final double? lineHeight;

  @override
  Widget build(BuildContext context) {
    final screenHeight = Get.height;
    final calculatedFontSize = fontSize ?? screenHeight * 0.018;

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
      capitalizeFirstLetter(title ?? ""),
      style: GoogleFonts.lato(
        color: color ?? AppColors.black,
        fontSize: calculatedFontSize,
        fontWeight: fontWeight ?? FontWeight.w500,
        fontStyle: fontStyle ?? FontStyle.normal,
        decoration: combinedDecoration,
        decorationColor: color ?? AppColors.black,
        decorationThickness: 2,
        height: lineHeight,
      ),
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textAlign: textAlign ?? TextAlign.start,
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
    this.fontWeight2,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  final String? title;
  final String? subTitle;
  final double? fontSize;
  final FontWeight? fontWeight;
  final FontWeight? fontWeight2;
  final Color? color;
  final Color? subTextColor;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final screenWidth = Get.width;
    final screenHeight = Get.height;
    final isMobile = screenWidth > 600;
    final isLandscape = screenWidth > screenHeight;

    double calculatedFontSize = fontSize ?? screenHeight * 0.018;

    if (isMobile && isLandscape) {
      calculatedFontSize *= 1.5;
    }

    return RichText(
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
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
            text: subTitle ?? '',
            style: GoogleFonts.poppins(
              color: subTextColor ?? AppColors.black,
              fontSize: calculatedFontSize,
              fontWeight: fontWeight2 ?? FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}