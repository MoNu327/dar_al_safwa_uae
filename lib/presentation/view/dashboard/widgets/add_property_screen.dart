import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/controller/agent_registered_property_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/custom_size.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({Key? key}) : super(key: key);

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final TextEditingController propertyNameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final controller = Get.put(AgentRegisteredPropertyController());

  String selectedStatus = 'Available';
  String selectedLocation = 'Kochi Kerala';

  @override
  void initState() {
    super.initState();
    propertyNameController.text = 'Sun-view Apartment, Flat 302';
    locationController.text = 'Kochi Kerala';
    priceController.text = '13526.19';
    descriptionController.text = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth4,
                vertical: screenHeight2,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.black,
                      size: iconSize,
                    ),
                  ),
                  kWidth(0.03),
                  Expanded(
                      child: CustomTextWidget(
                    title: "Add Property",
                    fontSize: appBarTitles,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  )),
                  Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth4,
                        vertical: screenHeight1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: CustomTextWidget(
                          title: 'Submit',
                          color: AppColors.secondaryColor,
                          fontSize: tagTitle,
                          fontWeight: FontWeight.w600,
                        ),
                      )),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: screenWidth4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    kHeight(0.02),

                    // Image Upload Section
                    Row(
                      children: [
                        _buildImageUploadBox(),
                        kWidth(0.02),
                        _buildImageUploadBox(),
                        kWidth(0.02),
                        _buildImageUploadBox(),
                      ],
                    ),

                    kHeight(0.03),

                    // Property Name
                    _buildSectionTitle('Property Name'),
                    kHeight(0.01),
                    _buildTextField(
                      controller: propertyNameController,
                      hintText: 'Enter property name',
                    ),

                    kHeight(0.025),

                    // Location
                    _buildSectionTitle('Location'),
                    kHeight(0.01),
                    _buildDropdownField(
                      value: selectedLocation,
                      onChanged: (value) {
                        setState(() {
                          selectedLocation = value!;
                        });
                      },
                      items: [
                        'Kochi Kerala',
                        'Mumbai Maharashtra',
                        'Delhi NCR'
                      ],
                    ),

                    kHeight(0.025),

                    // Price
                    Row(
                      children: [
                        _buildSectionTitle('Price'),
                        Text(
                          ' *',
                          style: TextStyle(
                            fontSize: H18,
                            color: AppColors.redColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    kHeight(0.01),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: priceController,
                            hintText: 'Enter price',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        kWidth(0.03),
                        Obx(() => Container(
                              decoration: BoxDecoration(
                                color: AppColors.lightGrey2,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.lightGrey),
                              ),
                              child: DropdownButton<String>(
                                value: controller.selectedCurrency.value,
                                onChanged: controller.updateCurrency,
                                underline: Container(),
                                // isExpanded: true,
                                items:
                                    controller.currencies.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth3),
                                      child: Text(
                                        value,
                                        style: TextStyle(
                                          fontSize: H18,
                                          color: AppColors.black600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                icon: Padding(
                                  padding: EdgeInsets.only(right: screenWidth3),
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: AppColors.black600,
                                  ),
                                ),
                              ),
                            )),
                      ],
                    ),

                    kHeight(0.025),

                    // Property Status
                    _buildSectionTitle('Property Status'),
                    kHeight(0.015),
                    Row(
                      children: [
                        _buildRadioOption('Available'),
                        kWidth(0.05),
                        _buildRadioOption('Sold Out'),
                        kWidth(0.05),
                        _buildRadioOption('Few Units Left'),
                      ],
                    ),

                    kHeight(0.025),

                    // Description
                    _buildSectionTitle('Describe the Issue'),
                    kHeight(0.01),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.lightGrey.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            maxLength: 500,
                            controller: descriptionController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Write your message here...',
                              hintStyle: TextStyle(
                                color: AppColors.darkGrey,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(screenWidth4),
                            ),
                            onChanged: (value) {},
                          ),
                        ],
                      ),
                    ),

                    kHeight(0.05),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadBox() {
    return Expanded(
      child: Container(
        height: screenHeight * 0.12,
        decoration: BoxDecoration(
          color: AppColors.lightGrey2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightGrey.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              color: AppColors.darkGrey,
              size: iconSize,
            ),
            kHeight(0.01),
            CustomTextWidget(
              title: 'Add Image',
              fontSize: detailContentTitle,
              color: AppColors.darkGrey,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return CustomTextWidget(
      title: title,
      fontSize: H18,
      fontWeight: FontWeight.w600,
      color: AppColors.black,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGrey.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.darkGrey,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth4,
            vertical: screenHeight15,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required Function(String?) onChanged,
    required List<String> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGrey.withOpacity(0.3)),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth4,
            vertical: screenHeight15,
          ),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
              value: item,
              child: CustomTextWidget(
                title: item,
                fontSize: 14,
                color: AppColors.black,
              ));
        }).toList(),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: AppColors.black600,
        ),
      ),
    );
  }

  Widget _buildRadioOption(String value) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedStatus = value;
        });
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: AppColors.lightGrey2,
            borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: screenHeight2,
              height: screenHeight2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selectedStatus == value
                      ? AppColors.secondaryColor
                      : AppColors.lightGrey,
                  width: 2,
                ),
              ),
              child: selectedStatus == value
                  ? Center(
                      child: Container(
                        width: screenHeight1,
                        height: screenHeight1,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
            kWidth(0.02),
            Text(
              value,
              style: TextStyle(
                fontSize: tagTitle,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double get screenHeight15 => screenHeightFactor(0.015);
}
