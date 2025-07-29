import 'package:cached_network_image/cached_network_image.dart';
import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:dar_al_safwa/data/model/technican_ticket_view_model.dart';
import 'package:dar_al_safwa/domain/controller/technician_tickets_controller.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/tenants_ticket_details_screen.dart' show TicketDetailsScreen;
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/tenants_tickets_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_text_widget.dart';
import 'technician_rectify_ticket_screen.dart';
Widget buildTicketCard( {
  required String propertyName,
  required String category,
  required String issue,
  required String status,
  required Color statusColor,
  required String description,
  required String date,
  required String time,
  required IconData categoryIcon,
  required List<String> images,
  required TicketModel ticket,
  required String complaintId,
  required String mobile,
  required String name,
}) {
  final controller = Get.find<TechnicianTicketsController>();
  
  return InkWell(
    onTap: () {},
    child: Container(
      padding: EdgeInsets.all(Get.width * 0.04),
      decoration: BoxDecoration(
        color: AppColors.whiteLight,
        borderRadius: BorderRadius.circular(screenWidth4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (same as before)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextWidget(
                    title: propertyName,
                    fontSize: screenHeight * 0.018,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                  SizedBox(height: Get.height * 0.005),
                  CustomTextWidget(
                    title: '$category • $issue',
                    fontSize: screenHeight * 0.014,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                  SizedBox(height: Get.height * 0.010),
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
              if (images.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: images.first,
                    width: Get.width * 0.14,
                    height: Get.width * 0.14,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.black.withOpacity(0.1),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.black.withOpacity(0.1),
                      child: Icon(Icons.image, color: AppColors.black.withOpacity(0.3)),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: Get.height * 0.010),

          CustomTextWidget(
            maxLines: 2,
            title: description,
            fontSize: screenHeight * 0.014,
            color: AppColors.black.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),

          SizedBox(height: Get.height * 0.015),

          Row(
            children: [
              Icon(
                HugeIcons.strokeRoundedCalendar01,
                size: 16,
                color: AppColors.black.withOpacity(0.5),
              ),
              SizedBox(width: Get.width * 0.015),
              CustomTextWidget(
                title: '$date • $time',
                fontSize: 12,
                color: AppColors.black.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ],
          ),

          if (status.toLowerCase() == 'pending') ...[
            SizedBox(height: Get.height * 0.02),
            const Divider(),
            SizedBox(height: Get.height * 0.015),
            CustomTextWidget(
              title: 'Assign to Technician',
              fontSize: screenHeight * 0.014,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
            SizedBox(height: Get.height * 0.01),

            // Technician Dropdown
            Obx(() {
              final selectedTechId = controller.selectedTechnicianIds[complaintId] ?? '';

              if (controller.availableTechnicians.isEmpty && controller.isLoading.value) {
                return CustomTextWidget(
                  title: 'Loading technicians...',
                  fontSize: screenHeight * 0.012,
                  color: AppColors.black.withOpacity(0.5),
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
                      return DropdownMenuItem<String>(
                        value: tech['id'],
                        child: CustomTextWidget(
                          title: tech['name'] ?? 'Unknown Technician',
                          fontSize: screenHeight * 0.014,
                          color: AppColors.black,
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
            }),

            SizedBox(height: Get.height * 0.015),

            // Assign Button
            Obx(() {
              final selectedTechId = controller.selectedTechnicianIds[complaintId] ?? '';
              final isAssigning = controller.isAssigningMap[complaintId] ?? false;

              return CustomButtonWidget(
                buttonHeight: screenHeight * 0.040,
                buttonTitle: isAssigning ? 'Assigning...' : 'Assign Technician',
                onPressed: isAssigning
                    ? null
                    : () async {
                        if (selectedTechId.isEmpty) {
                          Get.snackbar('Error', 'Please select a technician',
                              snackPosition: SnackPosition.BOTTOM);
                          return;
                        }

                        // Show loading state
                        controller.setAssigning(complaintId, true);
                        
                        try {
                          await controller.assignTechnician(complaintId, selectedTechId);
                          
                          // Remove the assigned ticket from local list immediately
                          final index = controller.tickets.indexWhere((t) => t.complaintId == complaintId);
                          if (index != -1) {
                            controller.tickets.removeAt(index);
                          }
                          
                          // Clear the selection
                          controller.selectedTechnicianIds.remove(complaintId);
                          
                          // Show success message
                          Get.snackbar(
                            'Success',
                            'Technician assigned successfully',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        } catch (e) {
                          Get.snackbar(
                            'Error',
                            'Failed to assign technician: ${e.toString()}',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        } finally {
                          controller.setAssigning(complaintId, false);
                        }
                      },
                buttonShape: 'rect',
                borderColor: AppColors.secondaryColor,
                buttonColor: AppColors.secondaryColor,
                fontSize: screenHeight * 0.014,
                buttonTextColor: AppColors.white,
              );
            }),

            SizedBox(height: Get.height * 0.01),
          ],

          // Footer Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomButtonWidget(
                  buttonHeight: screenHeight * 0.040,
                  buttonTitle: 'View Details',
                  onPressed: () {
                    Get.to(() => TicketDetailsScreen(ticket: ticket,));
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
                    Get.to(() => RectifyTicketsScreen(complaintId: complaintId));
                  },
                  buttonShape: 'rect',
                  borderColor: AppColors.darkGrey.withOpacity(0.2),
                  buttonColor: AppColors.white,
                  fontSize: screenHeight * 0.014,
                  buttonTextColor: AppColors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}