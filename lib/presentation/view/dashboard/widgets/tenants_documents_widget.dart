import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/data/model/tenant_document_model.dart';
import 'package:majan/presentation/view/dashboard/controller/tenant_document_controller.dart';
import 'package:majan/presentation/view/dashboard/widgets/tenants_document_card.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class TenantDocumentsView extends StatelessWidget {
  TenantDocumentsView({Key? key}) : super(key: key);

  final TenantDocumentController controller = Get.put(TenantDocumentController());

  @override
  Widget build(BuildContext context) {
    // Get current user UID from Firebase Auth
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Show error if user is not logged in
    if (uid.isEmpty) {
      return _buildLoginRequiredScreen();
    }

    // Fetch documents when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchTenantDocuments(uid);
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildDivider(),
          kHeight(0.02),
          _buildPropertySection(),
          kHeight(0.02),
          _buildDocumentsList(uid),
        ],
      ),
    );
  }

  /// Build AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: Icon(
          Icons.arrow_back,
          size: iconSize,
          color: AppColors.black,
        ),
      ),
      title: CustomTextWidget(
        title: 'My Documents',
        fontSize: appBarTitles,
        fontWeight: FontWeight.w600,
        color: AppColors.black,
      ),
      actions: [
        Obx(() {
          if (!controller.isLoading.value && 
              controller.tenantDocumentResponse.value != null) {
            return IconButton(
              onPressed: () {
                final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                if (uid.isNotEmpty) {
                  controller.fetchTenantDocuments(uid);
                }
              },
              icon: Icon(
                Icons.refresh,
                size: iconSize,
                color: AppColors.black,
              ),
            );
          }
          return SizedBox.shrink();
        }),
      ],
    );
  }

  /// Build Property Section
  Widget _buildPropertySection() {
    return Obx(() {
      final response = controller.tenantDocumentResponse.value;
      
      if (response == null || response.tenantProperty == null) {
        return SizedBox.shrink();
      }

      final property = response.tenantProperty!;
      final booking = response.booking;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth4),
        child: Container(
          padding: EdgeInsets.all(screenWidth4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.blueColor.withValues(alpha: 0.15),
                AppColors.blueColor.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(screenWidth3),
            border: Border.all(
              color: AppColors.blueColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(screenWidth2),
                    decoration: BoxDecoration(
                      color: AppColors.blueColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(screenWidth2),
                    ),
                    child: Icon(
                      Icons.home_outlined,
                      color: AppColors.blueColor,
                      size: 20,
                    ),
                  ),
                  kWidth(0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextWidget(
                          title: 'Property ID: ${property.propertyId}',
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                        if (booking != null) ...[
                          kHeight(0.003),
                          CustomTextWidget(
                            title: '${booking.firstName} ${booking.lastName}',
                            fontSize: tagTitle,
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkGrey,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth3,
                      vertical: screenHeight05,
                    ),
                    decoration: BoxDecoration(
                      color: property.status.toLowerCase() == 'active'
                          ? AppColors.onlineGreen
                          : AppColors.darkGrey,
                      borderRadius: BorderRadius.circular(screenWidth2),
                    ),
                    child: CustomTextWidget(
                      title: property.status,
                      fontSize: expandedContentTitle,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              kHeight(0.015),
              Row(
                children: [
                  Expanded(
                    child: _buildPropertyDetail(
                      'Unit',
                      property.unitId,
                      Icons.apartment,
                    ),
                  ),
                  kWidth(0.02),
                  Expanded(
                    child: _buildPropertyDetail(
                      'Booking',
                      property.bookingId,
                      Icons.receipt_long,
                    ),
                  ),
                ],
              ),
              kHeight(0.01),
              Row(
                children: [
                  Expanded(
                    child: _buildPropertyDetail(
                      'Start Date',
                      _formatDate(property.startDate),
                      Icons.calendar_today,
                    ),
                  ),
                  kWidth(0.02),
                  Expanded(
                    child: _buildPropertyDetail(
                      'End Date',
                      _formatDate(property.endDate),
                      Icons.event,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPropertyDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.blueColor.withValues(alpha: 0.7),
        ),
        kWidth(0.015),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextWidget(
                title: label,
                fontSize: expandedContentTitle,
                fontWeight: FontWeight.w500,
                color: AppColors.darkGrey.withValues(alpha: 0.8),
              ),
              CustomTextWidget(
                title: value,
                fontSize: tagTitle,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build Divider
  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AppColors.darkGrey.withValues(alpha: 0.3),
      margin: EdgeInsets.symmetric(horizontal: screenWidth4),
    );
  }

  /// Build Documents List
  Widget _buildDocumentsList(String uid) {
    return Expanded(
      child: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingState();
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return _buildErrorState(uid);
        }

        final response = controller.tenantDocumentResponse.value;
        if (response == null || !response.success) {
          return _buildNoDocumentsState();
        }

        final allDocuments = _prepareDocumentsList(response);

        if (allDocuments.isEmpty) {
          return _buildEmptyState();
        }

        return _buildDocumentsListView(allDocuments);
      }),
    );
  }

  /// Build Loading State
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.blueColor,
          ),
          kHeight(0.02),
          CustomTextWidget(
            title: 'Loading documents...',
            color: AppColors.darkGrey,
          ),
        ],
      ),
    );
  }

  /// Build Error State
  Widget _buildErrorState(String uid) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: AppColors.redColor,
            ),
            kHeight(0.02),
            CustomTextWidget(
              title: 'Error loading documents',
              fontSize: H18,
              fontWeight: FontWeight.w600,
              color: AppColors.redColor,
            ),
            kHeight(0.01),
            CustomTextWidget(
              title: controller.errorMessage.value,
              fontSize: tagTitle,
              color: AppColors.darkGrey,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            kHeight(0.03),
            ElevatedButton(
              onPressed: () => controller.fetchTenantDocuments(uid),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueColor,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth8,
                  vertical: screenHeight1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth2),
                ),
              ),
              child: CustomTextWidget(
                title: 'Retry',
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build No Documents State
  Widget _buildNoDocumentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 60,
            color: AppColors.darkGrey,
          ),
          kHeight(0.02),
          CustomTextWidget(
            title: 'No documents found',
            fontSize: H18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGrey,
          ),
          kHeight(0.01),
          CustomTextWidget(
            title: 'Your documents will appear here',
            fontSize: tagTitle,
            color: AppColors.darkGrey,
          ),
        ],
      ),
    );
  }

  /// Build Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 60,
            color: AppColors.darkGrey,
          ),
          kHeight(0.02),
          CustomTextWidget(
            title: 'No documents available',
            fontSize: H18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGrey,
          ),
        ],
      ),
    );
  }

  /// Build Login Required Screen
  Widget _buildLoginRequiredScreen() {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back,
            size: iconSize,
            color: AppColors.black,
          ),
        ),
        title: CustomTextWidget(
          title: 'My Documents',
          fontSize: appBarTitles,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 60,
              color: AppColors.redColor,
            ),
            kHeight(0.02),
            CustomTextWidget(
              title: 'Please login to view documents',
              fontSize: H18,
              fontWeight: FontWeight.w600,
              color: AppColors.redColor,
            ),
          ],
        ),
      ),
    );
  }

  /// Prepare Documents List
  List<DocumentItem> _prepareDocumentsList(TenantDocumentResponse response) {
    final allDocuments = <DocumentItem>[];
    
    final propertyId = response.tenantProperty?.propertyId;
    final unitId = response.tenantProperty?.unitId;

    // Add booking documents
    for (var doc in response.bookingDocuments) {
      allDocuments.add(DocumentItem(
        document: doc,
        type: DocumentType.booking,
        baseUrl: response.baseUrl,
        propertyId: propertyId,
        unitId: unitId,
      ));
    }

    // Add payment documents
    for (var doc in response.paymentDocuments) {
      allDocuments.add(DocumentItem(
        document: doc,
        type: DocumentType.payment,
        baseUrl: response.baseUrl,
        propertyId: propertyId,
        unitId: unitId,
      ));
    }

    return allDocuments;
  }

  /// Build Documents ListView
  Widget _buildDocumentsListView(List<DocumentItem> allDocuments) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: screenWidth4),
      itemCount: allDocuments.length,
      itemBuilder: (context, index) {
        final documentItem = allDocuments[index];
        return Column(
          children: [
            DocumentCard(
              documentItem: documentItem,
              onViewPressed: () {
                _viewDocument(documentItem);
              },
            ),
            if (index < allDocuments.length - 1) kHeight(0.025),
            if (index == allDocuments.length - 1) kHeight(0.02),
          ],
        );
      },
    );
  }

  /// View Document Dialog with Zoom and Gallery Options
  void _viewDocument(DocumentItem documentItem) {
    // Check if imageUrl already contains full URL
    String imageUrl = documentItem.document.imageUrl;
    
    // Only prepend baseUrl if imageUrl doesn't start with http/https
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      imageUrl = documentItem.baseUrl + imageUrl;
    }
    
    print('Image URL: $imageUrl'); // Debug print

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth3),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.85,
            maxWidth: Get.width * 0.95,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Gallery Button
              Container(
                padding: EdgeInsets.all(screenWidth4),
                decoration: BoxDecoration(
                  color: AppColors.blueColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(screenWidth3),
                    topRight: Radius.circular(screenWidth3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CustomTextWidget(
                        title: documentItem.document.title,
                        fontSize: H18,
                        fontWeight: FontWeight.w600,
                        maxLines: 2,
                      ),
                    ),
                    Row(
                      children: [
                        // Open in Gallery Button
                        IconButton(
                          onPressed: () => _openInGallery(imageUrl, documentItem.document.title),
                          icon: Icon(Icons.open_in_new, color: AppColors.blueColor),
                          tooltip: 'Open in Gallery',
                        ),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: Icon(Icons.close, color: AppColors.black),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Zoomable Image
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(screenWidth4),
                  child: ZoomableImageWidget(imageUrl: imageUrl),
                ),
              ),

              // Document Details
              Container(
                padding: EdgeInsets.all(screenWidth4),
                decoration: BoxDecoration(
                  color: AppColors.whiteLight,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(screenWidth3),
                    bottomRight: Radius.circular(screenWidth3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      'Type',
                      documentItem.document.documentType,
                    ),
                    kHeight(0.01),
                    _buildDetailRow(
                      'Status',
                      documentItem.document.verificationStatus,
                    ),
                    if (documentItem.document.expiryDate.isNotEmpty) ...[
                      kHeight(0.01),
                      _buildDetailRow(
                        'Expires',
                        _formatDate(documentItem.document.expiryDate),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Download and Open Image in Gallery
  Future<void> _openInGallery(String imageUrl, String documentTitle) async {
    try {
      // Show loading indicator
      Get.dialog(
        Center(
          child: Container(
            padding: EdgeInsets.all(screenWidth8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(screenWidth3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.blueColor),
                kHeight(0.02),
                CustomTextWidget(
                  title: 'Opening in gallery...',
                  color: AppColors.black,
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = '${documentTitle.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${tempDir.path}/$fileName';

      // Download image
      final dio = Dio();
      await dio.download(imageUrl, filePath);

      // Close loading dialog
      Get.back();

      // Open file with default gallery app
      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        Get.snackbar(
          'Error',
          'Could not open image in gallery',
          backgroundColor: AppColors.redColor,
          colorText: AppColors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      Get.snackbar(
        'Error',
        'Failed to open image: ${e.toString()}',
        backgroundColor: AppColors.redColor,
        colorText: AppColors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: '$label: ',
          fontSize: tagTitle,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        Expanded(
          child: CustomTextWidget(
            title: value,
            fontSize: tagTitle,
            fontWeight: FontWeight.w500,
            color: AppColors.darkGrey,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

/// Zoomable Image Widget with Pinch-to-Zoom and Double-Tap
class ZoomableImageWidget extends StatefulWidget {
  final String imageUrl;

  const ZoomableImageWidget({
    Key? key,
    required this.imageUrl,
  }) : super(key: key);

  @override
  State<ZoomableImageWidget> createState() => _ZoomableImageWidgetState();
}

class _ZoomableImageWidgetState extends State<ZoomableImageWidget> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_controller.value != Matrix4.identity()) {
      // If zoomed in, reset to normal
      _controller.value = Matrix4.identity();
    } else {
      // If normal, zoom to 2x at tap position
      final position = _doubleTapDetails!.localPosition;
      _controller.value = Matrix4.identity()
        ..translate(-position.dx, -position.dy)
        ..scale(2.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _handleDoubleTapDown,
      onDoubleTap: _handleDoubleTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(screenWidth2),
        child: InteractiveViewer(
          transformationController: _controller,
          minScale: 0.5,
          maxScale: 4.0,
          clipBehavior: Clip.none,
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: AppColors.blueColor,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      size: 50,
                      color: AppColors.redColor,
                    ),
                    kHeight(0.02),
                    CustomTextWidget(
                      title: 'Failed to load image',
                      color: AppColors.darkGrey,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}