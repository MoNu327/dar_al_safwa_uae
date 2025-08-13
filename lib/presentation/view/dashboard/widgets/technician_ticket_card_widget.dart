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

Widget  buildTicketCard({
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

          // Current Assignment Display (Always visible if assigned)
          _buildCurrentAssignmentSection(complaintId, controller, complaint),

          // Technician Assignment Section (for pending tickets or reassignment)
          if (_canAssignOrReassign(status, complaint)) ...[
            SizedBox(height: Get.height * 0.02),
            _buildTechnicianAssignmentSection(complaintId, controller, complaint),
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

// FIXED: Updated method to get assignment info from multiple sources with priority
String? _getAssignedTechnicianId(String complaintId, TechnicianTicketsController controller, Complaint? complaint) {
  // Priority 1: From controller's local state (for recent assignments)
  if (controller.assignedTechnicianIds.containsKey(complaintId)) {
    return controller.assignedTechnicianIds[complaintId];
  }
  
  // Priority 2: From complaint object (after API refresh)
  if (complaint?.assignedTechnicianId != null && complaint!.assignedTechnicianId!.isNotEmpty) {
    return complaint.assignedTechnicianId;
  }
  
  return null;
}

String? _getAssignedTechnicianName(String complaintId, TechnicianTicketsController controller, Complaint? complaint, String? techId) {
  if (techId == null || techId.isEmpty) return null;
  
  // Priority 1: From complaint object
  if (complaint?.assignedTechnicianName != null && complaint!.assignedTechnicianName!.isNotEmpty) {
    return complaint.assignedTechnicianName;
  }
  
  // Priority 2: From controller's local storage
  String? localAssignedName = controller.assignedTechnicianNames[complaintId];
  if (localAssignedName != null && localAssignedName.isNotEmpty) {
    return localAssignedName;
  }
  
  // Priority 3: Find from available technicians list
  final assignedTech = controller.availableTechnicians.firstWhere(
    (tech) => tech['id'] == techId,
    orElse: () => {},
  );
  
  if (assignedTech.isNotEmpty && assignedTech['name'] != null) {
    // CACHE the name for future use
    controller.assignedTechnicianNames[complaintId] = assignedTech['name'];
    return assignedTech['name'];
  }
  
  return 'Unknown Technician';
}

// FIXED: Updated method to build current assignment section with better data persistence
Widget _buildCurrentAssignmentSection(
  String complaintId,
  TechnicianTicketsController controller,
  Complaint? complaint,
) {
  return Obx(() {
    // Get assigned technician info using the helper methods
    String? assignedTechId = _getAssignedTechnicianId(complaintId, controller, complaint);
    String? assignedTechName = _getAssignedTechnicianName(complaintId, controller, complaint, assignedTechId);

    // Don't show anything if no technician is assigned
    if (assignedTechId == null || assignedTechId.isEmpty) {
      return const SizedBox.shrink();
    }

    // FIXED: Move sync logic to post-frame callback to avoid build-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAssignmentData(complaintId, controller, complaint);
    });

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
            size: 18,
            color: AppColors.secondaryColor,
          ),
          SizedBox(width: Get.width * 0.02),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextWidget(
                  title: 'Assigned To:',
                  fontSize: screenHeight * 0.012,
                  color: AppColors.black.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
                SizedBox(height: Get.height * 0.002),
                CustomTextWidget(
                  title: assignedTechName ?? 'Unknown Technician',
                  fontSize: screenHeight * 0.014,
                  color: AppColors.black,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
          // Reassign button (only for admin/supervisor roles)
          if (_canReassign(complaint)) 
            TextButton(
              onPressed: () {
                // Use post-frame callback for state updates
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.showAssignmentSection[complaintId] = true;
                  controller.selectedTechnicianIds[complaintId] = '';
                });
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


void _syncAssignmentData(
  String complaintId, 
  TechnicianTicketsController controller, 
  Complaint? complaint
) {
  // Only sync if complaint has assignment data and local state doesn't
  if (complaint?.assignedTechnicianId != null && 
      complaint!.assignedTechnicianId!.isNotEmpty) {
    
    final localTechId = controller.assignedTechnicianIds[complaintId];
    final localTechName = controller.assignedTechnicianNames[complaintId];
    
    // Update local state only if it's missing or different
    if (localTechId != complaint.assignedTechnicianId) {
      controller.assignedTechnicianIds[complaintId] = complaint.assignedTechnicianId!;
      debugPrint("🔄 Synced technician ID for $complaintId: ${complaint.assignedTechnicianId}");
    }
    
    if (complaint.assignedTechnicianName != null && 
        complaint.assignedTechnicianName!.isNotEmpty &&
        localTechName != complaint.assignedTechnicianName) {
      controller.assignedTechnicianNames[complaintId] = complaint.assignedTechnicianName!;
      debugPrint("🔄 Synced technician name for $complaintId: ${complaint.assignedTechnicianName}");
    }
  }
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

// FIXED: Updated technician assignment section with better data handling
Widget _buildTechnicianAssignmentSection(
  String complaintId,
  TechnicianTicketsController controller,
  Complaint? complaint,
) {
  return Obx(() {
    final assignedTechId = _getAssignedTechnicianId(complaintId, controller, complaint);
    final isReassigning = assignedTechId != null && assignedTechId.isNotEmpty;
    final showSection = controller.showAssignmentSection[complaintId] ?? !isReassigning;

    // Don't show assignment section if already assigned and not in reassignment mode
    if (isReassigning && !showSection) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        SizedBox(height: Get.height * 0.015),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomTextWidget(
              title: isReassigning ? 'Reassign to Another Technician' : 'Assign to Technician',
              fontSize: screenHeight * 0.014,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
            if (isReassigning)
              TextButton(
                onPressed: () {
                  controller.showAssignmentSection[complaintId] = false;
                  controller.selectedTechnicianIds[complaintId] = '';
                },
                child: CustomTextWidget(
                  title: 'Cancel',
                  fontSize: screenHeight * 0.012,
                  color: AppColors.darkGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        
        if (isReassigning) ...[
          SizedBox(height: Get.height * 0.005),
          CustomTextWidget(
            title: 'Select a different technician to reassign this ticket',
            fontSize: screenHeight * 0.012,
            color: AppColors.black.withOpacity(0.6),
            fontWeight: FontWeight.w400,
          ),
        ],
        
        SizedBox(height: Get.height * 0.01),

        // Technician Dropdown
        _buildTechnicianDropdown(complaintId, controller, assignedTechId),

        SizedBox(height: Get.height * 0.015),

        // Assign/Reassign Button
        _buildAssignButton(complaintId, controller, isReassigning),

        SizedBox(height: Get.height * 0.01),
      ],
    );
  });
}

// Updated technician dropdown to show current assignment
Widget _buildTechnicianDropdown(
  String complaintId,
  TechnicianTicketsController controller,
  String? assignedTechId,
) {
  return Obx(() {
    final selectedTechId = controller.selectedTechnicianIds[complaintId] ?? '';

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
                    isCurrentlyAssigned ? Icons.person : Icons.person_outline,
                    size: 16,
                    color: isCurrentlyAssigned 
                        ? AppColors.secondaryColor 
                        : AppColors.black.withOpacity(0.7),
                  ),
                  SizedBox(width: Get.width * 0.02),
                  Expanded(
                    child: CustomTextWidget(
                      title: '${tech['name'] ?? 'Unknown Technician'}${isCurrentlyAssigned ? ' (Currently Assigned)' : ''}',
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

// Updated assign button
Widget _buildAssignButton(
  String complaintId,
  TechnicianTicketsController controller,
  bool isReassigning,
) {
  return Obx(() {
    final selectedTechId = controller.selectedTechnicianIds[complaintId] ?? '';
    final isAssigning = controller.isAssigningMap[complaintId] ?? false;
    
    final canPerformAction = !isAssigning && selectedTechId.isNotEmpty;

    String buttonTitle;
    if (isAssigning) {
      buttonTitle = isReassigning ? 'Reassigning...' : 'Assigning...';
    } else {
      buttonTitle = isReassigning ? 'Reassign Technician' : 'Assign Technician';
    }

    return CustomButtonWidget(
      buttonColor: AppColors.secondaryColor,
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
          onPressed: () async {
            // Navigate to RectifyTicketsScreen and handle the result
            final result = await Get.to(() => RectifyTicketsScreen(
              complaintId: complaintId,
              category: category,
            ));

            // Handle the result and refresh if needed
            if (result != null && result is Map<String, dynamic>) {
              print("Received result from rectify form: $result");
              
              if (result['updated'] == true) {
                final technicianUid = result['technicianUid'];
                
                if (technicianUid != null) {
                  try {
                    final fetchController = Get.find<TechnicianTicketsController>();
                    
                    // Always force refresh all data to ensure UI is up to date
                    print("Force refreshing all data after ticket update...");
                    await fetchController.forceRefreshAllTickets(technicianUid);
                    
                    // Also refresh summary stats
                    try {
                      await fetchController.refreshSummaryOnly(technicianUid);
                      print("Summary refreshed successfully");
                    } catch (summaryError) {
                      print("Summary refresh failed: $summaryError");
                      // Continue even if summary fails
                    }
                    
                    // Show success message after successful refresh
                    Get.snackbar(
                      'Success', 
                      result['message'] ?? 'Updated successfully',
                      backgroundColor: Colors.green, 
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                      duration: Duration(seconds: 3),
                    );
                    
                  } catch (e) {
                    print("Error refreshing data in receiving screen: $e");
                    // Still show success message even if refresh fails
                    Get.snackbar(
                      'Success', 
                      result['message'] ?? 'Updated successfully',
                      backgroundColor: Colors.green, 
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                      duration: Duration(seconds: 3),
                    );
                  }
                } else {
                  // Show success message even without technician UID
                  Get.snackbar(
                    'Success', 
                    result['message'] ?? 'Updated successfully',
                    backgroundColor: Colors.green, 
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: Duration(seconds: 3),
                  );
                }
              }
            }
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

// Helper method to update local complaint data
void _updateLocalComplaintData(
  String complaintId, 
  Map<String, dynamic> updatedData, 
  TechnicianTicketsController fetchController
) {
  try {
    // Find and update the complaint in the tickets list
    final ticketIndex = fetchController.tickets.indexWhere(
      (ticket) => ticket.complaintId == complaintId
    );
    
    if (ticketIndex != -1) {
      // You'll need to create a method in your Complaint model to update from Map
      // or create a new Complaint object from the updated data
      // For now, we'll trigger a refresh of the reactive list
      fetchController.tickets.refresh();
      
      // Also update filtered tickets if they exist
      final filteredIndex = fetchController.filteredTickets.indexWhere(
        (ticket) => ticket.complaintId == complaintId
      );
      
      if (filteredIndex != -1) {
        fetchController.filteredTickets.refresh();
      }
      
      print("✅ Updated local complaint data for $complaintId");
    } else {
      print("⚠️ Complaint $complaintId not found in local list");
    }
  } catch (e) {
    print("❌ Error updating local complaint data: $e");
  }
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

// FIXED: Updated assignment handler with better data persistence
Future<void> _handleTechnicianAssignment(
  String complaintId,
  String selectedTechId,
  TechnicianTicketsController controller,
  bool isReassigning,
) async {
  try {
    // Show loading state
    controller.setAssigning(complaintId, true);

    // Store technician info before assignment
    final selectedTech = controller.availableTechnicians.firstWhere(
      (tech) => tech['id'] == selectedTechId,
      orElse: () => {'id': selectedTechId, 'name': 'Unknown Technician'},
    );

    // Call API to assign technician
    await controller.assignTechnicianWithoutRemoval(complaintId, selectedTechId);
    
    // FIXED: Use post-frame callback for UI state updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Store the assignment in local state
      controller.assignedTechnicianIds[complaintId] = selectedTechId;
      controller.assignedTechnicianNames[complaintId] = selectedTech['name'] ?? 'Unknown Technician';
      
      // Clear the selection dropdown
      controller.selectedTechnicianIds[complaintId] = '';
      
      // Hide assignment section if it was a reassignment
      if (isReassigning) {
        controller.showAssignmentSection[complaintId] = false;
      }
      
      // Update the ticket in the local list
      _updateTicketInList(complaintId, selectedTechId, selectedTech['name'], controller, isReassigning);
    });

    // Show success message
    Get.snackbar(
      'Success',
      isReassigning 
          ? 'Technician reassigned successfully to ${selectedTech['name']}'
          : 'Technician assigned successfully to ${selectedTech['name']}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
    
  } catch (e) {
    Get.snackbar(
      'Error',
      'Failed to ${isReassigning ? 'reassign' : 'assign'} technician: ${e.toString()}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
    );
  } finally {
    // FIXED: Use post-frame callback for state updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.setAssigning(complaintId, false);
    });
  }
}


void _updateTicketInList(
  String complaintId, 
  String selectedTechId, 
  String? technicianName,
  TechnicianTicketsController controller,
  bool isReassigning
) {
  final ticketIndex = controller.tickets.indexWhere((t) => t.complaintId == complaintId);
  if (ticketIndex != -1) {
    try {
      // Create an updated complaint object with assignment info
      final updatedComplaint = controller.tickets[ticketIndex].copyWith(
        assignedTechnicianId: selectedTechId,
        assignedTechnicianName: technicianName,
        status: isReassigning ? controller.tickets[ticketIndex].status : 'Assigned',
      );
      
      // Replace the ticket in the list
      controller.tickets[ticketIndex] = updatedComplaint;
      
      // Update filtered tickets as well
      final filteredIndex = controller.filteredTickets.indexWhere((t) => t.complaintId == complaintId);
      if (filteredIndex != -1) {
        controller.filteredTickets[filteredIndex] = updatedComplaint;
      }
      
      debugPrint("✅ Updated ticket $complaintId in lists with assignment info");
    } catch (e) {
      debugPrint("❌ Error updating ticket in list: $e");
    }
  }
}

// Helper method to get first available image
String _getFirstAvailableImage(Complaint complaint) {
  if (complaint.images.isNotEmpty) return complaint.images.first;

  if (complaint.complaintImages.tenantUploaded.isNotEmpty) {
    return complaint.complaintImages.tenantUploaded.first;
  }

  if (complaint.complaintImages.adminUploaded.isNotEmpty) {
    return complaint.complaintImages.adminUploaded.first;
  }

  if (complaint.complaintImages.technicianUploaded.isNotEmpty) {
    return complaint.complaintImages.technicianUploaded.first;
  }

  if (complaint.complaintImages.adminTechnicianUploaded.isNotEmpty) {
    return complaint.complaintImages.adminTechnicianUploaded.first;
  }

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

bool _canAssignOrReassign(String status, Complaint? complaint) {
  // Allow assignment for pending tickets
  if (status.toLowerCase() == 'pending') return true;
  
  final reassignableStatuses = ['assigned', 'in_progress'];
  return reassignableStatuses.contains(status.toLowerCase()) && _canReassign(complaint);
}

bool _canReassign(Complaint? complaint) {

  return true;
}