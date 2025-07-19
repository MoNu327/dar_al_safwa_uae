import 'dart:io';
import 'package:dar_al_safwa/presentation/view/dashboard/controller/rectify_tickets_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_formfield_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_text_widget.dart';

class RectifyTicketsScreen extends StatelessWidget {
  final String complaintId; // Pass complaintId dynamically

  const RectifyTicketsScreen({super.key, required this.complaintId});

  @override
  Widget build(BuildContext context) {
    final RectifyTicketsController controller =
        Get.put(RectifyTicketsController());

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const CustomTextWidget(
          title: 'Rectify Tickets',
          fontSize: 18,
          color: AppColors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Get.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ticketDetailsCard(),
            SizedBox(height: Get.height * 0.015),

            // ✅ Image Upload Section
            _imageUploadSection(controller),
            SizedBox(height: Get.height * 0.02),

            // ✅ Work Description
            CustomTextWidget(
              title: 'Technician Notes / Work Description',
              fontSize: screenHeight * 0.014,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
            SizedBox(height: Get.height * 0.010),
            CustomTextFieldWidget(
              hintText: "Enter notes..",
              keyboardType: TextInputType.text,
              controller: controller.workDescriptionController,
              maxLines: 3,
            ),
            SizedBox(height: Get.height * 0.01),

            // ✅ Work Status
            CustomTextWidget(
              title: 'Update Work Status',
              fontSize: screenHeight * 0.014,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
            SizedBox(height: Get.height * 0.010),
            _workStatusDropdown(controller),
            SizedBox(height: Get.height * 0.02),

            // ✅ Amount Charged Section
            _amountChargedSection(controller),
            SizedBox(height: Get.height * 0.03),

            // ✅ Submit Button
            SizedBox(
              width: double.infinity,
              child: CustomButtonWidget(
                buttonTitle: 'Submit Updates',
                buttonShape: "rect",
                buttonColor: AppColors.secondaryColor,
                buttonTextColor: AppColors.white,
                onPressed: () => controller.submitUpdates(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Work Status Dropdown
  Widget _workStatusDropdown(RectifyTicketsController controller) {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedWorkStatus.value,
          items: ['Pending', 'In Progress', 'Completed']
              .map((status) =>
                  DropdownMenuItem(value: status, child: Text(status)))
              .toList(),
          onChanged: (value) {
            if (value != null) controller.changeWorkStatus(value);
          },
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(screenWidth4),
            ),
          ),
        ));
  }

  /// Amount Charged Section
  Widget _amountChargedSection(RectifyTicketsController controller) {
    return Obx(() => Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.whiteLight,
              borderRadius: BorderRadius.circular(screenWidth4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CustomTextWidget(
                      title: 'Amount Charged',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: controller.amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '\$0',
                        border: UnderlineInputBorder(),
                      ),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CustomTextWidget(
                    title: 'Amount Changed?',
                    fontSize: 14,
                    color: AppColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  Switch(
                    value: controller.amountChanged.value,
                    onChanged: controller.toggleAmountChanged,
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CustomTextWidget(
                      title: 'Paid Status',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black),
                  Row(
                    children: [
                      CustomTextWidget(
                          title:
                              controller.isPaid.value ? 'Paid' : 'Not Paid',
                          fontSize: 16,
                          color: AppColors.black),
                      Switch(
                        value: controller.isPaid.value,
                        onChanged: controller.togglePaidStatus,
                      )
                    ],
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  /// Image Upload Section
  Widget _imageUploadSection(RectifyTicketsController controller) {
    return Container(
      padding: EdgeInsets.all(Get.width * 0.04),
      decoration: BoxDecoration(
        color: AppColors.whiteLight,
        borderRadius: BorderRadius.circular(screenWidth4),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CustomTextWidget(
          title: 'Upload Work Images (Before / After)',
          fontSize: screenHeight * 0.014,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        SizedBox(height: Get.height * 0.015),
        Obx(() => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: controller.uploadedImages.isEmpty
                  ? 1
                  : controller.uploadedImages.length + 1,
              itemBuilder: (context, index) {
                if (index < controller.uploadedImages.length) {
                  return _buildUploadedImageTile(controller.uploadedImages[index]);
                } else {
                  return _buildImageUploadTile(controller);
                }
              },
            )),
        SizedBox(height: Get.height * 0.005),
        CustomTextWidget(
          title: 'Upload up to 10 images',
          fontSize: screenHeight * 0.012,
          color: AppColors.black,
          fontWeight: FontWeight.w600,
        ),
      ]),
    );
  }

  Widget _buildImageUploadTile(RectifyTicketsController controller) {
    return GestureDetector(
      onTap: controller.pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightGrey),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(HugeIcons.strokeRoundedCloudUpload, size: 24),
            const CustomTextWidget(title: 'Tap to upload', fontSize: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedImageTile(File imageFile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.file(imageFile, fit: BoxFit.cover),
    );
  }

  Widget _ticketDetailsCard() {
    return Container(
      padding: EdgeInsets.all(screenWidth4),
      decoration: BoxDecoration(
        color: AppColors.whiteLight,
        borderRadius: BorderRadius.circular(screenWidth4),
      ),
      child: const CustomTextWidget(title: '#TK-RET2458 | Plumbing Issue'),
    );
  }
}
