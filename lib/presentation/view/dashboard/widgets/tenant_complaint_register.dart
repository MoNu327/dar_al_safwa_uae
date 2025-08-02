import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/controller/tenant_complaint_register_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_appbar_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_elevated_button.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_snackbar.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class TenantComplaintRegister extends StatelessWidget {
  final String propertyName;
  final int propertyId;
  final int unitAddressId;

  TenantComplaintRegister({
    super.key,
    required this.propertyName,
    required this.propertyId,
    required this.unitAddressId,
  });

  final TenantComplaintRegisterController tenantComplaintRegisterController =
      Get.put(TenantComplaintRegisterController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(
        title: 'Register Complaint',
        titleFontSize: screenHeight2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: screenHeight2,
            horizontal: screenWidth3,
          ),
          child: Obx(() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// ✅ Property Name Display
                CustomTextWidget(
                  title: 'Property: $propertyName',
                  fontSize: screenHeight * 0.02,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryColor,
                ),
                kHeight(0.02),

                /// Header Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextWidget(
                      title: 'Property Complaint',
                      fontSize: screenHeight2,
                      color: AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    kHeight(0.014),
                    CustomTextWidget(
                      maxLines: 2,
                      title:
                          'Register your complaint about the property you rent or own. Our team will address it promptly.',
                      fontSize: screenHeight * 0.014,
                      color: AppColors.black800,
                    ),
                  ],
                ),
                kHeight(0.025),

                /// ✅ Complaint Type Dropdown
                buildFieldLabel('Select Complaint'),
                kHeight(0.005),
                tenantComplaintRegisterController.isLoadingCompliantList.value
                    ? _buildLoadingIndicator()
                    : customDropdown(
                        selectedValue: tenantComplaintRegisterController
                            .selectedComplaintType.value,
                        items: tenantComplaintRegisterController
                            .complaintCategory
                            .map((item) => item.name.toString())
                            .toList(),
                        hintText: 'Select Complaint Type',
                        onChanged: (value) {
                          _onComplaintTypeSelected(value);
                        },
                      ),
                kHeight(0.02),

                /// ✅ Sub-Complaint Dropdown
                buildFieldLabel('Select Sub-Complaint'),
                kHeight(0.005),
                tenantComplaintRegisterController
                        .isLoadingSubtitleCompliantList.value
                    ? _buildLoadingIndicator()
                    : customDropdown(
                        selectedValue: tenantComplaintRegisterController
                            .selectedSubComplaintType.value,
                        items: tenantComplaintRegisterController
                            .subtitleComplaintCategory
                            .map((item) => item.name.toString())
                            .toList(),
                        hintText: 'Select Sub-Complaint',
                        onChanged: (value) {
                          _onSubComplaintTypeSelected(value);
                        },
                      ),
                kHeight(0.02),

                /// ✅ Complaint Details Text Area
                buildFieldLabel('Complaint Details'),
                kHeight(0.005),
                TextField(
                  controller: tenantComplaintRegisterController
                      .complaintDetailsController,
                  maxLines: 8,
                  style: TextStyle(
                    color: AppColors.black800,
                    fontSize: screenHeight * 0.015,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter complaint details...',
                    hintStyle: TextStyle(
                      color: AppColors.black800,
                      fontSize: screenHeight * 0.015,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth3,
                      vertical: screenHeight1,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.splashBackgroundColor,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.splashBackgroundColor,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryColor,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                kHeight(0.03),

                /// ✅ Submit Button
                CustomButtonWidget(
                  childWidgetLoader: tenantComplaintRegisterController
                      .isLoadingSubmitCompliant.value,
                  buttonTitle: 'REGISTER COMPLAINT',
                  buttonShape: "rect",
                  fontSize: tagTitle,
                  buttonColor: AppColors.secondaryColor,
                  onPressed: _onSubmit,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// Helper - Loading Indicator
  Widget _buildLoadingIndicator() {
    return Center(
      child: LoadingAnimationWidget.threeRotatingDots(
        size: 20,
        color: AppColors.primaryColor,
      ),
    );
  }

  /// On selecting complaint type
  void _onComplaintTypeSelected(String? value) {
    final selectedIndex = tenantComplaintRegisterController.complaintCategory
        .indexWhere((item) => item.name == value);
    if (selectedIndex != -1) {
      tenantComplaintRegisterController.selectedComplaintType.value = value!;
      tenantComplaintRegisterController.selectedComplaintId.value =
          tenantComplaintRegisterController.complaintCategory[selectedIndex].id;
    }
    tenantComplaintRegisterController.selectedSubComplaintType.value = '';
    debugPrint(
        'Selected Complaint Type: ${tenantComplaintRegisterController.selectedComplaintType.value}, ID: ${tenantComplaintRegisterController.selectedComplaintId.value}');
    tenantComplaintRegisterController.getSubCompliantList();
  }

  /// On selecting sub-complaint type
  void _onSubComplaintTypeSelected(String? value) {
    final selectedIndex = tenantComplaintRegisterController
        .subtitleComplaintCategory
        .indexWhere((item) => item.name == value);
    if (selectedIndex != -1) {
      tenantComplaintRegisterController.selectedSubComplaintType.value = value!;
      tenantComplaintRegisterController.selectedSubtitleComplaintId.value =
          tenantComplaintRegisterController
              .subtitleComplaintCategory[selectedIndex].id;
    }
    debugPrint(
        'Selected Sub-Complaint Type: ${tenantComplaintRegisterController.selectedSubComplaintType.value}, ID: ${tenantComplaintRegisterController.selectedSubtitleComplaintId.value}');
  }

  /// On submit
  void _onSubmit() {
    List<String> missingField = [];
    if (tenantComplaintRegisterController.selectedComplaintType.value.isEmpty) {
      missingField.add('Complaint Type');
    }
    if (tenantComplaintRegisterController.selectedSubComplaintType.value.isEmpty) {
      missingField.add('Complaint Subtitle Type');
    }
    if (tenantComplaintRegisterController.complaintDetailsController.text.isEmpty) {
      missingField.add('Complaint Details');
    }
    if (missingField.isNotEmpty) {
      CustomSnackbar.show(
        title: "Warning",
        message: 'Please select:\n ${missingField.join('\n ')}.',
        status: 1,
        isDismissible: true,
        durationInSeconds: 2,
        isPersistent: false,
      );
      return;
    }

    tenantComplaintRegisterController.submitCompliant(
      propertyName: propertyName,
      propertyId: propertyId,
      unitAddressId: unitAddressId,
    );
  }

  /// Dropdown Widget
  Widget customDropdown({
    required String? selectedValue,
    required List<String> items,
    required String hintText,
    required void Function(String?)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 1, color: AppColors.splashBackgroundColor),
      ),
      padding: EdgeInsets.symmetric(horizontal: screenWidth3),
      child: DropdownButton<String>(
        value: selectedValue?.isEmpty ?? true ? null : selectedValue,
        onChanged: onChanged,
        isExpanded: true,
        underline: const SizedBox(),
        hint: CustomTextWidget(
          title: hintText,
          fontSize: screenHeight * 0.015,
          color: AppColors.black800,
        ),
        dropdownColor: AppColors.white,
        elevation: 2,
        icon: Icon(
          Icons.arrow_drop_down,
          color: AppColors.black800,
          size: screenHeight2,
        ),
        borderRadius: BorderRadius.circular(15),
        menuMaxHeight: screenHeight * 0.5,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: CustomTextWidget(
                    title: item,
                    fontSize: screenHeight * 0.015,
                    color: AppColors.black800,
                  ),
                ))
            .toList(),
      ),
    );
  }

  /// Field Label
  Widget buildFieldLabel(String labelText) {
    return Padding(
      padding: EdgeInsets.only(left: screenWidth1),
      child: CustomTextWidget(
        title: labelText,
        fontSize: screenHeight * 0.014,
        fontWeight: FontWeight.w500,
        color: AppColors.secondaryColor,
      ),
    );
  }
}
