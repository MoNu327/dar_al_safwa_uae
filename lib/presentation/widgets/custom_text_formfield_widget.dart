import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/custom_size.dart';
import '../../core/theme/app_colors.dart';
import 'custom_text_widget.dart';

class CustomTextFieldWidget extends StatelessWidget {
  final String hintText;
  final String labelText;
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
    required this.labelText,
    required this.keyboardType,
    required this.controller,
    this.readOnly = false,
    this.suffixIconOnTap,
    this.inputFormatters,
    this.obscureText = false,
    this.suffixIcon = false,
    this.validator,
    this.onChanged,
    this.labelTextColor, // Initialize onChanged
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextWidget(
            title: labelText,
            color: labelTextColor ?? AppColors.black,
            fontSize: popularPlaceTitle,
            fontWeight: FontWeight.w500,
          ),
          SizedBox(height: screenHeight05),
          TextFormField(
            readOnly: readOnly,
            inputFormatters: inputFormatters,
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            obscureText: obscureText,
            onChanged: onChanged, // Pass onChanged to TextFormField
            decoration: InputDecoration(
              fillColor: AppColors.white,
              filled: true,
              hintText: hintText,
              hintStyle: GoogleFonts.poppins(
                color: AppColors.lightGrey,
                fontSize: popularPlaceTitle,
              ),
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
                borderSide: const BorderSide(
                  color: AppColors.black500,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.black500,
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
