import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:majan/core/utils/date_formater.dart';
import 'package:majan/data/model/complaint_details_model.dart';
import 'package:majan/presentation/view/dashboard/controller/complaint_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:majan/presentation/widgets/custom_text_formfield_widget.dart';
import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_text_widget.dart';
class TicketDetailsScreen extends StatefulWidget {
  final String complaintId;
  final String? previewImageUrl;
  final String? previewImageTimestamp;

  const TicketDetailsScreen({
    super.key,
    required this.complaintId,
    this.previewImageUrl,
    this.previewImageTimestamp,
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

  String _formatDateTimeToLocal(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return 'N/A';
    }
    try {
      if (dateTimeString.contains(' at ') ||
          RegExp(r'\d{1,2}:\d{2}\s?(AM|PM|am|pm)').hasMatch(dateTimeString)) {
        debugPrint('⚠️ Timeline timestamp already formatted: $dateTimeString');
        return dateTimeString;
      }
      DateTime dateTime;
      try {
        dateTime = DateTime.parse(dateTimeString);
        debugPrint('✅ Parsed as ISO 8601: $dateTimeString');
      } catch (e1) {
        try {
          dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTimeString);
          debugPrint('✅ Parsed as yyyy-MM-dd HH:mm:ss: $dateTimeString');
        } catch (e2) {
          try {
            dateTime = DateFormat('MM/dd/yyyy HH:mm:ss').parse(dateTimeString);
            debugPrint('✅ Parsed as MM/dd/yyyy HH:mm:ss: $dateTimeString');
          } catch (e3) {
            debugPrint('❌ All parsing strategies failed for: $dateTimeString');
            return dateTimeString;
          }
        }
      }
      DateTime localTime;
      if (dateTimeString.endsWith('Z') || dateTimeString.contains('+') || dateTimeString.contains('T')) {
        localTime = dateTime.toLocal();
        debugPrint('🌍 Converted from UTC to local: ${dateTime} -> ${localTime}');
      } else {
        localTime = dateTime;
        debugPrint('📍 Already local time: $localTime');
      }
      String formattedDate = DateFormat('MMM dd, yyyy').format(localTime);
      String formattedTime = DateFormat('hh:mm a').format(localTime);
      String result = '$formattedDate at $formattedTime';
      debugPrint('✅ Final formatted result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error formatting timeline timestamp: $e for input: $dateTimeString');
      return dateTimeString;
    }
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
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: Get.height * 0.08),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                Icon(Icons.info_outline, color: AppColors.grey, size: Get.height * 0.08),
                SizedBox(height: screenHeight2),
                CustomTextWidget(title: 'No complaint details found', fontSize: Get.height * 0.016, color: AppColors.grey),
              ],
            ),
          );
        }
        final complaintData = complaintDetails.data;
        final complaint = complaintData.complaint;
        final property = complaintData.property;
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                    SizedBox(height: screenHeight2),
                    _buildCommentsSection(),
                    SizedBox(height: screenHeight * 0.1),
                  ],
                ),
              ),
            ),
            _buildCommentsInputSection(),
          ],
        );
      }),
    );
  }

  // NEW: Build comments history section
  Widget _buildCommentsSection() {
    final timeline = controller.timeline;
    final commentEvents = timeline.where((event) =>
        event.type == 'user_comment' || event.type == 'reply'
    ).toList();
    if (commentEvents.isEmpty) {
      return SizedBox.shrink();
    }
    return _buildSection(
      title: "Comments & Replies",
      icon: HugeIcons.strokeRoundedMessageIncoming01,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextWidget(
            title: "${commentEvents.length} Comment${commentEvents.length > 1 ? 's' : ''}",
            fontSize: Get.height * 0.014,
            fontWeight: FontWeight.w600,
            color: AppColors.black600,
          ),
          SizedBox(height: screenHeight1),
          ...commentEvents.map((event) => _buildCommentItem(event)).toList(),
        ],
      ),
    );
  }

  // ✅ UPDATED: Use typed UserBy? object (safe with nulls)
  Widget _buildCommentItem(TimelineEvent event) {
    final by = event.by; // Now a UserBy? object, not Map

    // Determine type safely
    final String? senderType = by?.type?.toLowerCase();
    final bool isTechnician = senderType == 'technician';
    final bool isUser = senderType == 'tenant' || senderType == 'user';

    // Fallback name if missing
    final String senderName = by?.name?.trim().isNotEmpty == true
        ? by!.name!
        : (isTechnician ? 'Technician' : 'Tenant');

    // Photo URL (may be null)
    final String? photoUrl = by?.photo;

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight1),
      padding: EdgeInsets.all(screenWidth3),
      decoration: BoxDecoration(
        color: isUser
            ? AppColors.secondaryColor.withOpacity(0.1)
            : Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUser
              ? AppColors.secondaryColor.withOpacity(0.3)
              : Colors.green.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (photoUrl != null && photoUrl.isNotEmpty)
                      ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: photoUrl,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const CircleAvatar(child: Icon(Icons.person, size: 14)),
                          errorWidget: (context, url, error) => const CircleAvatar(child: Icon(Icons.person, size: 14)),
                        ),
                      )
                    else
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.secondaryColor : Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isUser ? Icons.person : Icons.engineering,
                          size: 14,
                          color: AppColors.white,
                        ),
                      ),
                    SizedBox(width: screenWidth2),
                    Expanded(
                      child: CustomTextWidget(
                        title: senderName,
                        fontSize: Get.height * 0.014,
                        fontWeight: FontWeight.w600,
                        color: isUser ? AppColors.secondaryColor : Colors.green,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: screenWidth1),
              CustomTextWidget(
                title: _formatDateTimeToLocal(event.timestamp),
                fontSize: Get.height * 0.012,
                color: AppColors.black600,
              ),
            ],
          ),
          if (event.message != null && event.message!.isNotEmpty) ...[
            SizedBox(height: screenHeight1),
            CustomTextWidget(
              title: event.message!,
              fontSize: Get.height * 0.015,
              color: AppColors.black,
            ),
          ],
        ],
      ),
    );
  }

  // NEW: Build comments input section (fixed at bottom)
  Widget _buildCommentsInputSection() {
    return Container(
      padding: EdgeInsets.all(screenWidth4),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: CustomTextFieldWidget(
                controller: controller.commentController,
                hintText: 'Add a comment...',
                maxLines: 1,
                isBorderNeeded: true,
                keyboardType: TextInputType.text,
              ),
            ),
            SizedBox(width: screenWidth2),
            Obx(() => Container(
              decoration: BoxDecoration(
                color: controller.isSubmittingComment.value
                    ? AppColors.grey.withOpacity(0.3)
                    : AppColors.secondaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: controller.isSubmittingComment.value
                    ? null
                    : () => controller.addComment(widget.complaintId),
                icon: controller.isSubmittingComment.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : const Icon(Icons.send, color: AppColors.white, size: 20),
              ),
            )),
          ],
        ),
      ),
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
                      title: "Ticket ${complaint.complaintNumber}",
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
            title: "Created: ${_formatDateTimeToLocal(complaint.createdAt)}",
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
          if (controller.paymentMethod.isNotEmpty) _buildInfoRow("Payment Method", controller.paymentMethod),
          SizedBox(height: screenHeight1),
          Container(
            padding: EdgeInsets.symmetric(horizontal: Get.width * 0.03, vertical: Get.height * 0.008),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    var tenantImages = controller.tenantImages.toList();
    final technicianImages = controller.technicianImages;
    final adminImages = controller.adminImages;

    if (widget.previewImageUrl != null &&
        widget.previewImageUrl!.isNotEmpty &&
        !tenantImages.any((img) => img.imagePath == widget.previewImageUrl)) {
      final previewImage = ComplaintImage(
        imagePath: widget.previewImageUrl!,
        timestamp: widget.previewImageTimestamp ?? DateTime.now().toIso8601String(),
      );
      tenantImages.insert(0, previewImage);
      print('🖼️ Added preview image to tenant images');
    }

    print('🖼️ Tenant images: ${tenantImages.length}');
    print('🖼️ Technician images: ${technicianImages.length}');
    print('🖼️ Admin images: ${adminImages.length}');

    final allImages = <ComplaintImage>[];
    allImages.addAll(tenantImages);
    allImages.addAll(technicianImages);
    allImages.addAll(adminImages);

    final uniqueImagesMap = <String, ComplaintImage>{};
    for (var img in allImages) {
      uniqueImagesMap[img.imagePath] = img;
    }
    final uniqueImages = uniqueImagesMap.values.toList();
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
                  Icon(Icons.image_not_supported, color: AppColors.grey, size: Get.height * 0.03),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tenantImages.isNotEmpty) _buildImageCategory("Tenant Images", tenantImages, Colors.blue),
          if (tenantImages.isNotEmpty && (technicianImages.isNotEmpty || adminImages.isNotEmpty))
            SizedBox(height: screenHeight2),
          if (technicianImages.isNotEmpty) _buildImageCategory("Technician Images", technicianImages, Colors.green),
          if (technicianImages.isNotEmpty && adminImages.isNotEmpty) SizedBox(height: screenHeight2),
          if (adminImages.isNotEmpty) _buildImageCategory("Admin Images", adminImages, Colors.orange),
        ],
      ),
    );
  }

Widget _buildTimelineSection() {
  final timelineEvents = controller.timeline;
  if (timelineEvents.isEmpty) {
    return SizedBox.shrink();
  }
  
  // ✅ Sort with FORCED logical order (complaint_created ALWAYS first)
  final sortedEvents = List<TimelineEvent>.from(timelineEvents);
  sortedEvents.sort((a, b) {
    // PRIORITY 1: Force complaint_created to always be first
    if (a.type == 'complaint_created' && b.type != 'complaint_created') return -1;
    if (b.type == 'complaint_created' && a.type != 'complaint_created') return 1;
    
    // PRIORITY 2: Force technician_assigned to be second (after complaint_created)
    if (a.type == 'technician_assigned' && b.type != 'complaint_created' && b.type != 'technician_assigned') return -1;
    if (b.type == 'technician_assigned' && a.type != 'complaint_created' && a.type != 'technician_assigned') return 1;
    
    // PRIORITY 3: Sort remaining events by timestamp
    try {
      if (a.timestamp == null || a.timestamp!.isEmpty) return 1;
      if (b.timestamp == null || b.timestamp!.isEmpty) return -1;
      
      final dateA = _parseTimestamp(a.timestamp!);
      final dateB = _parseTimestamp(b.timestamp!);
      
      return dateA.compareTo(dateB);
    } catch (e) {
      debugPrint('⚠️ Error sorting timeline events: $e');
      return 0;
    }
  });
  
  return _buildSection(
    title: "Timeline Events",
    icon: HugeIcons.strokeRoundedClock01,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: "Recent Activities (${sortedEvents.length})",
          fontSize: Get.height * 0.014,
          fontWeight: FontWeight.w600,
          color: AppColors.black600,
        ),
        SizedBox(height: screenHeight1),
        ...sortedEvents.asMap().entries.map((entry) {
          final index = entry.key;
          final event = entry.value;
          debugPrint('📅 Timeline Event Type: ${event.type}');
          debugPrint('📅 Raw Timestamp: ${event.timestamp}');
          debugPrint('📅 Formatted Timestamp: ${_formatDateTimeToLocal(event.timestamp)}');
          
          return Container(
            margin: EdgeInsets.only(bottom: index == sortedEvents.length - 1 ? 0 : screenHeight1),
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
                            title: _formatDateTimeToLocal(event.timestamp),
                            fontSize: Get.height * 0.011,
                            fontWeight: FontWeight.w400,
                            color: AppColors.black600,
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight05),
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
                                      title: "By: ${_getPersonNameFromUserBy(event.by!)}",
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
                                title: "Technician: ${_getPersonNameFromUserBy(event.technician!)}",
                                fontSize: Get.height * 0.012,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: screenHeight05),
                          ],
                        ),
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
                      if (event.by != null && event.type != 'reply')
                        Padding(
                          padding: EdgeInsets.only(bottom: screenHeight05),
                          child: CustomTextWidget(
                            title: "By: ${_getPersonNameFromUserBy(event.by!)}",
                            fontSize: Get.height * 0.011,
                            fontWeight: FontWeight.w400,
                            color: AppColors.black600,
                          ),
                        ),
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

// ✅ Add this helper method to parse timestamps with multiple format support
DateTime _parseTimestamp(String timestamp) {
  try {
    // Try ISO 8601 format first
    return DateTime.parse(timestamp);
  } catch (e1) {
    try {
      // Try yyyy-MM-dd HH:mm:ss format
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(timestamp);
    } catch (e2) {
      try {
        // Try MM/dd/yyyy HH:mm:ss format
        return DateFormat('MM/dd/yyyy HH:mm:ss').parse(timestamp);
      } catch (e3) {
        // Return current time as fallback
        debugPrint('❌ Failed to parse timestamp: $timestamp');
        return DateTime.now();
      }
    }
  }
}
  // ✅ Helper for UserBy object (not Map)
  String _getPersonNameFromUserBy(UserBy userBy) {
    return userBy.name?.trim().isNotEmpty == true ? userBy.name! : 'Unknown';
  }

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
    return type.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
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
      padding: EdgeInsets.symmetric(horizontal: Get.width * 0.03, vertical: Get.height * 0.006),
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
              return GestureDetector(
                onTap: () => _showZoomableImageDialog(context, imageUrl),
                child: Container(
                  width: Get.width * 0.35,
                  margin: EdgeInsets.only(right: screenWidth1),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accentColor.withOpacity(0.3)),
                            color: accentColor.withOpacity(0.05),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Container(
                                color: accentColor.withOpacity(0.1),
                                child: Center(child: CircularProgressIndicator(color: accentColor)),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.red.withOpacity(0.1),
                                child: Center(child: Icon(Icons.error_outline, color: Colors.red)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight05),
                      CustomTextWidget(
                        title: _formatDateTimeToLocal(image.timestamp),
                        fontSize: Get.height * 0.011,
                        fontWeight: FontWeight.w400,
                        color: AppColors.black600,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showZoomableImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(20),
          child: Stack(
            children: [
              Positioned(
                top: 40,
                right: 40,
                child: IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: EdgeInsets.all(20),
                  minScale: 0.1,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      color: Colors.black.withOpacity(0.1),
                      child: Center(child: CircularProgressIndicator(color: Colors.white)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.black.withOpacity(0.1),
                      child: Center(child: Icon(Icons.error_outline, color: Colors.white, size: 50)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}