import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_text_widget.dart';

enum DocumentStatus {
  signed,
  notSigned,
  expired,
  verified,
}

class TenantsDocumentsWidget extends StatelessWidget {
  const TenantsDocumentsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back,
            size: iconSize,
            color: AppColors.black,
          ),
        ),
        title: CustomTextWidget(
          title: 'My Documents',
          fontSize: appBarTitles,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      ),
      body: Column(
        children: [
          // Divider line
          Container(
            height: 1,
            color: AppColors.lightGrey2,
            margin: EdgeInsets.symmetric(horizontal: screenWidth4),
          ),
          kHeight(0.03),

          // Documents List
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: screenWidth4),
              children: [
                DocumentCard(
                  title: 'Property Ownership Certificate',
                  status: DocumentStatus.signed,
                  expiryDate: 'Expires on June 12, 2026',
                  onViewPressed: () {},
                ),
                kHeight(0.025),
                DocumentCard(
                  title: 'Land Tax Receipt',
                  status: DocumentStatus.notSigned,
                  expiryDate: 'Expires on May 24, 2025',
                  onViewPressed: () {},
                ),
                kHeight(0.025),
                DocumentCard(
                  title: 'Utility Bill (Electricity)',
                  status: DocumentStatus.verified,
                  expiryDate: 'Expires on April 10, 2025',
                  onViewPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(screenWidth3),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightGrey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Document Icon
          Container(
            width: screenWidth * 0.12,
            height: screenWidth * 0.12,
            decoration: BoxDecoration(
              color: AppColors.lightGrey2,
              borderRadius: BorderRadius.circular(screenWidth2),
            ),
            child: Icon(
              Icons.description_outlined,
              size: iconSize,
              color: AppColors.black500,
            ),
          ),
          kWidth(0.04),

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
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth2,
                    vertical: screenHeight05,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusBackgroundColor(),
                    borderRadius: BorderRadius.circular(screenWidth1),
                  ),
                  child: CustomTextWidget(
                    title: _getStatusText(),
                    fontSize: expandedContentTitle,
                    fontWeight: FontWeight.w500,
                    color: _getStatusTextColor(),
                  ),
                ),
                kHeight(0.008),

                // Expiry Date
                CustomTextWidget(
                  title: expiryDate,
                  fontSize: detailContentTitle,
                  color: AppColors.black500,
                ),
              ],
            ),
          ),

          // View Button
          InkWell(
            onTap: onViewPressed,
            borderRadius: BorderRadius.circular(screenWidth2),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth4,
                vertical: screenHeight1,
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
    );
  }

  Color _getStatusBackgroundColor() {
    switch (status) {
      case DocumentStatus.signed:
        return AppColors.onlineGreen.withOpacity(0.1);
      case DocumentStatus.notSigned:
        return AppColors.redColor.withOpacity(0.1);
      case DocumentStatus.expired:
        return AppColors.warning.withOpacity(0.1);
      case DocumentStatus.verified:
        return AppColors.onlineGreen.withOpacity(0.1);
    }
  }

  Color _getStatusTextColor() {
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
