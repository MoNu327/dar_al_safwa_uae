import 'dart:io';
import 'package:dar_al_safwa/presentation/view/dashboard/controller/tenant_complaint_register_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_elevated_button.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_formfield_widget.dart';

class TenantsCreateTicketScreen extends StatefulWidget {
  const TenantsCreateTicketScreen({super.key, required String propertyName});

  @override
  State<TenantsCreateTicketScreen> createState() =>
      _TenantsCreateTicketScreenState();
}

class _TenantsCreateTicketScreenState extends State<TenantsCreateTicketScreen> {
  final TenantComplaintRegisterController controller =
      Get.put(TenantComplaintRegisterController());

  String? selectedProperty = 'Sun-view Apartment, Flat 302';
  List<File> uploadedImages = [];

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
          title: "Post Ticket",
          fontSize: Get.height * 0.022,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      ),
      body: Obx(() {
        return controller.isLoadingCompliantList.value
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(screenWidth4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Select Property'),
                    kHeight(0.01),
                    _buildPropertyDropdown(),
                    SizedBox(height: screenHeight2),

                    // Complaint Category
                    _buildSectionHeader('Category'),
                    kHeight(0.01),
                    _buildComplaintCategoryDropdown(controller),
                    SizedBox(height: screenHeight2),

                    // Subcategory
                    if (controller.selectedComplaintId.value != 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Subcategory'),
                          kHeight(0.01),
                          _buildSubComplaintDropdown(controller),
                          SizedBox(height: screenHeight2),
                        ],
                      ),

                    _buildSectionHeader('Describe the issue'),
                    kHeight(0.01),
                    CustomTextFieldWidget(
                      keyboardType: TextInputType.text,
                      controller: controller.complaintDetailsController,
                      hintText: 'Write your message here...',
                      maxLines: 5,
                      isBorderNeeded: true,
                    ),
                    SizedBox(height: screenHeight2),

                    _buildSectionHeader('Upload Photos (Optional)'),
                    kHeight(0.01),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...uploadedImages
                            .map((file) => _buildImagePreview(file)),
                        _buildAddImageButton(),
                      ],
                    ),
                    SizedBox(height: screenHeight4),

                    CustomButtonWidget(
                      onPressed: () {
                        controller.submitCompliant(selectedProperty ?? '');
                      },
                      buttonTitle: "Submit Ticket",
                      buttonColor: AppColors.secondaryColor,
                      buttonTextColor: AppColors.white,
                      buttonShape: "rect",
                      buttonHeight: Get.height * 0.06,
                    ),
                  ],
                ),
              );
      }),
    );
  }

  Widget _buildSectionHeader(String title) {
    return CustomTextWidget(
      title: title,
      fontSize: Get.height * 0.018,
      fontWeight: FontWeight.w600,
      color: AppColors.black,
    );
  }

  /// ✅ Dropdown for Property
  Widget _buildPropertyDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteLight,
        border: Border.all(color: AppColors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: EdgeInsets.symmetric(horizontal: screenWidth1),
      child: DropdownButton<String>(
        value: selectedProperty,
        isExpanded: true,
        underline: Container(),
        items: [
          'Sun-view Apartment, Flat 302',
          'Ocean-view Villa, Unit 12',
          'Mountain Retreat, Cabin 5'
        ].map((String property) {
          return DropdownMenuItem(
            value: property,
            child: CustomTextWidget(
              title: property,
              fontSize: Get.height * 0.016,
              color: AppColors.black,
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedProperty = value;
          });
        },
      ),
    );
  }

  /// ✅ Complaint Category Dropdown (API Data)
 Widget _buildComplaintCategoryDropdown(TenantComplaintRegisterController controller) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.whiteLight,
      border: Border.all(color: AppColors.grey.withOpacity(0.3)),
      borderRadius: BorderRadius.circular(14),
    ),
    padding: EdgeInsets.symmetric(horizontal: screenWidth1),
    child: Obx(() {
      return DropdownButton<int>(
        value: controller.selectedComplaintId.value == 0
            ? null
            : controller.selectedComplaintId.value,
        isExpanded: true,
        underline: Container(),
        hint: const Text('Select a category'),
        items: controller.complaintCategory.map((category) {
          return DropdownMenuItem<int>(
            value: category.id,
            child: Text(category.name), // ✅ Correct field name
          );
        }).toList(),
        onChanged: (value) {
          controller.selectedComplaintId.value = value ?? 0;
          controller.getSubCompliantList();
        },
      );
    }),
  );
}



  /// ✅ Sub-Complaint Dropdown (API Data)
 Widget _buildSubComplaintDropdown(TenantComplaintRegisterController controller) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.whiteLight,
      border: Border.all(color: AppColors.grey.withOpacity(0.3)),
      borderRadius: BorderRadius.circular(14),
    ),
    padding: EdgeInsets.symmetric(horizontal: screenWidth1),
    child: Obx(() {
      if (controller.isLoadingSubtitleCompliantList.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.subtitleComplaintCategory.isEmpty) {
        return const Text('No subcategories found');
      }
      return DropdownButton<int>(
        value: controller.selectedSubtitleComplaintId.value == 0
            ? null
            : controller.selectedSubtitleComplaintId.value,
        isExpanded: true,
        underline: Container(),
        hint: const Text('Select subcategory'),
        items: controller.subtitleComplaintCategory.map((subCategory) {
          return DropdownMenuItem<int>(
            value: subCategory.id,
            child: Text(subCategory.name), // ✅ Correct field
          );
        }).toList(),
        onChanged: (value) {
          controller.selectedSubtitleComplaintId.value = value ?? 0;
        },
      );
    }),
  );
}

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: () async {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);

        if (image != null) {
          setState(() {
            uploadedImages.add(File(image.path));
          });
        }
      },
      child: Container(
        width: screenWidth * 0.30,
        height: screenHeight * 0.15,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 24, color: AppColors.black600),
            SizedBox(height: screenHeight05),
            const Text('Add image'),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(File file) {
    return Stack(
      children: [
        Container(
          width: screenWidth * 0.30,
          height: screenHeight * 0.15,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            image: DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                uploadedImages.remove(file);
              });
            },
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
