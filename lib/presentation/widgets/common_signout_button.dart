
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/presentation/view_model/login_controller.dart';

Widget commonSignOutButton(LoginController loginController) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: screenWidth5),
    width: screenWidth * 0.3,
    child: ElevatedButton(
      onPressed: () {
        loginController.logout();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondaryColor,
        foregroundColor: AppColors.white,
        padding: EdgeInsets.symmetric(vertical: screenHeight2),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 2,
            color: Colors.white,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 2,
      ),
      child: Text(
        'Sign Out',
        style: TextStyle(
          fontSize: H18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
