import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:majan/core/utils/date_formater.dart';
import 'package:majan/data/model/ticket_list_response_model.dart';
import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_text_widget.dart';

class TicketDetailsScreen extends StatefulWidget {
  final Complaint? complaint;

  const TicketDetailsScreen({
    super.key,
    this.complaint,
  });

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  late ComplaintImages complaintImages;
  List<TimelineStep> timelineSteps = [];
  
  @override
  void initState() {
    super.initState();
    
    _debugComplaintStructure();
    _debugImageParsing();

    debugPrint('=== IMAGES INITIALIZATION ===');
    
    final originalComplaintImages = widget.complaint?.complaintImages ?? ComplaintImages();
    
    debugPrint('Original complaint images:');
    debugPrint('- Tenant: ${originalComplaintImages.tenantUploaded.length} images: ${originalComplaintImages.tenantUploaded}');
    debugPrint('- Admin: ${originalComplaintImages.adminUploaded.length} images: ${originalComplaintImages.adminUploaded}'); 
    debugPrint('- Technician: ${originalComplaintImages.technicianUploaded.length} images: ${originalComplaintImages.technicianUploaded}');
    debugPrint('- Admin/Technician: ${originalComplaintImages.adminTechnicianUploaded.length} images: ${originalComplaintImages.adminTechnicianUploaded}');

    final bool hasComplaintImages = originalComplaintImages.tenantUploaded.isNotEmpty ||
                                    originalComplaintImages.adminUploaded.isNotEmpty ||
                                    originalComplaintImages.technicianUploaded.isNotEmpty ||
                                    originalComplaintImages.adminTechnicianUploaded.isNotEmpty;

    if (hasComplaintImages) {
      complaintImages = originalComplaintImages;
      debugPrint('Using original categorized images');
    } else if (
      widget.complaint != null &&
      (
        widget.complaint!.complaintImages.tenantUploaded.isNotEmpty ||
        widget.complaint!.complaintImages.adminUploaded.isNotEmpty ||
        widget.complaint!.complaintImages.technicianUploaded.isNotEmpty ||
        widget.complaint!.complaintImages.adminTechnicianUploaded.isNotEmpty
      )
    ) {
      debugPrint('No categorized images found, applying fallback logic to direct images');
      
      debugPrint('Direct images to categorize: $complaintImages');
      
      final totalImages = complaintImages.tenantUploaded.length +
                          complaintImages.adminUploaded.length +
                          complaintImages.technicianUploaded.length +
                          complaintImages.adminTechnicianUploaded.length;
      if (totalImages == 1) {
        complaintImages = ComplaintImages(
          tenantUploaded: complaintImages.tenantUploaded ,
          adminUploaded: [],
          technicianUploaded: [],
          adminTechnicianUploaded: [],
        );
      } else if (totalImages == 2) {
        complaintImages = ComplaintImages(
          tenantUploaded:[],
          technicianUploaded: [],
          adminUploaded: [],
          adminTechnicianUploaded: [],
        );
      } else if (totalImages >= 3) {
        final thirdPoint = (totalImages / 3).floor();
        final twoThirdsPoint = (totalImages * 2 / 3).floor();
        
        complaintImages = ComplaintImages(
          tenantUploaded: [] ,
          technicianUploaded: [] ,
          adminUploaded: [] , 
          adminTechnicianUploaded: [],
        );
      } else {
        complaintImages = ComplaintImages(
          tenantUploaded: [],
          adminUploaded: [],
          technicianUploaded: [],
          adminTechnicianUploaded: [],
        );
      }
      
      debugPrint('Applied fallback distribution - Tenant: ${complaintImages.tenantUploaded.length}, Tech: ${complaintImages.technicianUploaded.length}, Admin: ${complaintImages.adminUploaded.length}');
    } else {
      complaintImages = ComplaintImages(
        tenantUploaded: [],
        adminUploaded: [],
        technicianUploaded: [],
        adminTechnicianUploaded: [],
      );
      debugPrint('No images found anywhere - using empty ComplaintImages');
    }

    debugPrint('Final image counts:');
    debugPrint('- Tenant: ${complaintImages.tenantUploaded.length} -> ${complaintImages.tenantUploaded}');
    debugPrint('- Admin: ${complaintImages.adminUploaded.length} -> ${complaintImages.adminUploaded}');
    debugPrint('- Technician: ${complaintImages.technicianUploaded.length} -> ${complaintImages.technicianUploaded}');
    debugPrint('- Admin/Technician: ${complaintImages.adminTechnicianUploaded.length} -> ${complaintImages.adminTechnicianUploaded}');
    debugPrint('=== END IMAGES INITIALIZATION ===');
    
    _buildTimelineSteps();
  }

  bool _hasAnyImages() {
    debugPrint('=== CHECKING FOR ANY IMAGES ===');
    debugPrint('Tenant images: ${complaintImages.tenantUploaded}');
    debugPrint('Admin images: ${complaintImages.adminUploaded}');
    debugPrint('Technician images: ${complaintImages.technicianUploaded}');
    debugPrint('Admin/Technician images: ${complaintImages.adminTechnicianUploaded}');
    
    final tenantCount = complaintImages.tenantUploaded.length;
    final adminCount = complaintImages.adminUploaded.length;
    final technicianCount = complaintImages.technicianUploaded.length;
    final adminTechnicianCount = complaintImages.adminTechnicianUploaded.length;
    
    debugPrint('Image counts - Tenant: $tenantCount, Admin: $adminCount, Technician: $technicianCount, Admin/Tech: $adminTechnicianCount');
    
    final hasAny = tenantCount > 0 || adminCount > 0 || technicianCount > 0 || adminTechnicianCount > 0;
    debugPrint('Has any images: $hasAny');
    debugPrint('=== END CHECKING FOR ANY IMAGES ===');
    
    return hasAny;
  }

  void _debugComplaintStructure() {
    final complaint = widget.complaint;
    if (complaint == null) {
      debugPrint('Complaint is null');
      return;
    }

    debugPrint('=== FULL COMPLAINT STRUCTURE DEBUG ===');
    
    final json = complaint.toJson();
    debugPrint('Full complaint JSON keys: ${json.keys.toList()}');
    
    debugPrint('Direct assignedTechnicians: ${json['assigned_technicians']}');
    debugPrint('Property assignedTechnicians: ${json['property']?['assigned_technicians']}');
    debugPrint('Has property key: ${json.containsKey('property')}');
    
    if (json['property'] != null) {
      final property = json['property'] as Map<String, dynamic>;
      debugPrint('Property keys: ${property.keys.toList()}');
      debugPrint('Property assigned_technicians: ${property['assigned_technicians']}');
    }
    
    debugPrint('Complaint assignedTechnicians length: ${complaint.assignedTechnicians.length}');
    if (complaint.assignedTechnicians.isNotEmpty) {
      for (int i = 0; i < complaint.assignedTechnicians.length; i++) {
        final tech = complaint.assignedTechnicians[i];
        debugPrint('Technician $i:');
        debugPrint('  - ID: "${tech.technicianId}"');
        debugPrint('  - Name: "${tech.name}"');
        debugPrint('  - Phone: "${tech.phone}"');
        debugPrint('  - Email: "${tech.email}"');
        debugPrint('  - Photo: "${tech.photo}"');
        debugPrint('  - AssignedAt: "${tech.assignedAt}"');
      }
    } else {
      debugPrint('No technicians found in complaint.assignedTechnicians');
    }
    
    debugPrint('=== END FULL COMPLAINT STRUCTURE DEBUG ===');
  }

  void _buildTimelineSteps() {
    final complaint = widget.complaint;
    if (complaint == null) {
      debugPrint('Cannot build timeline - complaint is null');
      return;
    }

    debugPrint('=== BUILDING TIMELINE STEPS ===');
    timelineSteps = [];
    
    // Step 1: Complaint Submitted
    timelineSteps.add(TimelineStep(
      title: 'Complaint Submitted',
      subtitle: 'Your complaint has been registered',
      date: complaint.date,
      status: TimelineStepStatus.completed,
      icon: HugeIcons.strokeRoundedFileAdd,
      details: [
        'Complaint ID: ${complaint.complaintNumber}',
        'Category: ${complaint.category}',
        if (complaint.createdBy != null) 'Created by: ${complaint.createdBy!.name}',
      ],
    ));
    debugPrint('Added complaint submitted step');

    // Step 2: Admin Review (if applicable)
    if (complaint.addedByAdmin || complaint.lastUpdatedByAdmin?.isNotEmpty == true) {
      timelineSteps.add(TimelineStep(
        title: 'Admin Review',
        subtitle: complaint.addedByAdmin ? 'Added by admin' : 'Reviewed by admin',
        date: complaint.lastUpdatedByAdmin ?? complaint.date,
        status: TimelineStepStatus.completed,
        icon: HugeIcons.strokeRoundedAbacus,
        details: [
          if (complaint.addedByAdmin) 'Complaint was created by admin',
          if (complaint.lastUpdatedByAdmin?.isNotEmpty == true) 
            'Last updated: ${DateFormatter.formatTo12Hour(complaint.lastUpdatedByAdmin!)}',
          if (complaint.replyByAdmin?.isNotEmpty == true) 
            'Admin Reply: ${complaint.replyByAdmin!}',
        ],
      ));
      debugPrint('Added admin review step');
    }

    // Step 3: Technician Assignment (with enhanced debugging)
    debugPrint('Checking technician assignment...');
    debugPrint('Technicians count: ${complaint.assignedTechnicians.length}');
    
    if (complaint.assignedTechnicians.isNotEmpty) {
      final tech = complaint.assignedTechnicians.first;
      debugPrint('Creating technician step for: ${tech.name}');
      debugPrint('Technician data - Name: "${tech.name}", Phone: "${tech.phone}", Email: "${tech.email}"');
      
      if (tech.name.isNotEmpty || tech.phone.isNotEmpty || tech.email.isNotEmpty) {
        final techStep = TimelineStep(
          title: 'Technician Assigned',
          subtitle: 'A technician has been assigned to your complaint',
          date: tech.assignedAt.isNotEmpty ? tech.assignedAt : complaint.date,
          status: TimelineStepStatus.completed,
          icon: HugeIcons.strokeRoundedUserSettings01,
          details: [
            if (tech.name.isNotEmpty) 'Technician: ${tech.name}',
            if (tech.phone.isNotEmpty) 'Contact: ${tech.phone}',
            if (tech.email.isNotEmpty) 'Email: ${tech.email}',
          ],
          technician: tech,
        );
        
        timelineSteps.add(techStep);
        debugPrint('Successfully added technician timeline step');
        debugPrint('Step details: ${techStep.details}');
        debugPrint('Step has technician: ${techStep.technician != null}');
      } else {
        debugPrint('Technician has no meaningful data - skipping step');
      }
    } else {
      debugPrint('No technicians assigned - skipping technician step');
    }

    // Step 4: Work In Progress
    final currentStatus = complaint.status.toLowerCase();
    bool hasWorkStarted = currentStatus.contains('progress') || 
                         currentStatus.contains('assigned') || 
                         complaint.replyByTechnician?.isNotEmpty == true;
    
    if (hasWorkStarted) {
      List<String> workDetails = [
        'Status: ${complaint.statusText.en}',
      ];
      
      if (complaint.replyByTechnician?.isNotEmpty == true && 
          complaint.replyByTechnician != "No reply from technician") {
        workDetails.add('Technician Update: ${complaint.replyByTechnician!}');
      }
      
      timelineSteps.add(TimelineStep(
        title: 'Work In Progress',
        subtitle: 'Technician is working on your complaint',
        date: complaint.lastUpdated ?? complaint.date,
        status: currentStatus.contains('completed') || currentStatus.contains('resolved') 
                ? TimelineStepStatus.completed 
                : TimelineStepStatus.current,
        icon: HugeIcons.strokeRoundedSettings02,
        details: workDetails,
      ));
      debugPrint('Added work in progress step');
    }

    // Step 5: Payment (if applicable)
   if (complaint.amountPaid != null && complaint.amountPaid!.isNotEmpty) {
      final amount = double.tryParse(complaint.amountPaid!) ?? 0;
      if (amount > 0) {
        final isPaid = (complaint.amountPaidStatus?.toLowerCase().contains('paid') ?? false);
        final paymentDate = complaint.lastUpdated ?? complaint.date;
        
        timelineSteps.add(TimelineStep(
          title: 'Payment',
          subtitle: isPaid ? 'Payment completed' : 'Payment pending',
          date: paymentDate,
          status: isPaid ? TimelineStepStatus.completed : TimelineStepStatus.pending,
          icon: HugeIcons.strokeRoundedCreditCard,
          details: [
            'Amount: ${amount.toStringAsFixed(2)}',
            'Status: ${complaint.amountPaidStatus ?? 'Pending'}',
            if (paymentDate.isNotEmpty) 
              'Processed: ${DateFormatter.formatTo12Hour(paymentDate)}',
          ],
        ));
        debugPrint('Payment step added with amount: $amount');
      } else {
        debugPrint('Payment amount is zero or invalid: ${complaint.amountPaid}');
      }
    } else {
      debugPrint('''
        No valid payment data found:
        amountPaid: ${complaint.amountPaid}
        amountPaidStatus: ${complaint.amountPaidStatus}
      ''');
    }

    // Step 6: Resolution
    final isCompleted = currentStatus.contains('completed') || currentStatus.contains('resolved');
    List<String> resolutionDetails = [];
    
    if (isCompleted) {
      resolutionDetails.add('Completed successfully');
    }
    
    if (complaint.replyByAdmin?.isNotEmpty == true && 
        complaint.replyByAdmin != "No reply from admin") {
      resolutionDetails.add('Admin Note: ${complaint.replyByAdmin!}');
    }
    
    timelineSteps.add(TimelineStep(
      title: 'Resolution',
      subtitle: isCompleted ? 'Complaint resolved successfully' : 'Awaiting resolution',
      date: isCompleted ? (complaint.lastUpdated ?? complaint.date) : '',
      status: isCompleted ? TimelineStepStatus.completed : TimelineStepStatus.pending,
      icon: HugeIcons.strokeRoundedCheckmarkCircle01,
      details: resolutionDetails,
    ));
    debugPrint('Added resolution step');
    
    debugPrint('=== TIMELINE BUILDING COMPLETE ===');
    debugPrint('Total steps created: ${timelineSteps.length}');
    
    for (int i = 0; i < timelineSteps.length; i++) {
      final step = timelineSteps[i];
      if (step.technician != null) {
        debugPrint('Step $i (${step.title}) has technician: ${step.technician!.name}');
      }
    }
  }

  void _debugImageParsing() {
    final complaint = widget.complaint;
    if (complaint == null) return;

    debugPrint('=== DETAILED IMAGE DEBUG ===');
    
    final json = complaint.toJson();
    debugPrint('Raw complaint JSON image-related keys:');
    json.forEach((key, value) {
      if (key.toLowerCase().contains('image') || key.toLowerCase().contains('photo') || key.toLowerCase().contains('attachment')) {
        debugPrint('  - $key: $value (${value.runtimeType})');
      }
    });
    
    debugPrint('ComplaintImages structure:');
    debugPrint('  - tenantUploaded: ${complaint.complaintImages.tenantUploaded}');
    debugPrint('  - adminUploaded: ${complaint.complaintImages.adminUploaded}');
    debugPrint('  - technicianUploaded: ${complaint.complaintImages.technicianUploaded}');
    debugPrint('  - adminTechnicianUploaded: ${complaint.complaintImages.adminTechnicianUploaded}');
    
    debugPrint('Direct images: ${complaint.complaintImages}');
    
    if (json['property'] is Map) {
      final property = json['property'] as Map;
      debugPrint('Property level images: ${property['images']}');
      debugPrint('Property level attachments: ${property['attachments']}');
    }
    
    debugPrint('=== END DETAILED IMAGE DEBUG ===');
  }

  Widget _buildRepliesSection() {
    final complaint = widget.complaint;
    if (complaint == null) return SizedBox.shrink();

    final hasTechnicianReply = complaint.replyByTechnician?.isNotEmpty == true && 
                              complaint.replyByTechnician != "No reply from technician";
    final hasAdminReply = complaint.replyByAdmin?.isNotEmpty == true && 
                         complaint.replyByAdmin != "No reply from admin";

    if (!hasTechnicianReply && !hasAdminReply) {
      return SizedBox.shrink();
    }

    return _buildSection(
      title: "Updates & Replies",
      icon: HugeIcons.strokeRoundedMessage01,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTechnicianReply) ...[
            Container(
              padding: EdgeInsets.all(screenWidth2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(HugeIcons.strokeRoundedUserSettings01, 
                           size: 16, color: Colors.blue),
                      SizedBox(width: Get.width * 0.02),
                      CustomTextWidget(
                        title: "Technician Update",
                        fontSize: Get.height * 0.014,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight05),
                  CustomTextWidget(
                    title: complaint.replyByTechnician!,
                    fontSize: Get.height * 0.013,
                    fontWeight: FontWeight.w400,
                    color: AppColors.black600,
                    maxLines: 10,
                  ),
                ],
              ),
            ),
            if (hasAdminReply) SizedBox(height: screenHeight1),
          ],
          if (hasAdminReply) ...[
            Container(
              padding: EdgeInsets.all(screenWidth2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(HugeIcons.strokeRoundedAbacus, 
                           size: 16, color: Colors.green),
                      SizedBox(width: Get.width * 0.02),
                      CustomTextWidget(
                        title: "Admin Reply",
                        fontSize: Get.height * 0.014,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight05),
                  CustomTextWidget(
                    title: complaint.replyByAdmin!,
                    fontSize: Get.height * 0.013,
                    fontWeight: FontWeight.w400,
                    color: AppColors.black600,
                    maxLines: 10,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // NEW: Assignment Information Section
  Widget _buildAssignmentSection() {
    final complaint = widget.complaint;
    if (complaint == null || !complaint.isAssigned) return SizedBox.shrink();

    return _buildSection(
      title: "Assignment Information",
      icon: HugeIcons.strokeRoundedUserCheck01,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow("Assignment Status", complaint.assignmentStatus.displayName),
          if (complaint.assignedTechnicianId?.isNotEmpty == true)
            _buildInfoRow("Assigned Technician ID", complaint.assignedTechnicianId!),
          if (complaint.assignedTechnicianName?.isNotEmpty == true)
            _buildInfoRow("Assigned Technician", complaint.assignedTechnicianName!),
          if (complaint.assignedAt != null)
            _buildInfoRow("Assigned At", DateFormatter.formatTo12Hour(complaint.assignedAt!.toIso8601String())),
          if (complaint.assignedTechnicians.isNotEmpty) ...[
            SizedBox(height: screenHeight1),
            CustomTextWidget(
              title: "All Assigned Technicians:",
              fontSize: Get.height * 0.014,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
            SizedBox(height: screenHeight05),
            ...complaint.assignedTechnicians.map((tech) => Container(
              margin: EdgeInsets.only(bottom: screenHeight05),
              padding: EdgeInsets.all(screenWidth1),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tech.name.isNotEmpty) 
                    _buildInfoRow("Name", tech.name),
                  if (tech.email.isNotEmpty) 
                    _buildInfoRow("Email", tech.email),
                  if (tech.phone.isNotEmpty) 
                    _buildInfoRow("Phone", tech.phone),
                  if (tech.assignedAt.isNotEmpty) 
                    _buildInfoRow("Assigned At", DateFormatter.formatTo12Hour(tech.assignedAt)),
                ],
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  // NEW: Payment Information Section
  Widget _buildPaymentSection() {
    final complaint = widget.complaint;
    if (complaint == null) return SizedBox.shrink();

    debugPrint('=== PAYMENT SECTION DEBUG ===');
    debugPrint('Amount Paid: "${complaint.amountPaid}"');
    debugPrint('Amount Paid is null: ${complaint.amountPaid == null}');
    debugPrint('Amount Paid is empty: ${complaint.amountPaid?.isEmpty}');
    debugPrint('Payment Status: "${complaint.amountPaidStatus}"');
    debugPrint('Payment Status is null: ${complaint.amountPaidStatus == null}');
    debugPrint('Payment Status is empty: ${complaint.amountPaidStatus?.isEmpty}');
    
    // Check if we have any payment-related information to display
    final hasAmountPaid = complaint.amountPaid?.isNotEmpty == true;
    final hasPaymentStatus = complaint.amountPaidStatus?.isNotEmpty == true;
    
    debugPrint('Has Amount Paid: $hasAmountPaid');
    debugPrint('Has Payment Status: $hasPaymentStatus');
    
    // Show payment section if there's ANY payment data OR if this is for testing
    // You can change this condition based on your needs
    final shouldShowPaymentSection = hasAmountPaid || hasPaymentStatus || true; // Change 'true' to 'false' to hide when no data
    
    debugPrint('Should show payment section: $shouldShowPaymentSection');
    
    if (!shouldShowPaymentSection) {
      debugPrint('Hiding payment section - no payment information found');
      debugPrint('=== END PAYMENT SECTION DEBUG ===');
      return SizedBox.shrink();
    }

    // Parse amount safely
    final amount = hasAmountPaid ? (double.tryParse(complaint.amountPaid!) ?? 0) : 0;
    final isPaid = complaint.amountPaidStatus?.toLowerCase().contains('paid') ?? false;

    debugPrint('Parsed Amount: $amount');
    debugPrint('Is Paid: $isPaid');
    debugPrint('Showing payment section');
    debugPrint('=== END PAYMENT SECTION DEBUG ===');

    return _buildSection(
      title: "Payment Information",
      icon: HugeIcons.strokeRoundedCreditCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasAmountPaid) 
            _buildInfoRow("Amount", "${amount.toStringAsFixed(2)} SAR")
          else
            _buildInfoRow("Amount", "Not specified"),
          
          if (hasPaymentStatus)
            _buildInfoRow("Payment Status", complaint.amountPaidStatus!)
          else
            _buildInfoRow("Payment Status", "No status available"),
          
          Container(
            margin: EdgeInsets.only(top: screenHeight05),
            padding: EdgeInsets.symmetric(
              horizontal: Get.width * 0.03,
              vertical: Get.height * 0.005,
            ),
            decoration: BoxDecoration(
              color: (isPaid ? Colors.green : Colors.orange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: CustomTextWidget(
              title: isPaid ? "Payment Completed" : "Payment Pending",
              fontSize: Get.height * 0.012,
              fontWeight: FontWeight.w600,
              color: isPaid ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Timeline Events Section (from the model's timeline field)
  Widget _buildTimelineEventsSection() {
    final complaint = widget.complaint;
    if (complaint == null || complaint.timeline.isEmpty) return SizedBox.shrink();

    return _buildSection(
      title: "Detailed Timeline Events",
      icon: HugeIcons.strokeRoundedClock01,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: complaint.timeline.map((event) => Container(
          margin: EdgeInsets.only(bottom: screenHeight1),
          padding: EdgeInsets.all(screenWidth2),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomTextWidget(
                    title: event.type.toUpperCase(),
                    fontSize: Get.height * 0.013,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                  CustomTextWidget(
                    title: event.formattedTimestamp,
                    fontSize: Get.height * 0.011,
                    fontWeight: FontWeight.w400,
                    color: AppColors.black600,
                  ),
                ],
              ),
              if (event.message?.isNotEmpty == true) ...[
                SizedBox(height: screenHeight05),
                CustomTextWidget(
                  title: event.message!,
                  fontSize: Get.height * 0.013,
                  fontWeight: FontWeight.w400,
                  color: AppColors.black600,
                  maxLines: 3,
                ),
              ],
              if (event.oldStatus?.isNotEmpty == true || event.newStatus?.isNotEmpty == true) ...[
                SizedBox(height: screenHeight05),
                Row(
                  children: [
                    if (event.oldStatus?.isNotEmpty == true) ...[
                      CustomTextWidget(
                        title: "From: ${event.oldStatus}",
                        fontSize: Get.height * 0.012,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                      SizedBox(width: Get.width * 0.02),
                    ],
                    if (event.newStatus?.isNotEmpty == true)
                      CustomTextWidget(
                        title: "To: ${event.newStatus}",
                        fontSize: Get.height * 0.012,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                  ],
                ),
              ],
              if (event.by != null) ...[
                SizedBox(height: screenHeight05),
                CustomTextWidget(
                  title: "By: ${event.by!.name} (${event.by!.type})",
                  fontSize: Get.height * 0.012,
                  fontWeight: FontWeight.w400,
                  color: AppColors.black600,
                ),
              ],
            ],
          ),
        )).toList(),
      ),
    );
  }

  // NEW: System Information Section
  Widget _buildSystemInfoSection() {
    final complaint = widget.complaint;
    if (complaint == null) return SizedBox.shrink();

    return _buildSection(
      title: "System Information",
      icon: HugeIcons.strokeRoundedInformationCircle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow("Complaint ID", complaint.complaintId),
          _buildInfoRow("Flat ID", complaint.flatnoId),
          if (complaint.lastUpdated?.isNotEmpty == true)
            _buildInfoRow("Last Updated", DateFormatter.formatTo12Hour(complaint.lastUpdated!)),
          if (complaint.lastUpdatedByAdmin?.isNotEmpty == true)
            _buildInfoRow("Last Updated by Admin", DateFormatter.formatTo12Hour(complaint.lastUpdatedByAdmin!)),
          _buildInfoRow("Added by Admin", complaint.addedByAdmin ? "Yes" : "No"),
          _buildInfoRow("Primary Technician ID", complaint.primaryTechnicianId ?? "Not assigned"),
          _buildInfoRow("Primary Technician Name", complaint.primaryTechnicianName ?? "Not assigned"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomTextWidget(
          title: "Ticket Details",
          fontSize: Get.height * 0.022,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTicketHeader(),
            SizedBox(height: screenHeight2),
            _buildCreatorInfo(),
            SizedBox(height: screenHeight2),
            _buildPropertyDetails(),
            SizedBox(height: screenHeight2),
            _buildIssueDetails(),
            SizedBox(height: screenHeight2),
            _buildSystemInfoSection(), // NEW: System information (moved here)
            SizedBox(height: screenHeight2),
            _buildAssignmentSection(), // NEW: Assignment information
            SizedBox(height: screenHeight2),
            _buildPaymentSection(), // NEW: Payment information
            SizedBox(height: screenHeight2),
            _buildRepliesSection(),
            SizedBox(height: screenHeight2),
            _buildFlipkartStyleTimeline(),
            SizedBox(height: screenHeight2),
            _buildTimelineEventsSection(), // NEW: Detailed timeline events
            SizedBox(height: screenHeight2),
            _buildImagesSection(),
            SizedBox(height: screenHeight * 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildFlipkartStyleTimeline() {
    return Container(
      padding: EdgeInsets.all(screenWidth2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(HugeIcons.strokeRoundedTimeSchedule, size: 20, color: AppColors.warning),
              SizedBox(width: Get.width * 0.02),
              CustomTextWidget(
                title: "Complaint Timeline",
                fontSize: Get.height * 0.018,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ],
          ),
          SizedBox(height: screenHeight2),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: timelineSteps.length,
            itemBuilder: (context, index) {
              return _buildTimelineStep(
                timelineSteps[index], 
                index == timelineSteps.length - 1
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(TimelineStep step, bool isLast) {
    Color stepColor = _getStepColor(step.status);
    Color backgroundColor = _getStepBackgroundColor(step.status);
    
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : screenHeight1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: Get.height * 0.035,
                height: Get.height * 0.035,
                decoration: BoxDecoration(
                  color: stepColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: stepColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  step.icon,
                  color: AppColors.white,
                  size: Get.height * 0.02,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: Get.height * 0.06,
                  color: stepColor.withOpacity(0.3),
                  margin: EdgeInsets.symmetric(vertical: Get.height * 0.005),
                ),
            ],
          ),
          
          SizedBox(width: screenWidth2),
          
          Expanded(
            child: Container(
              padding: EdgeInsets.all(screenWidth2),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: stepColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextWidget(
                              title: step.title,
                              fontSize: Get.height * 0.016,
                              fontWeight: FontWeight.w600,
                              color: stepColor,
                            ),
                            SizedBox(height: screenHeight05),
                            CustomTextWidget(
                              title: step.subtitle,
                              fontSize: Get.height * 0.014,
                              fontWeight: FontWeight.w400,
                              color: AppColors.black600,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      if (step.date.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Get.width * 0.02,
                            vertical: Get.height * 0.003,
                          ),
                          decoration: BoxDecoration(
                            color: stepColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: CustomTextWidget(
                            title: DateFormatter.formatTo12Hour(step.date),
                            fontSize: Get.height * 0.011,
                            fontWeight: FontWeight.w500,
                            color: stepColor,
                          ),
                        ),
                    ],
                  ),
                  
                  if (step.details.isNotEmpty) ...[
                    SizedBox(height: screenHeight1),
                    ...step.details.map((detail) => Padding(
                      padding: EdgeInsets.only(bottom: screenHeight05),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            margin: EdgeInsets.only(top: Get.height * 0.008),
                            decoration: BoxDecoration(
                              color: stepColor.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: Get.width * 0.02),
                          Expanded(
                            child: CustomTextWidget(
                              title: detail,
                              fontSize: Get.height * 0.013,
                              fontWeight: FontWeight.w400,
                              color: AppColors.black600,
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                  
                  if (step.technician != null) ...[
                    SizedBox(height: screenHeight1),
                    Container(
                      padding: EdgeInsets.all(screenWidth2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: Get.height * 0.025,
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            backgroundImage: step.technician!.photo?.isNotEmpty == true
                                ? CachedNetworkImageProvider(step.technician!.photo!)
                                : null,
                            child: step.technician!.photo?.isEmpty != false
                                ? Icon(
                                    HugeIcons.strokeRoundedUser,
                                    color: Colors.blue,
                                    size: Get.height * 0.025,
                                  )
                                : null,
                          ),
                          SizedBox(width: screenWidth1),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomTextWidget(
                                  title: step.technician!.name,
                                  fontSize: Get.height * 0.014,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                                if (step.technician!.phone.isNotEmpty)
                                  CustomTextWidget(
                                    title: "📞 ${step.technician!.phone}",
                                    fontSize: Get.height * 0.012,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.black600,
                                  ),
                              ],
                            ),
                          ),
                          if (step.technician!.phone.isNotEmpty)
                            IconButton(
                              onPressed: () {
                                // Add call functionality here
                              },
                              icon: Icon(
                                HugeIcons.strokeRoundedCall,
                                color: Colors.green,
                                size: Get.height * 0.02,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStepColor(TimelineStepStatus status) {
    switch (status) {
      case TimelineStepStatus.completed:
        return Colors.green;
      case TimelineStepStatus.current:
        return Colors.blue;
      case TimelineStepStatus.pending:
        return AppColors.grey;
    }
  }

  Color _getStepBackgroundColor(TimelineStepStatus status) {
    switch (status) {
      case TimelineStepStatus.completed:
        return Colors.green.withOpacity(0.05);
      case TimelineStepStatus.current:
        return Colors.blue.withOpacity(0.05);
      case TimelineStepStatus.pending:
        return AppColors.grey.withOpacity(0.05);
    }
  }

  Widget _buildTicketHeader() {
    final complaint = widget.complaint;
    if (complaint == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(screenWidth2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomTextWidget(
                  title: "Ticket: ${complaint.complaintNumber}",
                  fontSize: Get.height * 0.018,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              _buildStatusChip(complaint.statusText.en),
            ],
          ),
          SizedBox(height: screenHeight1),
          if (complaint.addedByAdmin)
            Container(
              margin: EdgeInsets.only(top: screenHeight05),
              padding: EdgeInsets.symmetric(
                horizontal: Get.width * 0.03,
                vertical: Get.height * 0.005,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: CustomTextWidget(
                title: "Added by Admin",
                fontSize: Get.height * 0.012,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreatorInfo() {
    final creator = widget.complaint?.createdBy;
    if (creator == null) return SizedBox.shrink();

    return _buildSection(
      title: "Created By",
      icon: HugeIcons.strokeRoundedUser,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow("Name", creator.name),
          if (creator.email?.isNotEmpty == true)
            _buildInfoRow("Email", creator.email!),
          if (creator.phone?.isNotEmpty == true)
            _buildInfoRow("Phone", creator.phone!),
          _buildInfoRow("User Type", creator.type),
          if (creator.uid?.isNotEmpty == true)
            _buildInfoRow("User ID", creator.uid!),
          if (creator.role?.isNotEmpty == true)
            _buildInfoRow("Role", creator.role!),
        ],
      ),
    );
  }

  Widget _buildPropertyDetails() {
    final complaint = widget.complaint;
    if (complaint == null) return SizedBox.shrink();

    return _buildSection(
      title: "Property Details",
      icon: HugeIcons.strokeRoundedHome01,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow("Property Name", complaint.propertyName),
          _buildInfoRow("Unit Number", complaint.unitNumber),
          if (complaint.unitType.isNotEmpty)
            _buildInfoRow("Unit Type", complaint.unitType),
          _buildInfoRow("Full Address", complaint.fullAddress),
          if (complaint.flatnoId.isNotEmpty)
            _buildInfoRow("Flat ID", complaint.flatnoId),
        ],
      ),
    );
  }

  Widget _buildIssueDetails() {
    final complaint = widget.complaint;
    if (complaint == null) return SizedBox.shrink();

    return _buildSection(
      title: "Issue Details",
      icon: HugeIcons.strokeRoundedAlert01,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow("Category", complaint.category),
          _buildInfoRow("Subcategory", complaint.subcategory),
          SizedBox(height: screenHeight1),
          CustomTextWidget(
            title: "Description:",
            fontSize: Get.height * 0.014,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
          SizedBox(height: screenHeight05),
          CustomTextWidget(
            title: complaint.description,
            fontSize: Get.height * 0.014,
            fontWeight: FontWeight.w400,
            color: AppColors.black600,
            maxLines: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    debugPrint('=== IMAGE SECTION DEBUG ===');
    debugPrint('Tenant images: ${complaintImages.tenantUploaded.length}');
    debugPrint('Admin images: ${complaintImages.adminUploaded.length}');
    debugPrint('Technician images: ${complaintImages.technicianUploaded.length}');
    debugPrint('Admin/Technician images: ${complaintImages.adminTechnicianUploaded.length}');
    
    if (!_hasAnyImages()) {
      debugPrint('No images found in any category - hiding section');
      return SizedBox.shrink();
    }

    List<Widget> imageCategories = [];

    if (complaintImages.tenantUploaded.isNotEmpty) {
      imageCategories.add(_buildImageCategory("Tenant Uploaded", complaintImages.tenantUploaded, Colors.blue));
      debugPrint('Added tenant images section with ${complaintImages.tenantUploaded.length} images');
    }
    
    if (complaintImages.adminUploaded.isNotEmpty) {
      imageCategories.add(_buildImageCategory("Admin Uploaded", complaintImages.adminUploaded, Colors.green));
      debugPrint('Added admin images section with ${complaintImages.adminUploaded.length} images');
    }
    
    if (complaintImages.technicianUploaded.isNotEmpty) {
      imageCategories.add(_buildImageCategory("Technician Uploaded", complaintImages.technicianUploaded, Colors.orange));
      debugPrint('Added technician images section with ${complaintImages.technicianUploaded.length} images');
    }
    
    if (complaintImages.adminTechnicianUploaded.isNotEmpty) {
      imageCategories.add(_buildImageCategory("Admin/Technician Uploaded", complaintImages.adminTechnicianUploaded, Colors.purple));
      debugPrint('Added admin/technician images section with ${complaintImages.adminTechnicianUploaded.length} images');
    }

    if (imageCategories.isEmpty) {
      return SizedBox.shrink();
    }

    debugPrint('Total image categories to display: ${imageCategories.length}');
    debugPrint('=== END IMAGE SECTION DEBUG ===');

    return _buildSection(
      title: "Attachments",
      icon: HugeIcons.strokeRoundedImage01,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < imageCategories.length; i++) ...[
            imageCategories[i],
            if (i < imageCategories.length - 1) SizedBox(height: screenHeight1),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(screenWidth2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.warning),
              SizedBox(width: Get.width * 0.02),
              CustomTextWidget(
                title: title,
                fontSize: Get.height * 0.018,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ],
          ),
          SizedBox(height: screenHeight1),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: Get.width * 0.3,
            child: CustomTextWidget(
              title: "$label:",
              fontSize: Get.height * 0.014,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          Expanded(
            child: CustomTextWidget(
              title: value,
              fontSize: Get.height * 0.014,
              fontWeight: FontWeight.w400,
              color: AppColors.black600,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case "pending":
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      case "in progress":
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        break;
      case "completed":
        backgroundColor = AppColors.onlineGreen.withOpacity(0.2);
        textColor = AppColors.onlineGreenDark;
        break;
      case "cancelled":
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      default:
        backgroundColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Get.width * 0.03,
        vertical: Get.height * 0.005,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomTextWidget(
        title: status,
        fontSize: Get.height * 0.012,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  Widget _buildImageCategory(String title, List<String> images, Color accentColor) {
    debugPrint('Building image category: $title with ${images.length} images');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: Get.width * 0.02),
            CustomTextWidget(
              title: "$title (${images.length})",
              fontSize: Get.height * 0.015,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ],
        ),
        SizedBox(height: screenHeight1),
        SizedBox(
          height: Get.height * 0.12,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Container(
                width: Get.width * 0.25,
                margin: EdgeInsets.only(right: screenWidth1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: images[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: accentColor.withOpacity(0.1),
                      child: Icon(Icons.image, color: accentColor.withOpacity(0.5)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.red.withOpacity(0.1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red.withOpacity(0.5)),
                          const SizedBox(height: 4),
                          Text(
                            'Load Error',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Timeline data models
class TimelineStep {
  final String title;
  final String subtitle;
  final String date;
  final TimelineStepStatus status;
  final IconData icon;
  final List<String> details;
  final Technician? technician;

  TimelineStep({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.status,
    required this.icon,
    this.details = const [],
    this.technician,
  });
}

enum TimelineStepStatus {
  completed,
  current,
  pending,
}