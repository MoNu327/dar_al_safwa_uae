import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/custom_size.dart';
import '../../core/theme/app_colors.dart';
import 'custom_text_widget.dart';

class CustomTextFieldWidget extends StatelessWidget {
  final String hintText;
  final String? labelText;
  final int? maxLines;

  final IconData? prefixIcon;
  final bool? isBoldTextNeeded;
  final bool? isBorderNeeded;

  final TextInputType keyboardType;
  final TextEditingController controller;
  final Function()? suffixIconOnTap;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool suffixIcon;
  final bool readOnly;
  final String? Function(String?)? validator;
  final Function(String)? onChanged; // Add onChanged callback
  final Color? labelTextColor;

  const CustomTextFieldWidget({
    super.key,
    required this.hintText,
    this.labelText,
    this.isBorderNeeded = false,
    required this.keyboardType,
    required this.controller,
    this.readOnly = false,
    this.suffixIconOnTap,
    this.inputFormatters,
    this.obscureText = false,
    this.suffixIcon = false,
    this.prefixIcon,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.isBoldTextNeeded = false,
    this.labelTextColor, // Initialize onChanged
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labelText != null)
            CustomTextWidget(
              title: "$labelText*",
              color: labelTextColor ?? AppColors.black,
              fontSize: tagTitle,
              fontWeight: FontWeight.w500,
            ),
          SizedBox(height: screenHeight05),
          TextFormField(
            maxLines: maxLines,
            style: GoogleFonts.poppins(
                color: AppColors.black,
                fontSize: tagTitle,
                fontWeight:
                    isBoldTextNeeded! ? FontWeight.w600 : FontWeight.w500),

            readOnly: readOnly,
            inputFormatters: inputFormatters,
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            obscureText: obscureText,
            onChanged: onChanged, // Pass onChanged to TextFormField
            decoration: InputDecoration(
              prefixIcon:
                  prefixIcon != null ? Icon(prefixIcon) : SizedBox.shrink(),
              fillColor: AppColors.whiteLight,
              filled: true,
              hintText: hintText,
              hintStyle: GoogleFonts.poppins(
                  color: AppColors.darkGrey,
                  fontSize: screenHeight * 0.015,
                  fontWeight: FontWeight.w500),
              suffixIcon: suffixIcon
                  ? InkWell(
                      onTap: suffixIconOnTap,
                      child: obscureText
                          ? const Icon(Icons.visibility_off)
                          : const Icon(Icons.visibility_rounded),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isBorderNeeded!
                      ? AppColors.grey.withValues(alpha: 0.1)
                      : AppColors.white,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isBorderNeeded!
                      ? AppColors.grey.withValues(alpha: 0.3)
                      : AppColors.white,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryColor,
                  width: 1.0,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.redColor,
                  width: 1.0,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.redColor,
                  width: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
