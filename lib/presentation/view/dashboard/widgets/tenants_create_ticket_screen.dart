import 'dart:io';
import 'package:dar_al_safwa/data/model/compliant_model.dart';
import 'package:dar_al_safwa/data/model/tenant_complain_from_model.dart';
import 'package:dar_al_safwa/data/model/tenant_compliant_model.dart';
import 'package:dar_al_safwa/data/model/tenant_compliant_subtitle.dart';
import 'package:dar_al_safwa/data/repositories/api_services.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/controller/tenant_complaint_register_controller.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/controller/tenant_tickets_controller.dart' show TenantsTicketsController;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_elevated_button.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_formfield_widget.dart';

class TenantsCreateTicketScreen extends StatefulWidget {
  final String propertyName;
  final int propertyId;
  final int unitAddressId;
  final String userId;

  const TenantsCreateTicketScreen({
    super.key,
    required this.propertyName,
    required this.propertyId,
    required this.unitAddressId,
    required this.userId,
  });

  @override
  State<TenantsCreateTicketScreen> createState() =>
      _TenantsCreateTicketScreenState();
}

class _TenantsCreateTicketScreenState extends State<TenantsCreateTicketScreen> {
  final TenantComplaintRegisterController complaintController =
      Get.put(TenantComplaintRegisterController());

       final TenantsTicketsController fetchComplaintsControler =
      Get.find<TenantsTicketsController>();

  String? selectedCategory;
  String? selectedSubcategory;
  final TextEditingController _issueController = TextEditingController();
  List<File> uploadedImages = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    complaintController.getComplaintList(); // Fetch categories from API
  }
   Future<void> _loadComplaints() async {
  try {
    await fetchComplaintsControler.fetchTenantComplaints();
  } catch (e) {
    debugPrint("Error loading complaints: $e");
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
          title: "Post Ticket",
          fontSize: Get.height * 0.022,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      ),
      body: Obx(
        () => SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Display
              _buildSectionHeader('Property'),
              kHeight(0.01),
              Container(
                padding: EdgeInsets.all(screenWidth2),
                decoration: BoxDecoration(
                  color: AppColors.whiteLight,
                  border:
                      Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: CustomTextWidget(
                  title: "${widget.propertyName} (ID: ${widget.propertyId})",
                  fontSize: Get.height * 0.016,
                  color: AppColors.black,
                ),
              ),
              SizedBox(height: screenHeight2),

              // Category Dropdown
              _buildSectionHeader('Category'),
              kHeight(0.01),
              complaintController.isLoadingCompliantList.value
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDropdown(
                      value: selectedCategory,
                      items: complaintController.complaintCategory
                          .map((e) => e.name ?? '')
                          .toList(),
                      hintText: 'Select Category',
                      onChanged: (value) async {
                        setState(() {
                          selectedCategory = value;
                          selectedSubcategory = null;
                        });

                        final selectedItem = complaintController
                            .complaintCategory
                            .firstWhereOrNull((item) => item.name == value);

                        if (selectedItem != null) {
                          complaintController.selectedComplaintId.value =
                              selectedItem.id ?? 0;
                          debugPrint(
                              "✅ Selected Category ID: ${complaintController.selectedComplaintId.value}");
                          await complaintController.getSubCompliantList();
                        } else {
                          debugPrint("❌ No category found for $value");
                        }
                      },
                    ),
              SizedBox(height: screenHeight2),

              // Subcategory Dropdown
              if (selectedCategory != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Subcategory'),
                    kHeight(0.01),
                    complaintController.isLoadingSubtitleCompliantList.value
                        ? const Center(child: CircularProgressIndicator())
                        : _buildDropdown(
                            value: selectedSubcategory,
                            items: complaintController.subtitleComplaintCategory
                                .map((e) => e.name ?? '')
                                .toList(),
                            hintText: 'Select Subcategory',
                            onChanged: (value) async {

                             
                              
                              setState(() {
                                selectedSubcategory = value;
                              });

                              final selectedItem = complaintController
                                  .subtitleComplaintCategory
                                  .firstWhereOrNull(
                                      (item) => item.name == value);




                              if (selectedItem != null) {
                                complaintController
                                        .selectedSubtitleComplaintId.value =
                                    selectedItem.id ?? 0;
                                debugPrint(
                                    "✅ Selected Subcategory ID: ${complaintController.selectedSubtitleComplaintId.value}");
                              } else {
                                debugPrint("❌ No subcategory found for $value");
                                await complaintController
                                    .getSubCompliantList();
                              }
                            },
                          ),
                    SizedBox(height: screenHeight2),
                  ],
                ),

              // Issue Description
              _buildSectionHeader('Describe the issue'),
              kHeight(0.01),
              CustomTextFieldWidget(
                keyboardType: TextInputType.text,
                controller: _issueController,
                hintText: 'Write your message here...',
                maxLines: 5,
                isBorderNeeded: true,
              ),
              SizedBox(height: screenHeight2),

              // Upload Images
              _buildSectionHeader('Upload Photos (Optional)'),
              kHeight(0.01),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...uploadedImages
                      .map((image) => _buildImagePreview(image))
                      .toList(),
                  _buildAddImageButton(),
                ],
              ),
              SizedBox(height: screenHeight4),

              // Submit Button
              CustomButtonWidget(
                onPressed: complaintController.isLoadingSubmitCompliant.value
                    ? null
                    : _submitTicket,
                buttonTitle:
                    complaintController.isLoadingSubmitCompliant.value
                        ? "Submitting..."
                        : "Submit Ticket",
                buttonColor: AppColors.secondaryColor,
                buttonTextColor: AppColors.white,
                buttonShape: "rect",
                buttonHeight: Get.height * 0.06,
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    String? hintText,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteLight,
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: EdgeInsets.symmetric(horizontal: screenWidth1),
      child: DropdownButton<String>(
        padding: EdgeInsets.symmetric(horizontal: screenWidth1),
        value: (value != null && items.contains(value)) ? value : null,
        isExpanded: true,
        underline: Container(),
        hint: CustomTextWidget(
          title: hintText ?? 'Select',
          fontSize: Get.height * 0.016,
          color: AppColors.black600,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: CustomTextWidget(
              title: item,
              fontSize: Get.height * 0.016,
              color: AppColors.black,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildAddImageButton() {
  return GestureDetector(
    onTap: _showImageSourceOptions,  // <-- Call bottom sheet
    child: Container(
      width: screenWidth * 0.30,
      height: screenHeight * 0.15,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add, size: 24, color: AppColors.black600),
          SizedBox(height: screenHeight05),
          CustomTextWidget(
            title: 'Add image',
            fontSize: Get.height * 0.014,
            color: AppColors.black600,
          ),
        ],
      ),
    ),
  );
}
void _showImageSourceOptions() {
  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppColors.secondaryColor),
            title: const Text("Take Photo"),
            onTap: () async {
              await _pickFromCamera();
              Get.back();
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: AppColors.secondaryColor),
            title: const Text("Choose from Gallery"),
            onTap: () async {
              await _pickFromGallery();
              Get.back();
            },
          ),
        ],
      ),
    ),
  );
}
Future<void> _pickFromCamera() async {
  final pickedFile = await _picker.pickImage(source: ImageSource.camera);
  if (pickedFile != null) {
    setState(() {
      uploadedImages.add(File(pickedFile.path));
    });
  }
}

Future<void> _pickFromGallery() async {
  final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    setState(() {
      uploadedImages.add(File(pickedFile.path));
    });
  }
}

  

  Widget _buildImagePreview(File image) {
    return Stack(
      children: [
        Container(
          width: screenWidth * 0.30,
          height: screenHeight * 0.15,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.grey.withValues(alpha: 0.1),
            image: DecorationImage(
              image: FileImage(image),
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
                uploadedImages.remove(image);
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(screenWidth5),
              child: const Icon(Icons.close, size: 16, color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        uploadedImages.add(File(pickedFile.path));
      });
    }
  }

 Future<void> _submitTicket() async {
  if (selectedCategory == null ||
      selectedSubcategory == null ||
      _issueController.text.isEmpty) {
    Get.snackbar(
      'Error',
      'Please fill all required fields',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.redColor,
      colorText: AppColors.white,
    );
    return;
  }

  complaintController.complaintDetailsController.text =
      _issueController.text.trim();

  await complaintController.submitCompliant(
    propertyName: widget.propertyName,
    propertyId: widget.propertyId,
    unitAddressId: widget.unitAddressId,
    uploadedImages: uploadedImages,
  );

  if (complaintController.isLoadingSubmitCompliant.value) {
    Get.snackbar(
      'Submitting',
      'Please wait while we submit your ticket...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.blueColor,
      colorText: AppColors.white,
    );
  } else {
    Get.snackbar(
      'Success',
      'Ticket submitted successfully!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.onlineGreen,
      colorText: AppColors.white,
    );
   _loadComplaints(); // Refresh complaints list
    Navigator.pop(context); // Close the screen after submission
  }

  // if (!complaintController.isLoadingSubmitCompliant.value) {
  //   Get.back();
  // }
}
}
