import 'package:firebase_auth/firebase_auth.dart';
import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/data/model/tenatpropertymodel.dart';
import 'package:majan/presentation/view/dashboard/controller/tenant_property_controller.dart';
import 'package:majan/presentation/view/dashboard/widgets/tenants_create_ticket_screen.dart';
import 'package:majan/presentation/widgets/custom_appbar_widget.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'view_agreement_screen.dart';

class CustomTenantPropertyDetailWidget extends StatelessWidget {
  final int propertyId;
  final TenantPropertyController tenantPropertyController = Get.find();

  CustomTenantPropertyDetailWidget({
    super.key,
    required this.propertyId,
    required String cityName,
  });

  /// Fetch current user ID from FirebaseAuth
  String getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (tenantPropertyController.isLoading.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (tenantPropertyController.errorMessage.isNotEmpty) {
        return Scaffold(
          body: Center(
            child: Text(tenantPropertyController.errorMessage.value),
          ),
        );
      }
       
      /// Find property by ID
      final property = tenantPropertyController.properties
          .firstWhereOrNull((p) => p.id == propertyId);

      if (property == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Property Not Found')),
          body: const Center(child: Text('Property details not available')),
        );
      }

      /// Build UI using property details from API
      return Scaffold(
        appBar: CustomAppBarWidget(title: property.propertyTitle),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: Get.width * 0.04,
            vertical: Get.height * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPropertyImage(property.propertyImageUrl),
              kHeight(0.03),
              _buildStatusBadge(property.expiryStatus),
              kHeight(0.02),

              /// Property Details
              _buildSectionTitle('Property Details'),
              kHeight(0.02),
              _buildDetailRow(Icons.home_work_outlined, 'Property Name',
                  property.propertyTitle),
              _buildDetailRow(Icons.location_on_outlined, 'Location',
                  '${property.cityName}, ${property.stateName}'),
              _buildDetailRow(Icons.aspect_ratio_outlined, 'Area',
                  property.unitAreaFormatted),

              /// Unit Details
              kHeight(0.02),
              _buildSectionTitle('Unit Details'),
              kHeight(0.02),
              _buildDetailRow(Icons.home, 'Unit Type', property.unitTypeName),
              _buildDetailRow(Icons.home, 'Unit Number', property.unitNumber),

              /// Rental Details
              kHeight(0.02),
              _buildSectionTitle('Rental Details'),
              kHeight(0.02),
              _buildDetailRow(Icons.calendar_today_outlined, 'Start Date',
                  property.startDateFormatted),
              _buildDetailRow(Icons.calendar_today_outlined, 'End Date',
                  property.endDateFormatted),
              _buildDetailRow(
                  Icons.attach_money_outlined, 'Rent Amount', property.rentAmount),
                  _buildActionButtons(property),

              // kHeight(0.1),
            ],
          ),
        ),
       

      );
    });
  }

  /// Property Image Widget
  Widget _buildPropertyImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: Get.height * 0.25,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Container(color: Colors.grey[300], child: const Icon(Icons.image)),
      ),
    );
  }

  /// Status Badge Widget
  Widget _buildStatusBadge(String status) {
    bool isExpiring = status.toLowerCase().contains('expires');
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: Get.width * 0.04, vertical: Get.height * 0.01),
      decoration: BoxDecoration(
        color: isExpiring
            ? AppColors.secondaryColorLight.withOpacity(0.2)
            : Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomTextWidget(
        title: status,
        fontSize: Get.height * 0.016,
        fontWeight: FontWeight.w600,
        color: isExpiring ? AppColors.secondaryColorLight : Colors.green,
      ),
    );
  }

  /// Section Title
  Widget _buildSectionTitle(String title) {
    return CustomTextWidget(
      title: title,
      fontSize: Get.height * 0.02,
      fontWeight: FontWeight.bold,
      color: AppColors.secondaryColor,
    );
  }

  /// Detail Row
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Get.height * 0.01),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.black600, size: Get.height * 0.022),
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

  /// Bottom Action Buttons
// Widget _buildActionButtons(TenantPropertyModel property) {
//   return SafeArea(
//     child: Container(
//       padding: EdgeInsets.symmetric(
//           horizontal: Get.width * 0.04, vertical: Get.height * 0.02),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(.2),
//             spreadRadius: 2,
//             blurRadius: 5,
//             offset: const Offset(0, -2),
//           )
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: _buildActionButton(
//               'View Agreement',
//               AppColors.onlineGreen,
//               Icons.description_outlined,
//               onPressed: () {
//                 Get.to(() => PdfViewerScreen());
//               },
//             ),
//           ),
//           kWidth(0.03),
//           Expanded(
//             child: _buildActionButton(
//               'Register Complaint',
//               Colors.red,
//               Icons.report_problem_outlined,
//               onPressed: () {
//                 final userId = getCurrentUserId();
//                 Get.to(() => TenantsCreateTicketScreen(
//                       propertyName: property.propertyTitle,
//                       propertyId: property.propertyId,
//                       unitAddressId: property.unitAddressId,
//                       userId: userId, // Pass userId here
//                     ));
//               },
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// /// Action Button Widget
// Widget _buildActionButton(
//   String text,
//   Color color,
//   IconData icon, {
//   required VoidCallback onPressed,
// }) {
//   return ElevatedButton(
//     style: ElevatedButton.styleFrom(
//       backgroundColor: color,
//       shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//           side: BorderSide(color: color.withOpacity(.3), width: 1)),
//       padding: EdgeInsets.symmetric(
//           horizontal: Get.width * 0.02, vertical: Get.height * 0.015),
//     ),
//     onPressed: onPressed,
//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(icon, size: Get.height * 0.02, color: AppColors.white),
//         kWidth(0.01),
//         Flexible(
//           child: CustomTextWidget(
//             title: text,
//             fontSize: Get.height * 0.016,
//             fontWeight: FontWeight.w600,
//             color: AppColors.white,
//           ),
//         ),
//       ],
//     ),
//   );
// }
// }
Widget _buildActionButtons(TenantPropertyModel property) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: Get.width * 0.04, 
      vertical: Get.height * 0.02,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(.2),
          spreadRadius: 2,
          blurRadius: 5,
          offset: const Offset(0, -2),
        )
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
              Get.to(() => PdfViewerScreen());
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
              final userId = getCurrentUserId();
              Get.to(() => TenantsCreateTicketScreen(
                propertyName: property.propertyTitle,
                propertyId: property.propertyId,
                unitAddressId: property.unitAddressId,
                userId: userId,
              ));
            },
          ),
        ),
      ],
    ),
  );
}

/// Action Button Widget (unchanged)
Widget _buildActionButton(
  String text,
  Color color,
  IconData icon, {
  required VoidCallback onPressed,
}) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(.3), width: 1),
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
        Icon(icon, size: Get.height * 0.02, color: AppColors.white),
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