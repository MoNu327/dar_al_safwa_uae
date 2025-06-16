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
  final TicketModel ticket;

  const TicketDetailsScreen({
    super.key,
    required this.ticket,
  });

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  List<String> images = [
    'https://images.pexels.com/photos/7327135/pexels-photo-7327135.jpeg?auto=compress&cs=tinysrgb&w=400',
    'https://images.pexels.com/photos/8113574/pexels-photo-8113574.jpeg?auto=compress&cs=tinysrgb&w=400',
    'https://images.pexels.com/photos/8113785/pexels-photo-8113785.jpeg?auto=compress&cs=tinysrgb&w=400',
  ];

  List<TimelineItem> timelineItems = [];

  @override
  void initState() {
    super.initState();
    _initializeTimeline();
  }

  void _initializeTimeline() {
    timelineItems = [
      TimelineItem(
        title: 'Submitted',
        date: 'May 20, 2025, 9:43 AM',
        status: TimelineStatus.completed,
        icon: Icons.description_outlined,
      ),
      TimelineItem(
        title: 'Assigned',
        date: 'May 20, 2025, 11:45 AM',
        status: TimelineStatus.completed,
        icon: Icons.person_outline,
      ),
      TimelineItem(
        title: 'Technician',
        date: 'May 21, 2025, 2:30 PM',
        status: TimelineStatus.current,
        icon: Icons.build_outlined,
      ),
      TimelineItem(
        title: 'Rectified',
        date: 'May 22, 2025, 10:30 AM',
        status: TimelineStatus.pending,
        icon: Icons.check_circle_outline,
      ),
    ];
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
            // Ticket Header
            _buildTicketHeader(),

            SizedBox(height: screenHeight2),

            // Issue Description Section
            _buildIssueDescriptionSection(),

            SizedBox(height: screenHeight2),

            // Images Section
            if (images.isNotEmpty) _buildImagesSection(),

            SizedBox(height: screenHeight2),

            // Timeline Section
            _buildTimelineSection(),

            SizedBox(height: screenHeight * 0.1),
          ],
        ),
      ),
    );
  }

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
          // Ticket ID
          CustomTextWidget(
            title: "#${widget.ticket.id}",
            fontSize: Get.height * 0.016,
            fontWeight: FontWeight.w600,
            color: AppColors.black800,
          ),

          SizedBox(height: screenHeight05),

          // Property Title
          CustomTextWidget(
            title: widget.ticket.title,
            fontSize: Get.height * 0.020,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            maxLines: 2,
          ),

          SizedBox(height: screenHeight05),

          // Issue Title
          CustomTextWidget(
            title: widget.ticket.description,
            fontSize: Get.height * 0.016,
            fontWeight: FontWeight.w400,
            color: AppColors.black600,
          ),

          SizedBox(height: screenHeight1),

          // Date and Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomTextWidget(
                title: "Submitted on ${widget.ticket.submittedDate}",
                fontSize: Get.height * 0.014,
                fontWeight: FontWeight.w400,
                color: AppColors.black500,
              ),
              _buildStatusChip(widget.ticket.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(TicketStatus status) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status) {
      case TicketStatus.pending:
        backgroundColor = AppColors.primaryColor;
        textColor = AppColors.secondaryColor;
        statusText = "Pending";
        break;
      case TicketStatus.rectified:
        backgroundColor = AppColors.onlineGreen.withValues(alpha: 0.1);
        textColor = AppColors.onlineGreenDark;
        statusText = "Rectified";
        break;
      case TicketStatus.inProgress:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        statusText = "In Progress";
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
          title:
              "The kitchen tap is leaking constantly, causing water accumulation on the countertop. This has been ongoing for the past 3 days and is causing inconvenience.",
          fontSize: Get.height * 0.014,
          fontWeight: FontWeight.w400,
          color: AppColors.black600,
          maxLines: 10,
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: screenHeight1),
        SizedBox(
          height: Get.height * 0.15,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3, // Show placeholder boxes
            itemBuilder: (context, index) {
              final url = images[index];
              return Container(
                width: Get.width * 0.30,
                margin: EdgeInsets.only(right: screenWidth1),
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: NetworkImage(url), fit: BoxFit.cover),
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
                timelineItems[index], index == timelineItems.length - 1);
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
        // Timeline Icon and Line
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

        // Timeline Content
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
