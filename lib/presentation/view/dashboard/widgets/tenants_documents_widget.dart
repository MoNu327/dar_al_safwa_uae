import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_text_widget.dart';
import 'tenants_document_card.dart';

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
            color: AppColors.darkGrey.withValues(alpha: 0.3),
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
