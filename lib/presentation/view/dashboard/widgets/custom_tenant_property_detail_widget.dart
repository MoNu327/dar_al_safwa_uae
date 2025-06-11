import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/controller/tenant_property_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_appbar_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'view_agreement_screen.dart';

class CustomTenantPropertyDetailWidget extends StatelessWidget {
  final int propertyId;
  // Placeholder for property name
  final TenantPropertyController tenantPropertyController = Get.find();

  CustomTenantPropertyDetailWidget({
    super.key,
    required this.propertyId,
  });

  Map<String, dynamic> get property {
    return tenantPropertyController.tenantProperties.firstWhere(
      (property) => property['id'] == propertyId,
      orElse: () => <String, dynamic>{},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (property.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Property Not Found'),
        ),
        body: const Center(
          child: Text('Property details not available'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBarWidget(
        title: property['propertyName'],
        titleFontSize: screenHeight2,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: Get.width * 0.04,
          vertical: Get.height * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            _buildPropertyImage(),
            kHeight(0.03),

            // Property Status Badge
            _buildStatusBadge(),
            kHeight(0.02),

            // Property Details Section
            _buildSectionTitle('Property Details'),
            kHeight(0.015),
            _buildDetailRow(Icons.home_work_outlined, 'Property Name',
                property['propertyName']),
            _buildDetailRow(
                Icons.location_on_outlined, 'Location', property['location']),
            _buildDetailRow(
                Icons.aspect_ratio_outlined, 'Area', property['area']),
            kHeight(0.02),

            // Ownership Details Section
            _buildSectionTitle(property['status'] == 'Rent'
                ? 'Rental Details'
                : 'Ownership Details'),
            kHeight(0.015),
            _buildDetailRow(
                Icons.calendar_today_outlined,
                property['status'] == 'Rent'
                    ? 'Agreement Expiry'
                    : 'Purchased Date',
                property[property['status'] == 'Rent'
                    ? 'agreementExpiry'
                    : 'purchasedDate']),
            _buildDetailRow(
                Icons.attach_money_outlined,
                property['status'] == 'Rent'
                    ? 'Security Amount'
                    : 'Purchased Amount',
                property[property['status'] == 'Rent'
                    ? 'securityAmount'
                    : 'purchasedAmount']),
            kHeight(0.02),

            // Agent Details Section
            _buildSectionTitle('Agent Details'),
            kHeight(0.015),
            _buildDetailRow(
                Icons.business_outlined, 'Agent Name', property['agentName']),
            kHeight(0.1), // Extra space for buttons
          ],
        ),
      ),
      bottomSheet: _buildActionButtons(),
    );
  }

  // Reusable Widget: Property Image
  Widget _buildPropertyImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.asset(
        property['imageUrl'],
        width: double.infinity,
        height: Get.height * 0.25,
        fit: BoxFit.cover,
      ),
    );
  }

  // Reusable Widget: Status Badge
  Widget _buildStatusBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Get.width * 0.04,
        vertical: Get.height * 0.01,
      ),
      decoration: BoxDecoration(
        color: property['status'] == "Rent"
            ? AppColors.secondaryColorLight.withOpacity(0.2)
            : Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomTextWidget(
        title: property['status'],
        fontSize: Get.height * 0.016,
        fontWeight: FontWeight.w600,
        color: property['status'] == "Rent"
            ? AppColors.secondaryColorLight
            : Colors.green,
      ),
    );
  }

  // Reusable Widget: Section Title
  Widget _buildSectionTitle(String title) {
    return CustomTextWidget(
      title: title,
      fontSize: Get.height * 0.02,
      fontWeight: FontWeight.bold,
      color: AppColors.secondaryColor,
    );
  }

  // Reusable Widget: Detail Row
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Get.height * 0.01),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.black600,
            size: Get.height * 0.022,
          ),
          kWidth(0.02),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextWidget(
                  title: label,
                  fontSize: Get.height * 0.015,
                  color: AppColors.black600,
                ),
                kHeight(0.005),
                CustomTextWidget(
                  title: value,
                  fontSize: Get.height * 0.018,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black800,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Reusable Widget: Action Buttons
  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Get.width * 0.04,
        vertical: Get.height * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: .2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'View Agreement',
              AppColors.onlineGreen,
              Icons.description_outlined,
              onPressed: () {
                Get.to(PdfViewerScreen());
              },
            ),
          ),
          kWidth(0.03),
          Expanded(
            child: _buildActionButton(
              'Register Complaint',
              Colors.red,
              Icons.report_problem_outlined,
              onPressed: () {
                tenantPropertyController
                    .navigateToComplaintReg(property['propertyName']);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Reusable Widget: Single Action Button
  Widget _buildActionButton(
    String text,
    Color color,
    IconData icon, {
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withValues(alpha: .3), width: 1),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: Get.width * 0.02,
          vertical: Get.height * 0.015,
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: Get.height * 0.02,
            color: AppColors.white,
          ),
          kWidth(0.01),
          Flexible(
            child: CustomTextWidget(
              title: text,
              fontSize: Get.height * 0.016,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
