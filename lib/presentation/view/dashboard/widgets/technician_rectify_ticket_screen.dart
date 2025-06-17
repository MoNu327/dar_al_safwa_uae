import 'package:dar_al_safwa/presentation/widgets/custom_text_formfield_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_text_widget.dart';

class RectifyTicketsScreen extends StatefulWidget {
  const RectifyTicketsScreen({super.key});

  @override
  State<RectifyTicketsScreen> createState() => _RectifyTicketsScreenState();
}

class _RectifyTicketsScreenState extends State<RectifyTicketsScreen> {
  final TextEditingController _workDescriptionController =
      TextEditingController();
  String selectedWorkStatus = 'Pending';
  bool amountChanged = false;
  bool isPaid = false;
  List<File> uploadedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _workDescriptionController.text =
        'Replaced leaking pipe with PVC joint. Sealed wall after repair.';
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
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.black,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: const CustomTextWidget(
          title: 'Rectify Tickets',
          fontSize: 18,
          color: AppColors.black,
          fontWeight: FontWeight.w600,
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Get.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ticketDetailsCard(),
            SizedBox(height: Get.height * 0.015),

            // Image Upload Container
            Container(
              padding: EdgeInsets.all(Get.width * 0.04),
              decoration: BoxDecoration(
                color: AppColors.whiteLight,
                borderRadius: BorderRadius.circular(screenWidth4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextWidget(
                    title: 'Upload Work Images (Before / After)',
                    fontSize: screenHeight * 0.014,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                  SizedBox(height: Get.height * 0.015),
                  // Image Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount:
                        uploadedImages.isEmpty ? 1 : uploadedImages.length + 1,
                    itemBuilder: (context, index) {
                      if (index < uploadedImages.length) {
                        return _buildUploadedImageTile(uploadedImages[index]);
                      } else if (uploadedImages.length < 10) {
                        return _buildImageUploadTile();
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),

                  // Upload Instructions

                  SizedBox(height: Get.height * 0.005),
                  CustomTextWidget(
                    title: 'Upload up to 10 images',
                    fontSize: screenHeight * 0.012,
                    color: AppColors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
            SizedBox(height: Get.height * 0.02),

            // Work Description Section
            CustomTextWidget(
              title: 'Technician Notes/ Work Description',
              fontSize: screenHeight * 0.014,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
            SizedBox(height: Get.height * 0.010),
            CustomTextFieldWidget(
              hintText: "Enter notes..",
              keyboardType: TextInputType.text,
              controller: _workDescriptionController,
              maxLines: 3,
            ),

            SizedBox(height: Get.height * 0.01),

            // Work Status Section
            CustomTextWidget(
              title: 'Update Work Status',
              fontSize: screenHeight * 0.014,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
            SizedBox(height: Get.height * 0.010),

            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Get.width * 0.03,
                vertical: Get.height * 0.015,
              ),
              decoration: BoxDecoration(
                color: AppColors.whiteLight,
                borderRadius: BorderRadius.circular(screenWidth4),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomTextWidget(
                        title: 'Pending',
                        fontSize: screenHeight * 0.016,
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      Row(
                        children: [
                          CustomTextWidget(
                            title: selectedWorkStatus,
                            fontSize: screenHeight * 0.016,
                            color: AppColors.black,
                          ),
                          kWidth(0.02),
                          Icon(Icons.arrow_right,
                              color: AppColors.black,
                              size: screenHeight * 0.030),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: Get.height * 0.02),

            // Amount Charged Section
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Get.width * 0.03,
                vertical: Get.height * 0.015,
              ),
              decoration: BoxDecoration(
                color: AppColors.whiteLight,
                borderRadius: BorderRadius.circular(screenWidth4),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomTextWidget(
                        title: 'Amount Charged',
                        fontSize: screenHeight * 0.016,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                      Row(
                        children: [
                          CustomTextWidget(
                            title: '\$200',
                            fontSize: screenHeight * 0.016,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                          kWidth(0.02),
                          SizedBox(
                              height: Get.height * 0.010,
                              child: Switch(
                                  padding: EdgeInsets.all(2),
                                  value: false,
                                  onChanged: (value) => !value))
                        ],
                      ),
                    ],
                  ),
                  Divider(
                    color: AppColors.lightGrey,
                    thickness: 1,
                    height: Get.height * 0.02,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomTextWidget(
                        title: 'Paid Status',
                        fontSize: screenHeight * 0.016,
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      CustomTextWidget(
                        title: 'Not Paid',
                        fontSize: screenHeight * 0.016,
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: Get.height * 0.03),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: CustomButtonWidget(
                buttonTitle: 'Submit Updates',
                buttonShape: "rect",
                buttonColor: AppColors.secondaryColor,
                buttonTextColor: AppColors.white,
                onPressed: _submitUpdates,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadTile() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.lightGrey,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              HugeIcons.strokeRoundedCloudUpload,
              size: screenHeight * 0.025,
              color: AppColors.black,
            ),
            kHeight(0.01),
            const CustomTextWidget(
              title: 'Drag & Drop or',
              fontSize: 12,
              color: AppColors.black,
              fontWeight: FontWeight.w600,
            ),
            GestureDetector(
              onTap: _pickImages,
              child: const CustomTextWidget(
                title: ' Tap to upload',
                fontSize: 12,
                color: AppColors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedImageTile(File imageFile) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.lightGrey, style: BorderStyle.solid),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          imageFile,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage();
    if (images.isNotEmpty && uploadedImages.length + images.length <= 10) {
      setState(() {
        uploadedImages.addAll(images.map((xFile) => File(xFile.path)));
      });
    }
  }

  Widget _ticketDetailsCard() {
    return Container(
      padding: EdgeInsets.all(screenWidth4),
      decoration: BoxDecoration(
        color: AppColors.whiteLight,
        borderRadius: BorderRadius.circular(screenWidth4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ticket Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CustomTextWidget(
                title: '#TK-RET2458',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Get.width * 0.025,
                  vertical: Get.height * 0.005,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const CustomTextWidget(
                  title: 'Pending',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: Get.height * 0.01),

          // Property Details
          CustomTextWidget(
            title: 'Skyskiw Apartment, Block B-202',
            fontSize: screenHeight * 0.016,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
          SizedBox(height: Get.height * 0.005),
          const CustomTextWidget(
            title: 'Plumbing • Pipe Leakage',
            fontSize: 12,
            color: AppColors.black,
          ),
          SizedBox(height: Get.height * 0.005),
          const CustomTextWidget(
            title: 'Reported On: May 20, 2025',
            fontSize: 12,
            color: AppColors.darkGrey,
          ),
          const CustomTextWidget(
            title: 'Deadline: May 22, 2025',
            fontSize: 12,
            color: AppColors.darkGrey,
          ),
        ],
      ),
    );
  }

  void _submitUpdates() {
    // Handle submit updates logic
    Get.snackbar(
      'Success',
      'Updates submitted successfully',
      backgroundColor: AppColors.onlineGreen,
      colorText: AppColors.white,
    );
  }

  @override
  void dispose() {
    _workDescriptionController.dispose();
    super.dispose();
  }
}
