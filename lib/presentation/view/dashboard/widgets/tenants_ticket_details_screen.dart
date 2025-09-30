import 'package:cached_network_image/cached_network_image.dart';
import 'package:majan/core/utils/date_formater.dart';
import 'package:majan/data/model/complaint_details_model.dart';
import 'package:majan/presentation/view/dashboard/controller/complaint_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_text_widget.dart';

class TicketDetailsScreen extends StatefulWidget {
  final String complaintId;

  const TicketDetailsScreen({
    super.key,
    required this.complaintId,
  });

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  final ComplaintDetailsController controller = Get.put(ComplaintDetailsController());

  @override
  void initState() {
    super.initState();
    _loadComplaintDetails();
  }

  void _loadComplaintDetails() {
    controller.fetchComplaintDetails(widget.complaintId);
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
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: Get.height * 0.08,
                ),
                SizedBox(height: screenHeight2),
                CustomTextWidget(
                  title: 'Error Loading Details',
                  fontSize: Get.height * 0.018,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
                SizedBox(height: screenHeight1),
                CustomTextWidget(
                  title: controller.errorMessage.value,
                  fontSize: Get.height * 0.014,
                  fontWeight: FontWeight.w400,
                  color: AppColors.black600,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight2),
                ElevatedButton(
                  onPressed: _loadComplaintDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final complaintDetails = controller.complaintDetails.value;
        if (complaintDetails == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.grey,
                  size: Get.height * 0.08,
                ),
                SizedBox(height: screenHeight2),
                CustomTextWidget(
                  title: 'No complaint details found',
                  fontSize: Get.height * 0.016,
                  color: AppColors.grey,
                ),
              ],
            ),
          );
        }

        final complaintData = complaintDetails.data;
        final complaint = complaintData.complaint;
        final property = complaintData.property;

        return SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTicketHeader(complaint),
              SizedBox(height: screenHeight2),
              _buildPropertyDetails(property, complaintData),
              SizedBox(height: screenHeight2),
              _buildIssueDetails(complaint),
              SizedBox(height: screenHeight2),
              _buildPaymentSection(),
              SizedBox(height: screenHeight2),
              _buildImagesSection(),
              SizedBox(height: screenHeight2),
              _buildTimelineSection(),
              SizedBox(height: screenHeight * 0.1),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTicketHeader(Complaint complaint) {
    return Container(
      padding: EdgeInsets.all(screenWidth2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.1),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextWidget(
                      title: "Ticket #${complaint.complaintNumber}",
                      fontSize: Get.height * 0.018,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                    SizedBox(height: screenHeight05),
                    CustomTextWidget(
                      title: "ID: ${complaint.id}",
                      fontSize: Get.height * 0.012,
                      fontWeight: FontWeight.w400,
                      color: AppColors.black600,
                    ),
                  ],
                ),
              ),
              _buildStatusChip(complaint.status),
            ],
          ),
          SizedBox(height: screenHeight1),
          CustomTextWidget(
            title: "Created: ${DateFormatter.formatTo12Hour(complaint.createdAt)}",
            fontSize: Get.height * 0.014,
            fontWeight: FontWeight.w400,
            color: AppColors.black600,
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyDetails(Property property, ComplaintData complaintData) {
    return _buildSection(
      title: "Property Details",
      icon: HugeIcons.strokeRoundedHome01,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow("Property Name", property.title),
          _buildInfoRow("Unit Number", property.unit.number),
          _buildInfoRow("Unit Type", property.unit.type),
          _buildInfoRow("Address", property.unit.addressFormat),
          _buildInfoRow("Property ID", property.id),
        ],
      ),
    );
  }

  Widget _buildIssueDetails(Complaint complaint) {
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
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(screenWidth2),
            decoration: BoxDecoration(
              color: AppColors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grey.withOpacity(0.2)),
            ),
            child: CustomTextWidget(
              title: complaint.description,
              fontSize: Get.height * 0.014,
              fontWeight: FontWeight.w400,
              color: AppColors.black600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    final hasPaymentInfo = controller.amountPaid.isNotEmpty && 
                          controller.amountPaid != '0' && 
                          controller.paymentStatus.isNotEmpty;

    if (!hasPaymentInfo) {
      return SizedBox.shrink();
    }

    return _buildSection(
      title: "Payment Information",
      icon: HugeIcons.strokeRoundedCreditCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow("Amount Paid", "${controller.amountPaid} OMR"),
          _buildInfoRow("Payment Status", controller.paymentStatus),
          if (controller.paymentMethod.isNotEmpty)
            _buildInfoRow("Payment Method", controller.paymentMethod),
          SizedBox(height: screenHeight1),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Get.width * 0.03,
              vertical: Get.height * 0.008,
            ),
            decoration: BoxDecoration(
              color: controller.paymentStatus.toLowerCase().contains('paid') 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: controller.paymentStatus.toLowerCase().contains('paid')
                    ? Colors.green.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  controller.paymentStatus.toLowerCase().contains('paid')
                      ? HugeIcons.strokeRoundedCheckmarkCircle01
                      : HugeIcons.strokeRoundedClock01,
                  size: Get.height * 0.018,
                  color: controller.paymentStatus.toLowerCase().contains('paid')
                      ? Colors.green
                      : Colors.orange,
                ),
                SizedBox(width: Get.width * 0.02),
                CustomTextWidget(
                  title: controller.paymentStatus.toLowerCase().contains('paid')
                      ? "Payment Completed"
                      : "Payment Pending",
                  fontSize: Get.height * 0.013,
                  fontWeight: FontWeight.w600,
                  color: controller.paymentStatus.toLowerCase().contains('paid')
                      ? Colors.green
                      : Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildImagesSection() {
  // Combine all images and remove duplicates based on imagePath
  final allUniqueImagesMap = <String, ComplaintImage>{};

  for (var img in controller.tenantImages) {
    allUniqueImagesMap[img.imagePath] = img;
  }
  for (var img in controller.technicianImages) {
    allUniqueImagesMap[img.imagePath] = img;
  }
  for (var img in controller.adminImages) {
    allUniqueImagesMap[img.imagePath] = img;
  }

  final uniqueImages = allUniqueImagesMap.values.toList();

  // DEBUG: Print unique image count
  print('🖼️ Total unique images: ${uniqueImages.length}');

  if (uniqueImages.isEmpty) {
    return _buildSection(
      title: "Attachments",
      icon: HugeIcons.strokeRoundedImage01,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth2),
            decoration: BoxDecoration(
              color: AppColors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.image_not_supported,
                  color: AppColors.grey,
                  size: Get.height * 0.03,
                ),
                SizedBox(width: screenWidth1),
                Expanded(
                  child: CustomTextWidget(
                    title: "No images available for this complaint",
                    fontSize: Get.height * 0.014,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  return _buildSection(
    title: "Attachments",
    icon: HugeIcons.strokeRoundedImage01,
    child: SizedBox(
      height: Get.height * 0.18,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: uniqueImages.length,
        itemBuilder: (context, index) {
          final image = uniqueImages[index];
          final imageUrl = image.imagePath;

          return Container(
            width: Get.width * 0.35,
            margin: EdgeInsets.only(right: screenWidth1),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.grey.withOpacity(0.2)),
                      color: AppColors.grey.withOpacity(0.05),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Container(
                          color: AppColors.grey.withOpacity(0.1),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.red.withOpacity(0.1),
                          child: const Center(
                            child: Icon(Icons.error_outline, color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight05),
                CustomTextWidget(
                  title: DateFormatter.formatTo12Hour(image.timestamp),
                  fontSize: Get.height * 0.011,
                  fontWeight: FontWeight.w400,
                  color: AppColors.black600,
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
Widget _buildTimelineSection() {
  final timelineEvents = controller.timeline;
  
  if (timelineEvents.isEmpty) {
    return SizedBox.shrink();
  }

  return _buildSection(
    title: "Timeline Events",
    icon: HugeIcons.strokeRoundedClock01,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: "Recent Activities (${timelineEvents.length})",
          fontSize: Get.height * 0.014,
          fontWeight: FontWeight.w600,
          color: AppColors.black600,
        ),
        SizedBox(height: screenHeight1),
        ...timelineEvents.asMap().entries.map((entry) {
          final index = entry.key;
          final event = entry.value;
          
          return Container(
            margin: EdgeInsets.only(bottom: index == timelineEvents.length - 1 ? 0 : screenHeight1),
            padding: EdgeInsets.all(screenWidth2),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: Get.height * 0.04,
                  height: Get.height * 0.04,
                  decoration: BoxDecoration(
                    color: _getTimelineEventColor(event.type),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTimelineEventIcon(event.type),
                    color: AppColors.white,
                    size: Get.height * 0.02,
                  ),
                ),
                SizedBox(width: screenWidth2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: CustomTextWidget(
                              title: _formatTimelineEventType(event.type),
                              fontSize: Get.height * 0.014,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                          CustomTextWidget(
                            title: DateFormatter.formatTo12Hour(event.timestamp),
                            fontSize: Get.height * 0.011,
                            fontWeight: FontWeight.w400,
                            color: AppColors.black600,
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight05),
                      
                      // Display message for reply events
                      if (event.message != null && event.message!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(screenWidth1),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomTextWidget(
                                    title: event.message!,
                                    fontSize: Get.height * 0.013,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.black,
                                  ),
                                  SizedBox(height: screenHeight05),
                                  if (event.by != null)
                                    CustomTextWidget(
                                      title: "By: ${_getPersonName(event.by!)}",
                                      fontSize: Get.height * 0.011,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.black600,
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight05),
                          ],
                        ),
                      
                      // Display status change details
                      if (event.type == 'status_change' && event.oldStatus != null && event.newStatus != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(screenWidth1),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  CustomTextWidget(
                                    title: "Status changed: ",
                                    fontSize: Get.height * 0.012,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                  CustomTextWidget(
                                    title: "${event.oldStatus} → ${event.newStatus}",
                                    fontSize: Get.height * 0.012,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight05),
                          ],
                        ),
                      
                      // Display technician assignment
                      if (event.type == 'technician_assigned' && event.technician != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(screenWidth1),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: CustomTextWidget(
                                title: "Technician: ${_getPersonName(event.technician!)}",
                                fontSize: Get.height * 0.012,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: screenHeight05),
                          ],
                        ),
                      
                      // Display payment information
                      if (event.type == 'payment')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(screenWidth1),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.teal.withOpacity(0.3)),
                              ),
                              child: CustomTextWidget(
                                title: "Payment: ${event.message ?? 'Payment processed'}",
                                fontSize: Get.height * 0.012,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal,
                              ),
                            ),
                            SizedBox(height: screenHeight05),
                          ],
                        ),
                      
                      // Display who performed the action
                      if (event.by != null && event.type != 'reply')
                        Padding(
                          padding: EdgeInsets.only(bottom: screenHeight05),
                          child: CustomTextWidget(
                            title: "By: ${_getPersonName(event.by!)}",
                            fontSize: Get.height * 0.011,
                            fontWeight: FontWeight.w400,
                            color: AppColors.black600,
                          ),
                        ),
                      
                      // Event description
                      CustomTextWidget(
                        title: _getTimelineEventDescription(event),
                        fontSize: Get.height * 0.013,
                        fontWeight: FontWeight.w400,
                        color: AppColors.black600,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    ),
  );
}

// Helper to get person name from by/technician object
String _getPersonName(Map<String, dynamic> personData) {
  return personData['name']?.toString() ?? 'Unknown';
}

// Updated timeline event description method
String _getTimelineEventDescription(TimelineEvent event) {
  switch (event.type) {
    case 'technician_assigned':
      return 'Technician was assigned to handle this complaint';
    case 'complaint_created':
      return 'Complaint was created and registered in the system';
    case 'status_change':
      return 'Complaint status was updated';
    case 'reply':
      return 'Response was added to this complaint';
    case 'payment':
      return 'Payment was processed for this complaint';
    case 'image_upload':
      return 'Image was uploaded for this complaint';
    default:
      return 'Activity recorded for this complaint';
  }
}

// Update the existing helper methods to handle new event types
Color _getTimelineEventColor(String type) {
  switch (type) {
    case 'complaint_created':
      return Colors.blue;
    case 'technician_assigned':
      return Colors.green;
    case 'status_change':
      return Colors.orange;
    case 'reply':
      return Colors.purple;
    case 'payment':
      return Colors.teal;
    case 'image_upload':
      return Colors.indigo;
    default:
      return AppColors.grey;
  }
}

IconData _getTimelineEventIcon(String type) {
  switch (type) {
    case 'complaint_created':
      return HugeIcons.strokeRoundedFileAdd;
    case 'technician_assigned':
      return HugeIcons.strokeRoundedUserSettings01;
    case 'status_change':
      return HugeIcons.strokeRoundedEdit01;
    case 'reply':
      return HugeIcons.strokeRoundedMessageIncoming01;
    case 'payment':
      return HugeIcons.strokeRoundedCreditCard;
    case 'image_upload':
      return HugeIcons.strokeRoundedImage01;
    default:
      return HugeIcons.strokeRoundedInformationCircle;
  }
}

String _formatTimelineEventType(String type) {
  // Convert snake_case to Title Case
  return type.split('_').map((word) => 
    word[0].toUpperCase() + word.substring(1)
  ).join(' ');
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
            color: AppColors.grey.withOpacity(0.1),
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
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: Get.width * 0.35,
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
      case "in_progress":
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        break;
      case "completed":
        backgroundColor = AppColors.onlineGreen.withOpacity(0.2);
        textColor = AppColors.onlineGreenDark;
        break;
      case "resolved":
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      case "cancelled":
      case "rejected":
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      default:
        backgroundColor = AppColors.grey.withOpacity(0.1);
        textColor = AppColors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Get.width * 0.03,
        vertical: Get.height * 0.006,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: CustomTextWidget(
        title: status.toUpperCase(),
        fontSize: Get.height * 0.012,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

 Widget _buildImageCategory(String title, List<ComplaintImage> images, Color accentColor) {
  print('🖼️ Building image category: $title with ${images.length} images');
  
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
        height: Get.height * 0.18,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: images.length,
          itemBuilder: (context, index) {
            final image = images[index];
            final imageUrl = image.imagePath;
            
            print('🖼️ Loading image $index: $imageUrl');
            
            // Check if URL is valid
            final isValidUrl = imageUrl.startsWith('http') && 
                              imageUrl.isNotEmpty && 
                              !imageUrl.contains('example.com');
            
            return Container(
              width: Get.width * 0.35,
              margin: EdgeInsets.only(right: screenWidth1),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isValidUrl ? accentColor.withOpacity(0.3) : Colors.red.withOpacity(0.5),
                          width: isValidUrl ? 1 : 2,
                        ),
                        color: isValidUrl ? null : Colors.red.withOpacity(0.1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: isValidUrl 
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                progressIndicatorBuilder: (context, url, downloadProgress) => 
                                    Container(
                                      color: accentColor.withOpacity(0.1),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (downloadProgress != null)
                                            CircularProgressIndicator(
                                              value: downloadProgress.progress,
                                              color: accentColor,
                                            )
                                          else
                                            CircularProgressIndicator(
                                              color: accentColor,
                                            ),
                                          SizedBox(height: 8),
                                          Text(
                                            downloadProgress != null && downloadProgress.progress != null
                                                ? '${(downloadProgress.progress! * 100).toStringAsFixed(0)}%'
                                                : 'Loading...',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: accentColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                errorWidget: (context, url, error) {
                                  print('❌ Image load error: $error for URL: $url');
                                  return Container(
                                    color: Colors.red.withOpacity(0.1),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: Get.height * 0.04,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Load Failed',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Tap to retry',
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: Colors.red.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.link_off,
                                    color: Colors.red,
                                    size: Get.height * 0.04,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Invalid URL',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    imageUrl.isEmpty ? 'Empty' : imageUrl,
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.red.withOpacity(0.7),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight05),
                  CustomTextWidget(
                    title: DateFormatter.formatTo12Hour(image.timestamp),
                    fontSize: Get.height * 0.011,
                    fontWeight: FontWeight.w400,
                    color: AppColors.black600,
                  ),
                  if (!isValidUrl) ...[
                    SizedBox(height: 4),
                    CustomTextWidget(
                      title: 'Invalid URL',
                      fontSize: Get.height * 0.01,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}
}