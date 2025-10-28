import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/presentation/widgets/common_expires_widget.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/material.dart';

// Add this enum definition at the top of your file or in a separate file
enum DocumentStatus {
  signed,
  notSigned,
  expired,
  verified,
  pending,
  rejected,
  adminApproved, // New status for admin approved documents
}

enum DocumentType {
  booking,
  payment,
}

// Helper class to handle different document types
class DocumentItem {
  final dynamic document;
  final DocumentType type;
  final String baseUrl;
  final String? propertyId;
  final String? unitId;

  DocumentItem({
    required this.document,
    required this.type,
    required this.baseUrl,
    this.propertyId,
    this.unitId,
  });
}

class DocumentCard extends StatelessWidget {
  final DocumentItem documentItem;
  final VoidCallback onViewPressed;

  const DocumentCard({
    Key? key,
    required this.documentItem,
    required this.onViewPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final document = documentItem.document;
    final status = _getDocumentStatus(document.verificationStatusCode, document.isExpired);
    final expiryDate = document.expiryDate.isNotEmpty 
        ? 'Expires on ${_formatDate(document.expiryDate)}'
        : 'No expiry date';

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
                  title: document.title,
                  fontSize: H18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                kHeight(0.005),

                // Document Type
                CustomTextWidget(
                  title: _getDocumentTypeText(documentItem.type),
                  fontSize: tagTitle,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkGrey,
                ),
                kHeight(0.005),

                // Status Badge
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth2,
                        vertical: screenHeight05,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusBackgroundColor(status),
                        borderRadius: BorderRadius.circular(screenWidth2),
                      ),
                      child: CustomTextWidget(
                        title: _getStatusText(status),
                        fontSize: expandedContentTitle,
                        fontWeight: FontWeight.w500,
                        color: _getStatusTextColor(status),
                      ),
                    ),
                  ],
                ),
                kHeight(0.010),
                
                // Expiry Date
                if (document.expiryDate.isNotEmpty)
                  commonExpiresWidget(expiryDate, () {}),
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
                ),
                child: Icon(
                  Icons.description,
                  size: iconSize,
                  color: AppColors.darkGrey,
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

  DocumentStatus _getDocumentStatus(String statusCode, bool isExpired) {
    if (isExpired) return DocumentStatus.expired;
    
    // Handle numeric status codes
    switch (statusCode) {
      case '0':
        return DocumentStatus.pending; // Not Verified/Pending Review
      case '1':
        return DocumentStatus.verified; // Verified/Approved by Admin
      case '2':
        return DocumentStatus.adminApproved; // Admin Approved All - Show as Verified
      case '3':
        return DocumentStatus.rejected;
      default:
        // Handle string status codes
        switch (statusCode.toLowerCase()) {
          case 'verified':
          case 'approved':
          case 'adminapproved':
          case 'admin_approved':
          case '1':
          case '2':
            return DocumentStatus.verified;
          case 'signed':
            return DocumentStatus.signed;
          case 'rejected':
          case '3':
            return DocumentStatus.rejected;
          case 'pending':
          case 'unknown':
          case '0':
          default:
            return DocumentStatus.pending;
        }
    }
  }

  String _getDocumentTypeText(DocumentType type) {
    switch (type) {
      case DocumentType.booking:
        return 'Booking Document';
      case DocumentType.payment:
        return 'Payment Document';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusBackgroundColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.signed:
        return AppColors.blueColor;
      case DocumentStatus.pending:
        return AppColors.redColor;
      case DocumentStatus.expired:
        return AppColors.warning;
      case DocumentStatus.verified:
      case DocumentStatus.adminApproved: // Admin approved shows green
        return AppColors.onlineGreen;
      case DocumentStatus.rejected:
        return AppColors.redColor;
      case DocumentStatus.notSigned:
        return AppColors.warning;
    }
  }

  Color _getStatusTextColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.signed:
      case DocumentStatus.pending:
      case DocumentStatus.verified:
      case DocumentStatus.adminApproved: // Admin approved shows white text
      case DocumentStatus.rejected:
        return AppColors.white;
      case DocumentStatus.expired:
      case DocumentStatus.notSigned:
        return AppColors.secondaryColor;
    }
  }

  String _getStatusText(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.signed:
        return 'Signed';
      case DocumentStatus.pending:
        return 'Not Verified';
      case DocumentStatus.expired:
        return 'Expired';
      case DocumentStatus.verified:
      case DocumentStatus.adminApproved: // Admin approved shows as "Verified"
        return 'Verified';
      case DocumentStatus.rejected:
        return 'Rejected';
      case DocumentStatus.notSigned:
        return 'Not Signed';
    }
  }
}