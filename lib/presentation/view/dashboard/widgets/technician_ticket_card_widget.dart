// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:dar_al_safwa/core/routes/app_route.dart';
// import 'package:dar_al_safwa/data/model/technican_ticket_view_model.dart';
// import 'package:dar_al_safwa/data/model/technician_complaints_response.dart';
// import 'package:dar_al_safwa/data/model/ticket_list_response_model.dart';
// import 'package:dar_al_safwa/domain/controller/technician_tickets_controller.dart';
// import 'package:dar_al_safwa/presentation/view/dashboard/widgets/tenants_ticket_details_screen.dart' show TicketDetailsScreen;
// import 'package:dar_al_safwa/presentation/view/dashboard/widgets/tenants_tickets_list_widget.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:get/get.dart';
// import 'package:hugeicons/hugeicons.dart';
// import 'package:intl/intl.dart';

// import '../../../../core/constants/custom_size.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../widgets/custom_elevated_button.dart';
// import '../../../widgets/custom_text_widget.dart';
// import 'technician_rectify_ticket_screen.dart';

// Widget buildTicketCard({
//   required String propertyName,
//   required String category,
//   required String issue,
//   required String status,
//   required Color statusColor,
//   required String description,
//   required String date,
//   required String time,
//   required IconData categoryIcon,
//   ComplaintImages? images,
//   required String complaintId,
//   Complaint? complaint,
// }) {
//   // Enhanced date parsing with error handling
//   DateTime? dateTime;
//   String formattedDate = '';
//   String formattedTime = '';
  
//   try {
//     dateTime = DateFormat('MMM dd, yyyy hh:mm a').parse(date);
//     formattedDate = DateFormat('MMM dd, yyyy').format(dateTime);
//     formattedTime = DateFormat('hh:mm a').format(dateTime);
//   } catch (e) {
//     // Fallback for date parsing errors
//     debugPrint('Date parsing error: $e');
//     formattedDate = date.split(' ').take(3).join(' '); // Try to extract date part
//     formattedTime = time.isNotEmpty ? time : '';
//   }

//   final controller = Get.find<TechnicianTicketsController>();
//   debugPrint('Original date: $date, time: $time');

//   return InkWell(
//     onTap: () {
//       if (complaint != null) {
//         Get.to(() => TicketDetailsScreen(complaint: complaint));
//       }
//     },
//     child: Container(
//       padding: EdgeInsets.all(Get.width * 0.04),
//       decoration: BoxDecoration(
//         color: AppColors.whiteLight,
//         borderRadius: BorderRadius.circular(screenWidth4),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.black.withOpacity(0.05),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Enhanced Header Section
//           _buildHeaderSection(
//             propertyName: propertyName,
//             category: category,
//             issue: issue,
//             status: status,
//             statusColor: statusColor,
//             categoryIcon: categoryIcon,
//             complaint: complaint,
//           ),

//           SizedBox(height: Get.height * 0.010),

//           // Description Section
//           _buildDescriptionSection(description),

//           SizedBox(height: Get.height * 0.015),

//           // Date and Time Section
//           _buildDateTimeSection(formattedTime, formattedDate),

//           // Technician Assignment Section (only for pending tickets)
//           if (_isPendingStatus(status)) ...[
//             SizedBox(height: Get.height * 0.02),
//             _buildTechnicianAssignmentSection(complaintId, controller),
//           ],

//           SizedBox(height: Get.height * 0.02),

//           // Action Buttons Section
//           _buildActionButtonsSection(complaint, complaintId, category),
//         ],
//       ),
//     ),
//   );
// }

// // Helper method to build header section
// Widget _buildHeaderSection({
//   required String propertyName,
//   required String category,
//   required String issue,
//   required String status,
//   required Color statusColor,
//   required IconData categoryIcon,
//   Complaint? complaint,
// }) {
//   return Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: [
//       Expanded(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Property Name
//             CustomTextWidget(
//               title: propertyName,
//               fontSize: screenHeight * 0.018,
//               fontWeight: FontWeight.w600,
//               color: AppColors.black,
//             ),
//             SizedBox(height: Get.height * 0.005),
            
//             // Category and Issue with Icon
//             Row(
//               children: [
//                 Icon(
//                   categoryIcon,
//                   size: 16,
//                   color: AppColors.black.withOpacity(0.7),
//                 ),
//                 SizedBox(width: Get.width * 0.015),
//                 Expanded(
//                   child: CustomTextWidget(
//                     title: '$category • $issue',
//                     fontSize: screenHeight * 0.014,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.black,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),

//             SizedBox(height: Get.height * 0.010),
            
//             // Status Badge
//             Container(
//               padding: EdgeInsets.symmetric(
//                 horizontal: Get.width * 0.025,
//                 vertical: Get.height * 0.005,
//               ),
//               decoration: BoxDecoration(
//                 color: statusColor,
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: CustomTextWidget(
//                 title: status,
//                 fontSize: screenHeight * 0.012,
//                 fontWeight: FontWeight.w500,
//                 color: AppColors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
      
//       // Image Section
//       if (_hasImages(complaint))
//         _buildImagePreview(complaint!),
//     ],
//   );
// }

// // Helper method to build description section
// Widget _buildDescriptionSection(String description) {
//   return CustomTextWidget(
//     maxLines: 2,
//     title: description,
//     fontSize: screenHeight * 0.014,
//     color: AppColors.black.withOpacity(0.9),
//     fontWeight: FontWeight.w500,
//   );
// }

// // Helper method to build date time section
// Widget _buildDateTimeSection(String formattedTime, String formattedDate) {
//   return Row(
//     children: [
//       Icon(
//         HugeIcons.strokeRoundedCalendar01,
//         size: 16,
//         color: AppColors.black.withOpacity(0.5),
//       ),
//       SizedBox(width: Get.width * 0.015),
//       CustomTextWidget(
//         title: '$formattedTime • $formattedDate',
//         fontSize: 12,
//         color: AppColors.black.withOpacity(0.9),
//         fontWeight: FontWeight.w500,
//       ),
//     ],
//   );
// }

// // Helper method to build technician assignment section
// Widget _buildTechnicianAssignmentSection(
//   String complaintId,
//   TechnicianTicketsController controller,
// ) {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       const Divider(),
//       SizedBox(height: Get.height * 0.015),
      
//       CustomTextWidget(
//         title: 'Assign to Technician',
//         fontSize: screenHeight * 0.014,
//         fontWeight: FontWeight.w600,
//         color: AppColors.black,
//       ),
//       SizedBox(height: Get.height * 0.01),

//       // Technician Dropdown
//       _buildTechnicianDropdown(complaintId, controller),

//       SizedBox(height: Get.height * 0.015),

//       // Assign Button
//       _buildAssignButton(complaintId, controller),

//       SizedBox(height: Get.height * 0.01),
//     ],
//   );
// }

// // Helper method to build technician dropdown
// Widget _buildTechnicianDropdown(
//   String complaintId,
//   TechnicianTicketsController controller,
// ) {
//   return Obx(() {
//     final selectedTechId = controller.selectedTechnicianIds[complaintId] ?? '';

//     if (controller.availableTechnicians.isEmpty && controller.isLoading.value) {
//       return Container(
//         padding: EdgeInsets.all(Get.width * 0.03),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(6),
//           border: Border.all(color: AppColors.darkGrey.withOpacity(0.2)),
//         ),
//         child: Row(
//           children: [
//             SizedBox(
//               width: 16,
//               height: 16,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2,
//                 valueColor: AlwaysStoppedAnimation<Color>(
//                   AppColors.black.withOpacity(0.5),
//                 ),
//               ),
//             ),
//             SizedBox(width: Get.width * 0.03),
//             CustomTextWidget(
//               title: 'Loading technicians...',
//               fontSize: screenHeight * 0.012,
//               color: AppColors.black.withOpacity(0.5),
//             ),
//           ],
//         ),
//       );
//     }

//     if (controller.availableTechnicians.isEmpty) {
//       return Container(
//         padding: EdgeInsets.all(Get.width * 0.03),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(6),
//           border: Border.all(color: AppColors.darkGrey.withOpacity(0.2)),
//         ),
//         child: CustomTextWidget(
//           title: 'No technicians available',
//           fontSize: screenHeight * 0.014,
//           color: AppColors.black.withOpacity(0.5),
//         ),
//       );
//     }

//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: AppColors.darkGrey.withOpacity(0.2)),
//       ),
//       padding: EdgeInsets.symmetric(horizontal: Get.width * 0.03),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           isExpanded: true,
//           value: selectedTechId.isEmpty ? null : selectedTechId,
//           hint: CustomTextWidget(
//             title: 'Select Technician',
//             fontSize: screenHeight * 0.014,
//             color: AppColors.black.withOpacity(0.5),
//           ),
//           items: controller.availableTechnicians.map((tech) {
//             return DropdownMenuItem<String>(
//               value: tech['id'],
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.person,
//                     size: 16,
//                     color: AppColors.black.withOpacity(0.7),
//                   ),
//                   SizedBox(width: Get.width * 0.02),
//                   Expanded(
//                     child: CustomTextWidget(
//                       title: tech['name'] ?? 'Unknown Technician',
//                       fontSize: screenHeight * 0.014,
//                       color: AppColors.black,
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//           onChanged: (value) {
//             if (value != null) {
//               controller.selectedTechnicianIds[complaintId] = value;
//             }
//           },
//         ),
//       ),
//     );
//   });
// }

// // Helper method to build assign button
// Widget _buildAssignButton(
//   String complaintId,
//   TechnicianTicketsController controller,
// ) {
//   return Obx(() {
//     final selectedTechId = controller.selectedTechnicianIds[complaintId] ?? '';
//     final isAssigning = controller.isAssigningMap[complaintId] ?? false;

//     return CustomButtonWidget(
//       buttonHeight: screenHeight * 0.040,
//       buttonTitle: isAssigning ? 'Assigning...' : 'Assign Technician',
//       onPressed: (isAssigning || selectedTechId.isEmpty)
//           ? null
//           : () => _handleTechnicianAssignment(complaintId, selectedTechId, controller),
//       buttonShape: 'rect',
//       borderColor: AppColors.secondaryColor,
//       buttonColor: (isAssigning || selectedTechId.isEmpty) 
//           ? AppColors.darkGrey.withOpacity(0.3)
//           : AppColors.secondaryColor,
//       fontSize: screenHeight * 0.014,
//       buttonTextColor: AppColors.white,
//     );
//   });
// }

// // Helper method to build action buttons section
// Widget _buildActionButtonsSection(
//   Complaint? complaint,
//   String complaintId,
//   String category,
// ) {
//   return Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: [
//       Expanded(
//         child: CustomButtonWidget(
//           buttonHeight: screenHeight * 0.040,
//           buttonTitle: 'View Details',
//           onPressed: () {
//             if (complaint != null) {
//               debugPrint("Complaint Details inside navigation ==> $complaint");
//               Get.to(() => TicketDetailsScreen(complaint: complaint));
//             } else {
//               Get.snackbar(
//                 'Error',
//                 'Complaint details not available',
//                 snackPosition: SnackPosition.BOTTOM,
//               );
//             }
//           },
//           buttonShape: 'rect',
//           borderColor: AppColors.darkGrey.withOpacity(0.2),
//           buttonColor: AppColors.white,
//           fontSize: screenHeight * 0.014,
//           buttonTextColor: AppColors.black,
//         ),
//       ),
//       SizedBox(width: Get.width * 0.02),
//       Expanded(
//         child: CustomButtonWidget(
//           buttonHeight: screenHeight * 0.040,
//           buttonTitle: 'Reply',
//           onPressed: () {
//             Get.to(() => RectifyTicketsScreen(
//               complaintId: complaintId,
//               category: category,
//             ));
//           },
//           buttonShape: 'rect',
//           borderColor: AppColors.darkGrey.withOpacity(0.2),
//           buttonColor: AppColors.white,
//           fontSize: screenHeight * 0.014,
//           buttonTextColor: AppColors.black,
//         ),
//       ),
//     ],
//   );
// }

// // Helper method to build image preview
// Widget _buildImagePreview(Complaint complaint) {
//   return ClipRRect(
//     borderRadius: BorderRadius.circular(6),
//     child: CachedNetworkImage(
//       imageUrl: _getFirstAvailableImage(complaint),
//       width: Get.width * 0.14,
//       height: Get.width * 0.14,
//       fit: BoxFit.cover,
//       placeholder: (context, url) => Container(
//         color: AppColors.black.withOpacity(0.1),
//         child: Center(
//           child: SizedBox(
//             width: 16,
//             height: 16,
//             child: CircularProgressIndicator(
//               strokeWidth: 2,
//               valueColor: AlwaysStoppedAnimation<Color>(
//                 AppColors.black.withOpacity(0.3),
//               ),
//             ),
//           ),
//         ),
//       ),
//       errorWidget: (context, url, error) => Container(
//         color: AppColors.black.withOpacity(0.1),
//         child: Icon(
//           Icons.image,
//           color: AppColors.black.withOpacity(0.3),
//         ),
//       ),
//     ),
//   );
// }

// // Helper method to handle technician assignment
// Future<void> _handleTechnicianAssignment(
//   String complaintId,
//   String selectedTechId,
//   TechnicianTicketsController controller,
// ) async {
//   // Show loading state
//   controller.setAssigning(complaintId, true);

//   try {
//     await controller.assignTechnician(complaintId, selectedTechId);

//     // Remove the assigned ticket from local list immediately
//     final index = controller.tickets.indexWhere((t) => t.complaintId == complaintId);
//     if (index != -1) {
//       controller.tickets.removeAt(index);
//     }

//     // Clear the selection
//     controller.selectedTechnicianIds.remove(complaintId);

//     // Show success message
//     Get.snackbar(
//       'Success',
//       'Technician assigned successfully',
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.green.withOpacity(0.8),
//       colorText: Colors.white,
//     );
//   } catch (e) {
//     Get.snackbar(
//       'Error',
//       'Failed to assign technician: ${e.toString()}',
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.red.withOpacity(0.8),
//       colorText: Colors.white,
//     );
//   } finally {
//     controller.setAssigning(complaintId, false);
//   }
// }

// // Helper method to get first available image
// String _getFirstAvailableImage(Complaint complaint) {
//   // Check in order of priority:
//   // 1. Direct images list
//   if (complaint.images.isNotEmpty) return complaint.images.first;

//   // 2. Tenant uploaded images
//   if (complaint.complaintImages.tenantUploaded.isNotEmpty) {
//     return complaint.complaintImages.tenantUploaded.first;
//   }

//   // 3. Admin uploaded images
//   if (complaint.complaintImages.adminUploaded.isNotEmpty) {
//     return complaint.complaintImages.adminUploaded.first;
//   }

//   // 4. Technician uploaded images
//   if (complaint.complaintImages.technicianUploaded.isNotEmpty) {
//     return complaint.complaintImages.technicianUploaded.first;
//   }

//   // 5. Admin/Technician uploaded images
//   if (complaint.complaintImages.adminTechnicianUploaded.isNotEmpty) {
//     return complaint.complaintImages.adminTechnicianUploaded.first;
//   }

//   // Fallback empty image
//   return '';
// }

// // Helper method to check if complaint has images
// bool _hasImages(Complaint? complaint) {
//   if (complaint == null) return false;
  
//   return complaint.images.isNotEmpty ||
//       complaint.complaintImages.tenantUploaded.isNotEmpty ||
//       complaint.complaintImages.adminUploaded.isNotEmpty ||
//       complaint.complaintImages.technicianUploaded.isNotEmpty ||
//       complaint.complaintImages.adminTechnicianUploaded.isNotEmpty;
// }

// // Helper method to check if status is pending
// bool _isPendingStatus(String status) {
//   return status.toLowerCase() == 'pending';
// }



import 'package:cached_network_image/cached_network_image.dart';
import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:dar_al_safwa/data/model/technican_ticket_view_model.dart';
import 'package:dar_al_safwa/data/model/technician_complaints_response.dart';
import 'package:dar_al_safwa/data/model/ticket_list_response_model.dart';
import 'package:dar_al_safwa/domain/controller/technician_tickets_controller.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/tenants_ticket_details_screen.dart' show TicketDetailsScreen;
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/tenants_tickets_list_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_text_widget.dart';
import 'technician_rectify_ticket_screen.dart';

Widget buildTicketCard({
  required String propertyName,
  required String category,
  required String issue,
  required String status,
  required Color statusColor,
  required String description,
  required String date,
  required String time,
  required IconData categoryIcon,
  ComplaintImages? images,
  required String complaintId,
  Complaint? complaint,
}) {
  // Enhanced date parsing with error handling
  DateTime? dateTime;
  String formattedDate = '';
  String formattedTime = '';
  
  try {
    dateTime = DateFormat('MMM dd, yyyy hh:mm a').parse(date);
    formattedDate = DateFormat('MMM dd, yyyy').format(dateTime);
    formattedTime = DateFormat('hh:mm a').format(dateTime);
  } catch (e) {
    // Fallback for date parsing errors
    debugPrint('Date parsing error: $e');
    formattedDate = date.split(' ').take(3).join(' '); // Try to extract date part
    formattedTime = time.isNotEmpty ? time : '';
  }

  final controller = Get.find<TechnicianTicketsController>();
  debugPrint('Original date: $date, time: $time');

  return InkWell(
    onTap: () {
      if (complaint != null) {
        Get.to(() => TicketDetailsScreen(complaint: complaint));
      }
    },
    child: Container(
      padding: EdgeInsets.all(Get.width * 0.04),
      decoration: BoxDecoration(
        color: AppColors.whiteLight,
        borderRadius: BorderRadius.circular(screenWidth4),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header Section
          _buildHeaderSection(
            propertyName: propertyName,
            category: category,
            issue: issue,
            status: status,
            statusColor: statusColor,
            categoryIcon: categoryIcon,
            complaint: complaint,
          ),

          SizedBox(height: Get.height * 0.010),

          // Description Section
          _buildDescriptionSection(description),

          SizedBox(height: Get.height * 0.015),

          // Date and Time Section
          _buildDateTimeSection(formattedTime, formattedDate),

          // Show current assigned technician if any
          _buildCurrentAssignmentSection(complaintId, controller),

          // Technician Assignment Section (for pending tickets or reassignment)
          if (_canAssignOrReassign(status)) ...[
            SizedBox(height: Get.height * 0.02),
            _buildTechnicianAssignmentSection(complaintId, controller),
          ],

          SizedBox(height: Get.height * 0.02),

          // Action Buttons Section
          _buildActionButtonsSection(complaint, complaintId, category),
        ],
      ),
    ),
  );
}

// Helper method to build header section
Widget _buildHeaderSection({
  required String propertyName,
  required String category,
  required String issue,
  required String status,
  required Color statusColor,
  required IconData categoryIcon,
  Complaint? complaint,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Name
            CustomTextWidget(
              title: propertyName,
              fontSize: screenHeight * 0.018,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
            SizedBox(height: Get.height * 0.005),
            
            // Category and Issue with Icon
            Row(
              children: [
                Icon(
                  categoryIcon,
                  size: 16,
                  color: AppColors.black.withOpacity(0.7),
                ),
                SizedBox(width: Get.width * 0.015),
                Expanded(
                  child: CustomTextWidget(
                    title: '$category • $issue',
                    fontSize: screenHeight * 0.014,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: Get.height * 0.010),
            
            // Status Badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Get.width * 0.025,
                vertical: Get.height * 0.005,
              ),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: CustomTextWidget(
                title: status,
                fontSize: screenHeight * 0.012,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
      
      // Image Section
      if (_hasImages(complaint))
        _buildImagePreview(complaint!),
    ],
  );
}

// Helper method to build current assignment section
Widget _buildCurrentAssignmentSection(
  String complaintId,
  TechnicianTicketsController controller,
) {
  return Obx(() {
    final assignedTechId = controller.assignedTechnicianIds[complaintId];
    if (assignedTechId == null || assignedTechId.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find the assigned technician name
    final assignedTech = controller.availableTechnicians.firstWhere(
      (tech) => tech['id'] == assignedTechId,
      orElse: () => {'name': 'Unknown Technician'},
    );

    return Container(
      margin: EdgeInsets.only(top: Get.height * 0.015),
      padding: EdgeInsets.all(Get.width * 0.03),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.secondaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_2_outlined,
            size: 16,
            color: AppColors.secondaryColor,
          ),
          SizedBox(width: Get.width * 0.02),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextWidget(
                  title: 'Currently Assigned To:',
                  fontSize: screenHeight * 0.012,
                  color: AppColors.black.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
                SizedBox(height: Get.height * 0.002),
                CustomTextWidget(
                  title: assignedTech['name'] ?? 'Unknown Technician',
                  fontSize: screenHeight * 0.014,
                  color: AppColors.black,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
          // Reassign button
          TextButton(
            onPressed: () {
              // Clear current selection to allow reassignment
              controller.selectedTechnicianIds[complaintId] = '';
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: Get.width * 0.02,
                vertical: Get.height * 0.005,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: CustomTextWidget(
              title: 'Reassign',
              fontSize: screenHeight * 0.012,
              color: AppColors.secondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  });
}

// Helper method to build description section
Widget _buildDescriptionSection(String description) {
  return CustomTextWidget(
    maxLines: 2,
    title: description,
    fontSize: screenHeight * 0.014,
    color: AppColors.black.withOpacity(0.9),
    fontWeight: FontWeight.w500,
  );
}

// Helper method to build date time section
Widget _buildDateTimeSection(String formattedTime, String formattedDate) {
  return Row(
    children: [
      Icon(
        HugeIcons.strokeRoundedCalendar01,
        size: 16,
        color: AppColors.black.withOpacity(0.5),
      ),
      SizedBox(width: Get.width * 0.015),
      CustomTextWidget(
        title: '$formattedTime • $formattedDate',
        fontSize: 12,
        color: AppColors.black.withOpacity(0.9),
        fontWeight: FontWeight.w500,
      ),
    ],
  );
}

// Helper method to build technician assignment section
Widget _buildTechnicianAssignmentSection(
  String complaintId,
  TechnicianTicketsController controller,
) {
  return Obx(() {
    final assignedTechId = controller.assignedTechnicianIds[complaintId];
    final isReassigning = assignedTechId != null && assignedTechId.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        SizedBox(height: Get.height * 0.015),
        
        CustomTextWidget(
          title: isReassigning ? 'Reassign to Another Technician' : 'Assign to Technician',
          fontSize: screenHeight * 0.014,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        
        if (isReassigning) ...[
          SizedBox(height: Get.height * 0.005),
          CustomTextWidget(
            title: 'Select a different technician if the current one is busy',
            fontSize: screenHeight * 0.012,
            color: AppColors.black.withOpacity(0.6),
            fontWeight: FontWeight.w400,
          ),
        ],
        
        SizedBox(height: Get.height * 0.01),

        // Technician Dropdown
        _buildTechnicianDropdown(complaintId, controller),

        SizedBox(height: Get.height * 0.015),

        // Assign/Reassign Button
        _buildAssignButton(complaintId, controller, isReassigning),

        SizedBox(height: Get.height * 0.01),
      ],
    );
  });
}

// Helper method to build technician dropdown
Widget _buildTechnicianDropdown(
  String complaintId,
  TechnicianTicketsController controller,
) {
  return Obx(() {
    final selectedTechId = controller.selectedTechnicianIds[complaintId] ?? '';
    final assignedTechId = controller.assignedTechnicianIds[complaintId] ?? '';

    if (controller.availableTechnicians.isEmpty && controller.isLoading.value) {
      return Container(
        padding: EdgeInsets.all(Get.width * 0.03),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.darkGrey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.black.withOpacity(0.5),
                ),
              ),
            ),
            SizedBox(width: Get.width * 0.03),
            CustomTextWidget(
              title: 'Loading technicians...',
              fontSize: screenHeight * 0.012,
              color: AppColors.black.withOpacity(0.5),
            ),
          ],
        ),
      );
    }

    if (controller.availableTechnicians.isEmpty) {
      return Container(
        padding: EdgeInsets.all(Get.width * 0.03),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.darkGrey.withOpacity(0.2)),
        ),
        child: CustomTextWidget(
          title: 'No technicians available',
          fontSize: screenHeight * 0.014,
          color: AppColors.black.withOpacity(0.5),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.darkGrey.withOpacity(0.2)),
      ),
      padding: EdgeInsets.symmetric(horizontal: Get.width * 0.03),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedTechId.isEmpty ? null : selectedTechId,
          hint: CustomTextWidget(
            title: 'Select Technician',
            fontSize: screenHeight * 0.014,
            color: AppColors.black.withOpacity(0.5),
          ),
          items: controller.availableTechnicians.map((tech) {
            final isCurrentlyAssigned = tech['id'] == assignedTechId;
            return DropdownMenuItem<String>(
              value: tech['id'],
              child: Row(
                children: [
                  Icon(
                    isCurrentlyAssigned ? Icons.person : Icons.person,
                    size: 16,
                    color: isCurrentlyAssigned 
                        ? AppColors.secondaryColor 
                        : AppColors.black.withOpacity(0.7),
                  ),
                  SizedBox(width: Get.width * 0.02),
                  Expanded(
                    child: CustomTextWidget(
                      title: '${tech['name'] ?? 'Unknown Technician'}${isCurrentlyAssigned ? ' (Current)' : ''}',
                      fontSize: screenHeight * 0.014,
                      color: isCurrentlyAssigned 
                          ? AppColors.secondaryColor 
                          : AppColors.black,
                      fontWeight: isCurrentlyAssigned 
                          ? FontWeight.w600 
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              controller.selectedTechnicianIds[complaintId] = value;
            }
          },
        ),
      ),
    );
  });
}

// Helper method to build assign button
Widget _buildAssignButton(
  String complaintId,
  TechnicianTicketsController controller,
  bool isReassigning,
) {
  return Obx(() {
    final selectedTechId = controller.selectedTechnicianIds[complaintId] ?? '';
    final assignedTechId = controller.assignedTechnicianIds[complaintId] ?? '';
    final isAssigning = controller.isAssigningMap[complaintId] ?? false;
    
    // Check if the selected technician is different from currently assigned
    final isDifferentTechnician = selectedTechId != assignedTechId;
    final canPerformAction = !isAssigning && selectedTechId.isNotEmpty && 
                           (!isReassigning || isDifferentTechnician);

    String buttonTitle;
    if (isAssigning) {
      buttonTitle = isReassigning ? 'Reassigning...' : 'Assigning...';
    } else if (isReassigning) {
      buttonTitle = isDifferentTechnician ? 'Reassign Technician' : 'Select Different Technician';
    } else {
      buttonTitle = 'Assign Technician';
    }

    return CustomButtonWidget(
      buttonColor:AppColors.secondaryColor,
      buttonHeight: screenHeight * 0.040,
      buttonTitle: buttonTitle,
      
      onPressed: canPerformAction
          ? () => _handleTechnicianAssignment(complaintId, selectedTechId, controller, isReassigning)
          : null,
      buttonShape: 'rect',
      borderColor: AppColors.secondaryColor,
     
      fontSize: screenHeight * 0.014,
      buttonTextColor: AppColors.white,
    );
  });
}

// Helper method to build action buttons section
Widget _buildActionButtonsSection(
  Complaint? complaint,
  String complaintId,
  String category,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: CustomButtonWidget(
          buttonHeight: screenHeight * 0.040,
          buttonTitle: 'View Details',
          onPressed: () {
            if (complaint != null) {
              debugPrint("Complaint Details inside navigation ==> $complaint");
              Get.to(() => TicketDetailsScreen(complaint: complaint));
            } else {
              Get.snackbar(
                'Error',
                'Complaint details not available',
                snackPosition: SnackPosition.BOTTOM,
              );
            }
          },
          buttonShape: 'rect',
          borderColor: AppColors.darkGrey.withOpacity(0.2),
          buttonColor: AppColors.white,
          fontSize: screenHeight * 0.014,
          buttonTextColor: AppColors.black,
        ),
      ),
      SizedBox(width: Get.width * 0.02),
      Expanded(
        child: CustomButtonWidget(
          buttonHeight: screenHeight * 0.040,
          buttonTitle: 'Reply',
          onPressed: () {
            Get.to(() => RectifyTicketsScreen(
              complaintId: complaintId,
              category: category,
            ));
          },
          buttonShape: 'rect',
          borderColor: AppColors.darkGrey.withOpacity(0.2),
          buttonColor: AppColors.white,
          fontSize: screenHeight * 0.014,
          buttonTextColor: AppColors.black,
        ),
      ),
    ],
  );
}

// Helper method to build image preview
Widget _buildImagePreview(Complaint complaint) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: CachedNetworkImage(
      imageUrl: _getFirstAvailableImage(complaint),
      width: Get.width * 0.14,
      height: Get.width * 0.14,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppColors.black.withOpacity(0.1),
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.black.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.black.withOpacity(0.1),
        child: Icon(
          Icons.image,
          color: AppColors.black.withOpacity(0.3),
        ),
      ),
    ),
  );
}

// Modified helper method to handle technician assignment/reassignment
// Updated helper method to handle technician assignment/reassignment 
// (matching your actual controller implementation)
Future<void> _handleTechnicianAssignment(
  String complaintId,
  String selectedTechId,
  TechnicianTicketsController controller,
  bool isReassigning,
) async {
  // Show loading state
  controller.setAssigning(complaintId, true);

  try {
    // Call the actual API method from your controller
    await controller.assignTechnician(complaintId, selectedTechId);

    // Your assignTechnician method already handles:
    // 1. API call to "complaints/escalate"
    // 2. Removing the ticket from the list: tickets.removeWhere((ticket) => ticket.complaintId == complaintId)
    // 3. Clearing selection: selectedTechnicianIds.remove(complaintId)
    // 4. Success/error messages

    // For reassignment case, we need to handle it differently since 
    // your current API removes the ticket entirely
    if (isReassigning) {
      // Store the assigned technician ID for UI purposes
      controller.assignedTechnicianIds[complaintId] = selectedTechId;
    }

    // Note: The success message and ticket removal is already handled 
    // in your controller's assignTechnician method
    
  } catch (e) {
    // Error handling is already done in your controller's assignTechnician method
    debugPrint('Assignment error caught in UI handler: $e');
  } finally {
    // Loading state is already handled in your controller's assignTechnician method
    // But we'll ensure it's reset here too
    controller.setAssigning(complaintId, false);
  }
}
// Helper method to get first available image
String _getFirstAvailableImage(Complaint complaint) {
  // Check in order of priority:
  // 1. Direct images list
  if (complaint.images.isNotEmpty) return complaint.images.first;

  // 2. Tenant uploaded images
  if (complaint.complaintImages.tenantUploaded.isNotEmpty) {
    return complaint.complaintImages.tenantUploaded.first;
  }

  // 3. Admin uploaded images
  if (complaint.complaintImages.adminUploaded.isNotEmpty) {
    return complaint.complaintImages.adminUploaded.first;
  }

  // 4. Technician uploaded images
  if (complaint.complaintImages.technicianUploaded.isNotEmpty) {
    return complaint.complaintImages.technicianUploaded.first;
  }

  // 5. Admin/Technician uploaded images
  if (complaint.complaintImages.adminTechnicianUploaded.isNotEmpty) {
    return complaint.complaintImages.adminTechnicianUploaded.first;
  }

  // Fallback empty image
  return '';
}

// Helper method to check if complaint has images
bool _hasImages(Complaint? complaint) {
  if (complaint == null) return false;
  
  return complaint.images.isNotEmpty ||
      complaint.complaintImages.tenantUploaded.isNotEmpty ||
      complaint.complaintImages.adminUploaded.isNotEmpty ||
      complaint.complaintImages.technicianUploaded.isNotEmpty ||
      complaint.complaintImages.adminTechnicianUploaded.isNotEmpty;
}

// Modified helper method to check if can assign or reassign
bool _canAssignOrReassign(String status) {
  // Allow assignment for pending tickets or tickets that can be reassigned
  final assignableStatuses = ['pending', 'assigned', 'in_progress'];
  return assignableStatuses.contains(status.toLowerCase());
}