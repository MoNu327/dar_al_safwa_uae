import 'dart:ui';

import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/presentation/view/dashboard/widgets/tenants_documents_widget.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/material.dart';

import '../../../widgets/common_expires_widget.dart';

class DocumentCard extends StatelessWidget {
  final String title;
  final DocumentStatus status;
  final String expiryDate;
  final VoidCallback onViewPressed;

  const DocumentCard({
    Key? key,
    required this.title,
    required this.status,
    required this.expiryDate,
    required this.onViewPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(screenWidth4),
      decoration: BoxDecoration(
          color: AppColors.whiteLight,
          borderRadius: BorderRadius.circular(screenWidth3),
          border: Border.all(width: 1, color: AppColors.lightGrey)),
      child: Row(
        children: [
          // Document Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                CustomTextWidget(
                  title: title,
                  fontSize: H18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                kHeight(0.005),

                // Status Badge
                Row(
                  children: [
                    CustomTextWidget(
                      title: "Signed",
                      fontSize: tagTitle,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                    kWidth(0.010),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth2,
                        vertical: screenHeight05,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusBackgroundColor(),
                        borderRadius: BorderRadius.circular(screenWidth2),
                      ),
                      child: CustomTextWidget(
                        title: _getStatusText(),
                        fontSize: expandedContentTitle,
                        fontWeight: FontWeight.w500,
                        color: _getStatusTextColor(),
                      ),
                    ),
                  ],
                ),
                kHeight(0.010),
                // Expiry Date
                commonExpiresWidget(expiryDate, () {})
              ],
            ),
          ),

          // View Button
          Column(
            children: [
              // Document Icon
              Container(
                width: screenWidth * 0.13,
                height: screenWidth * 0.13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.darkGrey.withValues(alpha: 0.2),
                  // borderRadius: BorderRadius.circular(screenWidth2),
                ),
                child: Icon(
                  Icons.file_copy,
                  size: iconSize,
                  color: AppColors.whiteLight,
                ),
              ),
              kHeight(0.01),
              InkWell(
                onTap: onViewPressed,
                borderRadius: BorderRadius.circular(screenWidth2),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth5,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blueColor,
                    borderRadius: BorderRadius.circular(screenWidth2),
                  ),
                  child: CustomTextWidget(
                    title: 'View',
                    fontSize: tagTitle,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusBackgroundColor() {
    switch (status) {
      case DocumentStatus.signed:
        return AppColors.onlineGreen;
      case DocumentStatus.notSigned:
        return AppColors.redColor;
      case DocumentStatus.expired:
        return AppColors.warning;
      case DocumentStatus.verified:
        return AppColors.onlineGreen;
    }
  }

  Color _getStatusTextColor() {
    switch (status) {
      case DocumentStatus.signed:
        return AppColors.white;
      case DocumentStatus.notSigned:
        return AppColors.white;
      case DocumentStatus.expired:
        return AppColors.secondaryColor;
      case DocumentStatus.verified:
        return AppColors.white;
    }
  }

  String _getStatusText() {
    switch (status) {
      case DocumentStatus.signed:
        return 'Signed';
      case DocumentStatus.notSigned:
        return 'Not Verified';
      case DocumentStatus.expired:
        return 'Expired';
      case DocumentStatus.verified:
        return 'Verified';
    }
  }
}

// Document Data Model
class DocumentData {
  final String title;
  final DocumentStatus status;
  final String expiryDate;

  DocumentData({
    required this.title,
    required this.status,
    required this.expiryDate,
  });
}

// Extension for easy status creation
extension DocumentStatusExtension on DocumentStatus {
  static DocumentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'signed':
        return DocumentStatus.signed;
      case 'not signed':
      case 'not verified':
        return DocumentStatus.notSigned;
      case 'expired':
        return DocumentStatus.expired;
      case 'verified':
        return DocumentStatus.verified;
      default:
        return DocumentStatus.notSigned;
    }
  }
}
