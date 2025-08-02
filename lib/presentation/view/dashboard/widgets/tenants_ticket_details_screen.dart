import 'package:dar_al_safwa/data/model/ticket_list_response_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  List<TimelineItem> timelineItems = [];
  
  @override
  void initState() {
    super.initState();
    debugPrint('Technician complaint data: ${widget.complaint}');
debugPrint('Images: ${widget.complaint?.complaintImages}');
debugPrint('Direct images: ${widget.complaint?.images}');
debugPrint('Status text: ${widget.complaint?.statusText.en}');

    debugPrint("=== initState ===");
    debugPrint("Received complaint: ${widget.complaint?.complaintNumber}");

    complaintImages = widget.complaint?.complaintImages ?? ComplaintImages();

    debugPrint("Initial complaintImages: $complaintImages");

    if (complaintImages.tenantUploaded.isEmpty &&
        complaintImages.adminUploaded.isEmpty &&
        complaintImages.technicianUploaded.isEmpty &&
        complaintImages.adminTechnicianUploaded.isEmpty) {
      final directImages = widget.complaint?.images ?? [];
      if (directImages.isNotEmpty) {
        complaintImages = ComplaintImages(tenantUploaded: directImages);
        debugPrint("Fallback to direct complaint images: $directImages");
      }
    }

    debugPrint('Final images to display:');
    debugPrint('Tenant: ${complaintImages.tenantUploaded}');
    debugPrint('Admin: ${complaintImages.adminUploaded}');
    debugPrint('Technician: ${complaintImages.technicianUploaded}');
    debugPrint('Admin/Technician: ${complaintImages.adminTechnicianUploaded}');

    _initializeTimeline();
  }

  void _initializeTimeline() {
    final String lastUpdated = widget.complaint?.date ?? '';

    timelineItems = [
      TimelineItem(
        title: 'Submitted',
        date: lastUpdated,
        status: TimelineStatus.completed,
        icon: Icons.description_outlined,
      ),
      TimelineItem(
        title: 'Assigned',
        date: lastUpdated,
        status: TimelineStatus.completed,
        icon: Icons.person_outline,
      ),
      TimelineItem(
        title: 'Technician',
        date: lastUpdated,
        status: TimelineStatus.current,
        icon: Icons.build_outlined,
      ),
      TimelineItem(
        title: 'Resolved',
        date: lastUpdated,
        status: TimelineStatus.pending,
        icon: Icons.check_circle_outline,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.complaint != null) {
      debugPrint("Complaint Details: ${widget.complaint!.complaintNumber}");
    }

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
            _buildIssueDescriptionSection(),
            SizedBox(height: screenHeight2),
            _buildRepliesSection(),
            SizedBox(height: screenHeight2),
            if (complaintImages.tenantUploaded.isNotEmpty || 
                complaintImages.adminUploaded.isNotEmpty ||
                complaintImages.technicianUploaded.isNotEmpty ||
                complaintImages.adminTechnicianUploaded.isNotEmpty) 
              _buildImagesSection(),
            SizedBox(height: screenHeight2),
            _buildTimelineSection(),
            SizedBox(height: screenHeight * 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketHeader() {
    final String complaintNumber = widget.complaint?.complaintNumber ?? "N/A";
    final String category = widget.complaint?.category ?? "N/A";
    final String subcategory = widget.complaint?.subcategory ?? "N/A";
    final String propertyName = widget.complaint?.propertyName ?? "N/A";
    final String unitNumber = widget.complaint?.unitNumber ?? "N/A";
    final String fullAddress = widget.complaint?.fullAddress ?? "N/A";
    final String lastUpdated = widget.complaint?.date ?? "N/A";
    final String? complaintStatusText = widget.complaint?.statusText.en;

    debugPrint("Building ticket header with:");
    debugPrint("Complaint Number: $complaintNumber");
    debugPrint("Category: $category | Subcategory: $subcategory");
    debugPrint("Property: $propertyName | Unit: $unitNumber");
    debugPrint("Address: $fullAddress | Last Updated: $lastUpdated");

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
          CustomTextWidget(
            title: "Ticket No: $complaintNumber",
            fontSize: Get.height * 0.016,
            fontWeight: FontWeight.w600,
            color: AppColors.black800,
          ),
          SizedBox(height: screenHeight05),
          CustomTextWidget(
            title: "Category: $category",
            fontSize: Get.height * 0.018,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
          ),
          CustomTextWidget(
            title: "Subcategory: $subcategory",
            fontSize: Get.height * 0.016,
            fontWeight: FontWeight.w400,
            color: AppColors.black600,
          ),
          SizedBox(height: screenHeight05),
          CustomTextWidget(
            title: "Property: $propertyName",
            fontSize: Get.height * 0.016,
            fontWeight: FontWeight.w400,
            color: AppColors.black600,
          ),
          CustomTextWidget(
            title: "Unit: $unitNumber",
            fontSize: Get.height * 0.016,
            fontWeight: FontWeight.w400,
            color: AppColors.black600,
          ),
          CustomTextWidget(
            title: "Address: $fullAddress",
            fontSize: Get.height * 0.016,
            fontWeight: FontWeight.w400,
            color: AppColors.black600,
          ),
          SizedBox(height: screenHeight1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomTextWidget(
                title: "Updated on $lastUpdated",
                fontSize: Get.height * 0.014,
                fontWeight: FontWeight.w400,
                color: AppColors.black500,
              ),
              if (complaintStatusText != null)
                _buildComplaintStatusChip(complaintStatusText),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRepliesSection() {
    final replyByTechnician = widget.complaint?.replyByTechnician ?? "No reply from technician";
    final replyByAdmin = widget.complaint?.replyByAdmin ?? "No reply from admin";
    debugPrint("Technician reply: $replyByTechnician");
    debugPrint("Admin reply: $replyByAdmin");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: "Replies",
          fontSize: Get.height * 0.018,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        SizedBox(height: screenHeight1),
        CustomTextWidget(
          title: "Technician: $replyByTechnician",
          fontSize: Get.height * 0.014,
          fontWeight: FontWeight.w400,
          color: AppColors.black600,
        ),
        SizedBox(height: screenHeight05),
        CustomTextWidget(
          title: "Admin: $replyByAdmin",
          fontSize: Get.height * 0.014,
          fontWeight: FontWeight.w400,
          color: AppColors.black600,
        ),
      ],
    );
  }

  Widget _buildComplaintStatusChip(String statusText) {
    Color backgroundColor;
    Color textColor;

    switch (statusText.toLowerCase()) {
      case "pending":
        backgroundColor = AppColors.primaryColor.withOpacity(0.1);
        textColor = AppColors.primaryColor;
        break;
      case "completed":
        backgroundColor = AppColors.onlineGreen.withOpacity(0.2);
        textColor = AppColors.onlineGreenDark;
        break;
      default:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.015,
        vertical: screenHeight * 0.005,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomTextWidget(
        title: statusText,
        fontSize: Get.height * 0.012,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  Widget _buildIssueDescriptionSection() {
    final description = widget.complaint?.description ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: "Issue Description",
          fontSize: Get.height * 0.018,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        SizedBox(height: screenHeight1),
        CustomTextWidget(
          title: description,
          fontSize: Get.height * 0.014,
          fontWeight: FontWeight.w400,
          color: AppColors.black600,
          maxLines: 10,
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    final hasAnyImages = complaintImages.tenantUploaded.isNotEmpty ||
                       complaintImages.adminUploaded.isNotEmpty ||
                       complaintImages.technicianUploaded.isNotEmpty ||
                       complaintImages.adminTechnicianUploaded.isNotEmpty;

    if (!hasAnyImages) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: "Attachments",
          fontSize: Get.height * 0.018,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        SizedBox(height: screenHeight1),
        if (complaintImages.tenantUploaded.isNotEmpty)
          _buildImageCategory("Tenant Uploaded", complaintImages.tenantUploaded),
        if (complaintImages.adminUploaded.isNotEmpty)
          _buildImageCategory("Admin Uploaded", complaintImages.adminUploaded),
        if (complaintImages.technicianUploaded.isNotEmpty)
          _buildImageCategory("Technician Uploaded", complaintImages.technicianUploaded),
        if (complaintImages.adminTechnicianUploaded.isNotEmpty)
          _buildImageCategory("Admin/Technician Uploaded", complaintImages.adminTechnicianUploaded),
      ],
    );
  }

  Widget _buildImageCategory(String title, List<String> images) {
    debugPrint("Rendering image category '$title' with ${images.length} images");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: screenHeight1),
        CustomTextWidget(
          title: title,
          fontSize: Get.height * 0.018,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        SizedBox(height: screenHeight1),
        SizedBox(
          height: Get.height * 0.15,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              final url = images[index];
              return Container(
                width: Get.width * 0.30,
                margin: EdgeInsets.only(right: screenWidth1),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(url), 
                    fit: BoxFit.cover
                  ),
                  color: AppColors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.grey.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: "Timeline",
          fontSize: Get.height * 0.018,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        SizedBox(height: screenHeight1),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: timelineItems.length,
          itemBuilder: (context, index) {
            return _buildTimelineItem(
              timelineItems[index],
              index == timelineItems.length - 1,
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimelineItem(TimelineItem item, bool isLast) {
    debugPrint("Timeline item: ${item.title} - ${item.date} - ${item.status}");

    Color iconColor;
    Color lineColor;

    switch (item.status) {
      case TimelineStatus.completed:
        iconColor = AppColors.onlineGreenDark;
        lineColor = AppColors.onlineGreenDark;
        break;
      case TimelineStatus.current:
        iconColor = AppColors.secondaryColor;
        lineColor = AppColors.secondaryColor;
        break;
      case TimelineStatus.pending:
        iconColor = AppColors.grey;
        lineColor = AppColors.grey.withValues(alpha: 0.3);
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: Get.height * 0.03,
              height: Get.height * 0.03,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                color: AppColors.white,
                size: Get.height * 0.018,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: Get.height * 0.05,
                color: lineColor,
              ),
          ],
        ),
        SizedBox(width: screenWidth1),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: screenHeight1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextWidget(
                  title: item.title,
                  fontSize: Get.height * 0.016,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                SizedBox(height: screenHeight05),
                CustomTextWidget(
                  title: item.date,
                  fontSize: Get.height * 0.014,
                  fontWeight: FontWeight.w400,
                  color: AppColors.black500,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TimelineItem {
  final String title;
  final String date;
  final TimelineStatus status;
  final IconData icon;

  TimelineItem({
    required this.title,
    required this.date,
    required this.status,
    required this.icon,
  });
}

enum TimelineStatus { completed, current, pending }