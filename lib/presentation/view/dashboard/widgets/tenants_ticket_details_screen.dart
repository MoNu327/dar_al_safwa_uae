import 'package:dar_al_safwa/data/model/technican_ticket_view_model.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_formfield_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/notification_navigation_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_text_widget.dart';
import 'tenants_tickets_list_widget.dart';

class TicketDetailsScreen extends StatefulWidget {
  final TicketModel? ticket;

  const TicketDetailsScreen({
    super.key,
    required this.ticket,
  });

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  late List<String> images;
  List<TimelineItem> timelineItems = [];

  @override
  void initState() {
    super.initState();
    images = [
      ...widget.ticket?.images ?? [],
      // ...widget.ticket?.images.technicianImages ?? [],
    ];
    _initializeTimeline();
  }

  void _initializeTimeline() {
    // This can be replaced by dynamic timeline data from API
    timelineItems = [
      TimelineItem(
        title: 'Submitted',
        date: widget.ticket!.lastUpdated,
        status: TimelineStatus.completed,
        icon: Icons.description_outlined,
      ),
      TimelineItem(
        title: 'Assigned',
        date: widget.ticket!.lastUpdated,
        status: TimelineStatus.completed,
        icon: Icons.person_outline,
      ),
      TimelineItem(
        title: 'Technician',
        date: widget.ticket!.lastUpdated,
        status: TimelineStatus.current,
        icon: Icons.build_outlined,
      ),
      TimelineItem(
        title: 'Resolved',
        date: widget.ticket!.lastUpdated,
        status: TimelineStatus.pending,
        icon: Icons.check_circle_outline,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Ticket Details: ${widget.ticket!.toJson()}");
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
            // _buildPropertyDetails(),
            SizedBox(height: screenHeight2),
            _buildIssueDescriptionSection(),
            SizedBox(height: screenHeight2),
            if (images.isNotEmpty) _buildImagesSection(),
            SizedBox(height: screenHeight2),
            _buildTimelineSection(),
            SizedBox(height: screenHeight * 0.1),
          ],
        ),
      ),
    );
  }

  /// -------------------- Ticket Header --------------------
  Widget _buildTicketHeader() {
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
            title: widget.ticket!.complaintNumber,
            fontSize: Get.height * 0.016,
            fontWeight: FontWeight.w600,
            color: AppColors.black800,
          ),
          SizedBox(height: screenHeight05),
          CustomTextWidget(
            title: widget.ticket!.category,
            fontSize: Get.height * 0.020,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            maxLines: 2,
          ),
          SizedBox(height: screenHeight05),
          CustomTextWidget(
            title: widget.ticket!.subcategory,
            fontSize: Get.height * 0.016,
            fontWeight: FontWeight.w400,
            color: AppColors.black600,
          ),
          SizedBox(height: screenHeight1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomTextWidget(
                title: "Updated on ${widget.ticket!.lastUpdated}",
                fontSize: Get.height * 0.014,
                fontWeight: FontWeight.w400,
                color: AppColors.black500,
              ),
              _buildStatusChip(widget.ticket!.status),
            ],
          ),
        ],
      ),
    );
  }

  // /// -------------------- Property Details --------------------
  // Widget _buildPropertyDetails() {
  //   final property = widget.ticket!.property;
  //   return Container(
  //     padding: EdgeInsets.all(screenWidth2),
  //     decoration: BoxDecoration(
  //       color: AppColors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: AppColors.grey.withValues(alpha: 0.1),
  //           blurRadius: 8,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         CustomTextWidget(
  //           title: "Property Details",
  //           fontSize: Get.height * 0.018,
  //           fontWeight: FontWeight.w600,
  //           color: AppColors.black,
  //         ),
  //         SizedBox(height: screenHeight1),
  //         CustomTextWidget(
  //           title: property.title,
  //           fontSize: Get.height * 0.016,
  //           fontWeight: FontWeight.w500,
  //           color: AppColors.black600,
  //         ),
  //         CustomTextWidget(
  //           title: "${property.unitNumber} - ${property.unitType}",
  //           fontSize: Get.height * 0.014,
  //           fontWeight: FontWeight.w400,
  //           color: AppColors.black500,
  //         ),
  //         CustomTextWidget(
  //           title: property.addressFormat,
  //           fontSize: Get.height * 0.014,
  //           fontWeight: FontWeight.w400,
  //           color: AppColors.black500,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// -------------------- Status Chip --------------------
  Widget _buildStatusChip(TicketStatus status) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status) {
      case TicketStatus.pending:
        backgroundColor = AppColors.primaryColor.withOpacity(0.1);
        textColor = AppColors.primaryColor;
        statusText = "Pending";
        break;
      case TicketStatus.rectified:
        backgroundColor = AppColors.onlineGreen.withOpacity(0.1);
        textColor = AppColors.onlineGreenDark;
        statusText = "Rectified";
        break;
      case TicketStatus.inProgress:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        statusText = "In Progress";
        break;
      case TicketStatus.completed:
        backgroundColor = AppColors.onlineGreen.withOpacity(0.2);
        textColor = AppColors.onlineGreenDark;
        statusText = "Completed";
        break;
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

  /// -------------------- Issue Description --------------------
  Widget _buildIssueDescriptionSection() {
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
          title: widget.ticket!.description,
          fontSize: Get.height * 0.014,
          fontWeight: FontWeight.w400,
          color: AppColors.black600,
          maxLines: 10,
        ),
      ],
    );
  }

  /// -------------------- Images Section --------------------
  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: "Images",
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
                  image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
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

  /// -------------------- Timeline Section --------------------
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

// Timeline Item Model
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

// Timeline Status Enum
enum TimelineStatus {
  completed,
  current,
  pending,
}
