import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_elevated_button.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_formfield_widget.dart';

class TenantsCreateTicketScreen extends StatefulWidget {
  const TenantsCreateTicketScreen({super.key});

  @override
  State<TenantsCreateTicketScreen> createState() =>
      _TenantsCreateTicketScreenState();
}

class _TenantsCreateTicketScreenState extends State<TenantsCreateTicketScreen> {
  String? selectedProperty = 'Sun-view Apartment, Flat 302';
  String? selectedCategory;
  String? selectedSubcategory;
  final TextEditingController _issueController = TextEditingController();
  List<String> uploadedImages = [];

  // Sample data
  final List<String> properties = [
    'Sun-view Apartment, Flat 302',
    'Ocean-view Villa, Unit 12',
    'Mountain Retreat, Cabin 5'
  ];

  final Map<String, List<String>> categories = {
    'Select a category': [],
    'Maintenance': ['Plumbing', 'Electrical', 'HVAC'],
    'Cleaning': ['Regular', 'Deep', 'Carpet'],
    'Security': ['Access', 'Cameras', 'Locks'],
  };

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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Icon(
              Icons.info_outline,
              color: AppColors.black,
            ),
          )
        ],
        title: CustomTextWidget(
          title: "Post Ticket",
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
            // Select Property
            _buildSectionHeader('Select Property'),
            kHeight(0.01),
            _buildDropdown(
              value: selectedProperty,
              items: properties,
              onChanged: (value) {
                setState(() {
                  selectedProperty = value;
                });
              },
            ),
            SizedBox(height: screenHeight2),

            // Category
            _buildSectionHeader('Category'),
            kHeight(0.01),
            _buildDropdown(
              value: selectedCategory ?? 'Select a category',
              items: categories.keys.toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory =
                      value == 'Select a category' ? null : value;
                  selectedSubcategory = null;
                });
              },
            ),
            SizedBox(height: screenHeight2),

            // Subcategory (only shown when category is selected)
            if (selectedCategory != null &&
                selectedCategory != 'Select a category')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Subcategory'),
                  kHeight(0.01),
                  _buildDropdown(
                    value: selectedSubcategory,
                    items: categories[selectedCategory] ?? [],
                    hintText: 'Select subcategory',
                    onChanged: (value) {
                      setState(() {
                        selectedSubcategory = value;
                      });
                    },
                  ),
                  SizedBox(height: screenHeight2),
                ],
              ),

            // Describe the issue
            _buildSectionHeader('Describe the issue'),
            kHeight(0.01),
            CustomTextFieldWidget(
              keyboardType: TextInputType.text,
              controller: _issueController,
              hintText: 'Write your message here...',
              maxLines: 5,
              // pad: EdgeInsets.all(screenWidth1),
              isBorderNeeded: true,

              // borderColor: AppColors.grey.withValues(alpha: 0.3),
            ),
            SizedBox(height: screenHeight2),

            // Upload Photos
            _buildSectionHeader('Upload Photos (Optional)'),
            kHeight(0.01),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...uploadedImages.map((image) => _buildImagePreview(image)),
                _buildAddImageButton(),
              ],
            ),
            SizedBox(height: screenHeight4),

            // Submit Button
            CustomButtonWidget(
              onPressed: _submitTicket,
              buttonTitle: "Submit Ticket",
              buttonColor: AppColors.secondaryColor,
              buttonTextColor: AppColors.white,
              buttonShape: "rect",
              buttonHeight: Get.height * 0.06,
            ),
          ],
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
        value: value,
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
      onTap: () async {
        setState(() {
          uploadedImages.add('placeholder_${uploadedImages.length + 1}');
        });
      },
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
            Icon(Icons.add, size: 24, color: AppColors.black600),
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

  Widget _buildImagePreview(String image) {
    return Stack(
      children: [
        Container(
          width: screenWidth * 0.30,
          height: screenHeight * 0.15,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.grey.withValues(alpha: 0.1),
          ),
          child: Icon(Icons.image, size: 40, color: AppColors.grey),
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
              child: Icon(Icons.close, size: 16, color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }

  void _submitTicket() {
    if (selectedProperty == null ||
        selectedCategory == null ||
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

    // TODO: Implement ticket submission logic
    final ticketData = {
      'property': selectedProperty,
      'category': selectedCategory,
      'subcategory': selectedSubcategory,
      'issue': _issueController.text,
      'images': uploadedImages,
    };

    debugPrint('Ticket submitted: $ticketData');
    Get.back();
    Get.snackbar(
      'Success',
      'Ticket submitted successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.onlineGreenDark,
      colorText: AppColors.white,
    );
  }
}
