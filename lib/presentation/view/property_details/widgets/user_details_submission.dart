import 'package:majan/presentation/view/property_details/controller/user_data_submission_controller.dart';
import 'package:majan/presentation/view/property_details/widgets/document_upload_screen.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_text_formfield_widget.dart';
import '../../../widgets/custom_text_widget.dart';

class UserDetailsSubmission extends StatelessWidget {
  final UserDataSubmissionController controller =
      Get.put(UserDataSubmissionController());

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
     final args = Get.arguments as Map<String, dynamic>? ?? {};
  
  final propertyId = args['propertyId'] ?? '';
  final unitId = args['unitId'] ?? '';
  final unitTypeId = args['unitTypeId'] ?? 0;
  final selectedCount = args['selectedCount'] ?? 1;
  final propertyName = args['propertyName'] ?? 'Unknown Property'; // Get property name
  final propertyType = args['propertyType'] ?? 'residential'; // Get property type

  print('UserDetailsSubmission - Received arguments:');
  print('propertyId: $propertyId');
  print('unitId: $unitId');
  print('unitTypeId: $unitTypeId');
  print('selectedCount: $selectedCount');
  print('propertyName: $propertyName'); // Add this line
  print('propertyType: $propertyType'); // Add this line
  
    
    
    // Check commercial property status when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (unitId > 0) {
        controller.checkCommercialPropertyStatus(unitId);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: CustomTextWidget(
          title: "Personal Details",
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: InkWell(
            onTap: () {
              Get.back();
            },
            child: Icon(Icons.arrow_back, color: AppColors.black)),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                controller.updateUserFromControllers();
                if (controller.validateForm()) {
                  Get.snackbar(
                    "Success",
                    "Form validation successful",
                    backgroundColor: Colors.green.shade100,
                    colorText: Colors.black,
                  );
                }
              } else {
                Get.snackbar(
                  "Warning!",
                  "Please fill all required fields",
                  backgroundColor: Colors.red.shade100,
                  colorText: Colors.black,
                );
              }
            },
            child: Text(
              "Submit",
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        // Show loading indicator while checking commercial status
        if (controller.isCheckingCommercialStatus.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.secondaryColor),
                SizedBox(height: 16),
                Text(
                  "Checking property type...",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.all(screenWidth5),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  kHeight(0.01),
                  
                  // Property Type Selection (now disabled and shows API result)
                  CustomTextWidget(
                    title: "Property Type",
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                  kHeight(0.01),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.secondaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          controller.isCommercialProperty 
                            ? Icons.business 
                            : Icons.home,
                          color: AppColors.secondaryColor,
                        ),
                        SizedBox(width: 12),
                        Text(
                          controller.isCommercialProperty 
                            ? "Commercial Property" 
                            : "Residential Property",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  kHeight(0.02),

                  // Citizenship Type Selection
                  CustomTextWidget(
                    title: "Citizenship Type",
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                  kHeight(0.01),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<int>(
                          title: Text("Native"),
                          value: 1,
                          groupValue: controller.selectedCitizenship.value,
                          onChanged: controller.isEditMode.value 
                            ? (value) => controller.changeCitizenshipType(value!) 
                            : null,
                          activeColor: AppColors.secondaryColor,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<int>(
                          title: Text("Foreign"),
                          value: 0,
                          groupValue: controller.selectedCitizenship.value,
                          onChanged: controller.isEditMode.value 
                            ? (value) => controller.changeCitizenshipType(value!) 
                            : null,
                          activeColor: AppColors.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  kHeight(0.02),

                  // Basic Information
                  CustomRichTextWidget(
                    title: "First Name ",
                    subTitle: "*",
                    color: AppColors.black,
                    subTextColor: Colors.red,
                  ),
                  CustomTextFieldWidget(
                    hintText: 'Enter First Name',
                    controller: controller.firstNameCtrl,
                    readOnly: !controller.isEditMode.value,
                    keyboardType: TextInputType.name,
                    // validator: (value) => Validator.validateName(value,
                    //     fieldName: "First Name"),
                  ),

                  CustomRichTextWidget(
                    title: "Last Name ",
                    subTitle: "*",
                    color: AppColors.black,
                    subTextColor: Colors.red,
                  ),
                  CustomTextFieldWidget(
                    hintText: 'Enter Last Name',
                    controller: controller.lastNameCtrl,
                    readOnly: !controller.isEditMode.value,
                    keyboardType: TextInputType.name,
                    // validator: (value) => Validator.validateLastname(value,
                    //     fieldName: "Last Name"),
                  ),

                  CustomRichTextWidget(
                    title: "Address ",
                    subTitle: "*",
                    color: AppColors.black,
                    subTextColor: Colors.red,
                  ),
                  CustomTextFieldWidget(
                    hintText: 'Enter Address',
                    controller: controller.addressCtrl,
                    readOnly: !controller.isEditMode.value,
                    keyboardType: TextInputType.text,
                    // validator: Validator.validateAddress,
                  ),

                  CustomRichTextWidget(
                    title: "Email ",
                    subTitle: "*",
                    color: AppColors.black,
                    subTextColor: Colors.red,
                  ),
                  CustomTextFieldWidget(
                      hintText: 'Enter Email',
                      controller: controller.emailCtrl,
                      readOnly: !controller.isEditMode.value,
                      keyboardType: TextInputType.emailAddress,
                      // validator: Validator.validateEmail
                      ),

                  CustomRichTextWidget(
                    title: "Mobile ",
                    subTitle: "*",
                    color: AppColors.black,
                    subTextColor: Colors.red,
                  ),
                  CustomTextFieldWidget(
                    hintText: 'Enter Mobile Number',
                    controller: controller.mobileCtrl,
                    readOnly: !controller.isEditMode.value,
                    keyboardType: TextInputType.phone,
                    // validator: Validator.validateMobile,
                  ),

                  kHeight(0.02),

                  // Citizenship-specific fields
                  if (controller.isNativeCitizen) ...[
                    // Native Citizen Fields
                    CustomTextWidget(
                      title: "Native Citizen Details",
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.secondaryColor,
                    ),
                    kHeight(0.01),
                    
                    CustomRichTextWidget(
                      title: "Civil ID ",
                      subTitle: "*",
                      color: AppColors.black,
                      subTextColor: Colors.red,
                    ),
                    CustomTextFieldWidget(
                      hintText: 'Enter Civil ID',
                      controller: controller.civilIdCtrl,
                      readOnly: !controller.isEditMode.value,
                      keyboardType: TextInputType.text,
                      // validator: (value) => controller.isNativeCitizen && (value?.isEmpty ?? true) 
                      //   ? 'Civil ID is required for native citizens' 
                      //   : null,
                    ),

                    CustomRichTextWidget(
                      title: "Civil ID Expiry Date ",
                      subTitle: "*",
                      color: AppColors.black,
                      subTextColor: Colors.red,
                    ),
                    CustomTextFieldWidget(
                      hintText: 'Enter Civil ID Expiry (YYYY-MM-DD)',
                      controller: controller.civilIdExpiryCtrl,
                      readOnly: !controller.isEditMode.value,
                      keyboardType: TextInputType.datetime,
                      // validator: (value) => controller.isNativeCitizen && (value?.isEmpty ?? true) 
                      //   ? 'Civil ID expiry date is required for native citizens' 
                      //   : null,
                    ),
                  ] else ...[
                    // Foreign Citizen Fields
                    CustomTextWidget(
                      title: "Foreign Citizen Details",
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.secondaryColor,
                    ),
                    kHeight(0.01),

                    CustomRichTextWidget(
                      title: "Passport No ",
                      subTitle: "*",
                      color: AppColors.black,
                      subTextColor: Colors.red,
                    ),
                    CustomTextFieldWidget(
                      hintText: 'Enter Passport No',
                      controller: controller.passportCtrl,
                      readOnly: !controller.isEditMode.value,
                      keyboardType: TextInputType.text,
                      // validator: (value) => controller.isForeignCitizen && (value?.isEmpty ?? true) 
                      //   ? 'Passport number is required for foreign citizens' 
                      //   : null,
                    ),

                    CustomRichTextWidget(
                      title: "Visa No ",
                      subTitle: "*",
                      color: AppColors.black,
                      subTextColor: Colors.red,
                    ),
                    CustomTextFieldWidget(
                      hintText: 'Enter Visa No',
                      controller: controller.visaCtrl,
                      readOnly: !controller.isEditMode.value,
                      keyboardType: TextInputType.text,
                      // validator: (value) => controller.isForeignCitizen && (value?.isEmpty ?? true) 
                      //   ? 'Visa number is required for foreign citizens' 
                      //   : null,
                    ),

                    CustomRichTextWidget(
                      title: "Visa Expiry Date ",
                      subTitle: "*",
                      color: AppColors.black,
                      subTextColor: Colors.red,
                    ),
                    CustomTextFieldWidget(
                      hintText: 'Enter Visa Expiry (YYYY-MM-DD)',
                      controller: controller.visaExpiryCtrl,
                      readOnly: !controller.isEditMode.value,
                      keyboardType: TextInputType.datetime,
                      // validator: (value) => controller.isForeignCitizen && (value?.isEmpty ?? true) 
                      //   ? 'Visa expiry date is required for foreign citizens' 
                      //   : null,
                    ),

                    CustomRichTextWidget(
                      title: "Expat Civil ID ",
                      subTitle: "*",
                      color: AppColors.black,
                      subTextColor: Colors.red,
                    ),
                    CustomTextFieldWidget(
                      hintText: 'Enter Expat Civil ID',
                      controller: controller.expatCivilIdCtrl,
                      readOnly: !controller.isEditMode.value,
                      keyboardType: TextInputType.text,
                      // validator: (value) => controller.isForeignCitizen && (value?.isEmpty ?? true) 
                      //   ? 'Expat Civil ID is required for foreign citizens' 
                      //   : null,
                    ),

                    CustomRichTextWidget(
                      title: "Expat Civil ID Expiry ",
                      subTitle: "*",
                      color: AppColors.black,
                      subTextColor: Colors.red,
                    ),
                    CustomTextFieldWidget(
                      hintText: 'Enter Expat Civil ID Expiry (YYYY-MM-DD)',
                      controller: controller.expatCivilIdExpiryCtrl,
                      readOnly: !controller.isEditMode.value,
                      keyboardType: TextInputType.datetime,
                      // validator: (value) => controller.isForeignCitizen && (value?.isEmpty ?? true) 
                      //   ? 'Expat Civil ID expiry date is required for foreign citizens' 
                      //   : null,
                    ),
                  ],

                  // Commercial Property Fields
                  if (controller.isCommercialProperty) ...[
                    kHeight(0.02),
                    CustomTextWidget(
                      title: "Commercial Property Details",
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.secondaryColor,
                    ),
                    kHeight(0.01),

                    CustomRichTextWidget(
                      title: "CR Number ",
                      subTitle: "*",
                      color: AppColors.black,
                      subTextColor: Colors.red,
                    ),
                    CustomTextFieldWidget(
                      hintText: 'Enter Commercial Registration Number',
                      controller: controller.crNumberCtrl,
                      readOnly: !controller.isEditMode.value,
                      keyboardType: TextInputType.text,
                      // validator: (value) => controller.isCommercialProperty && (value?.isEmpty ?? true) 
                      //   ? 'CR Number is required for commercial properties' 
                      //   : null,
                    ),

                    CustomRichTextWidget(
                      title: "CR Expiry Date ",
                      subTitle: "*",
                      color: AppColors.black,
                      subTextColor: Colors.red,
                    ),
                    CustomTextFieldWidget(
                      hintText: 'Enter CR Expiry (YYYY-MM-DD)',
                      controller: controller.crExpiryCtrl,
                      readOnly: !controller.isEditMode.value,
                      keyboardType: TextInputType.datetime,
                      // validator: (value) => controller.isCommercialProperty && (value?.isEmpty ?? true) 
                      //   ? 'CR Expiry date is required for commercial properties' 
                      //   : null,
                    ),

                    CustomRichTextWidget(
                      title: "Municipality License No ",
                      subTitle: "*",
                      color: AppColors.black,
                      subTextColor: Colors.red,
                    ),
                    CustomTextFieldWidget(
                      hintText: 'Enter Municipality License Number',
                      controller: controller.municipalityLicenseNumberCtrl,
                      readOnly: !controller.isEditMode.value,
                      keyboardType: TextInputType.text,
                      // validator: (value) => controller.isCommercialProperty && (value?.isEmpty ?? true) 
                      //   ? 'Municipality License is required for commercial properties' 
                      //   : null,
                    ),

                    CustomRichTextWidget(
                      title: "Municipality License Date ",
                      subTitle: "*",
                      color: AppColors.black,
                      subTextColor: Colors.red,
                    ),
                    CustomTextFieldWidget(
                      hintText: 'Enter Municipality License Date (YYYY-MM-DD)',
                      controller: controller.municipalityLicenseDateCtrl,
                      readOnly: !controller.isEditMode.value,
                      keyboardType: TextInputType.datetime,
                      // validator: (value) => controller.isCommercialProperty && (value?.isEmpty ?? true) 
                      //   ? 'Municipality License date is required for commercial properties' 
                      //   : null,
                    ),

                    CustomRichTextWidget(
                      title: "Company Address ",
                      subTitle: "*",
                      color: AppColors.black,
                      subTextColor: Colors.red,
                    ),
                    CustomTextFieldWidget(
                      hintText: 'Enter Company Address',
                      controller: controller.companyAddressCtrl,
                      readOnly: !controller.isEditMode.value,
                      keyboardType: TextInputType.text,
                      // validator: (value) => controller.isCommercialProperty && (value?.isEmpty ?? true) 
                      //   ? 'Company address is required for commercial properties' 
                      //   : null,
                    ),

                    CustomRichTextWidget(
                      title: "PO Box ",
                      subTitle: "*",
                      color: AppColors.black,
                      subTextColor: Colors.red,
                    ),
                    CustomTextFieldWidget(
                      hintText: 'Enter PO Box Number',
                      controller: controller.poBoxCtrl,
                      readOnly: !controller.isEditMode.value,
                      keyboardType: TextInputType.text,
                      // validator: (value) => controller.isCommercialProperty && (value?.isEmpty ?? true) 
                      //   ? 'PO Box is required for commercial properties' 
                      //   : null,
                    ),
                  ],

                  kHeight(0.03),

                  // Required Documents Information
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.secondaryColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextWidget(
                          title: "Required Documents for ${controller.citizenshipLabel} ${controller.propertyTypeLabel} Property:",
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryColor,
                        ),
                        kHeight(0.01),
                        ...controller.requiredDocumentLabels.map((doc) => 
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: AppColors.secondaryColor, size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    doc,
                                    style: TextStyle(fontSize: 14, color: AppColors.black),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).toList(),
                      ],
                    ),
                  ),

                  kHeight(0.03),

                  // Error Message Display
                  if (controller.errorMessage.value != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.errorMessage.value!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Proceed Button
                  CustomButtonWidget(
                    buttonTitle: controller.isLoading.value ? "Processing..." : "Proceed to Document Upload",
                    onPressed: controller.isLoading.value ? null : () async {
                      if (_formKey.currentState!.validate()) {
                        controller.updateUserFromControllers();
                        
                        if (controller.validateForm()) {
                          // Prepare document fields based on citizenship and property type
                          List<DocumentField> documentFields = [];
                          
                          // Citizenship documents
                          if (controller.isNativeCitizen) {
                            documentFields.addAll([
                              DocumentField(
                                title: "Civil ID Front",
                                allowedTypes: FileTypeEnum.image,
                                maxFiles: 1,
                              ),
                              DocumentField(
                                title: "Civil ID Back",
                                allowedTypes: FileTypeEnum.image,
                                maxFiles: 1,
                              ),
                            ]);
                          } else {
                            documentFields.addAll([
                              DocumentField(
                                title: "Passport First Page",
                                allowedTypes: FileTypeEnum.any,
                                maxFiles: 1,
                              ),
                              DocumentField(
                                title: "Passport Last Page",
                                allowedTypes: FileTypeEnum.any,
                                maxFiles: 1,
                              ),
                              DocumentField(
                                title: "Expat Civil ID Front",
                                allowedTypes: FileTypeEnum.image,
                                maxFiles: 1,
                              ),
                              DocumentField(
                                title: "Expat Civil ID Back",
                                allowedTypes: FileTypeEnum.image,
                                maxFiles: 1,
                              ),
                              DocumentField(
                                title: "Resident Visa",
                                allowedTypes: FileTypeEnum.any,
                                maxFiles: 1,
                              ),
                            ]);
                          }
                          
                          // Commercial property documents
                          if (controller.isCommercialProperty) {
                            documentFields.addAll([
                              DocumentField(
                                title: "Commercial Registration Copy",
                                allowedTypes: FileTypeEnum.any,
                                maxFiles: 1,
                              ),
                              DocumentField(
                                title: "Municipality License",
                                allowedTypes: FileTypeEnum.any,
                                maxFiles: 1,
                              ),
                              DocumentField(
                                title: "Company Authorization Letter",
                                allowedTypes: FileTypeEnum.any,
                                maxFiles: 1,
                              ),
                            ]);
                          }

                          // Navigate to document upload screen
                          Get.to(
                            () => DocumentUploadScreen(
                              screenTitle: "Upload ${controller.citizenshipLabel} ${controller.propertyTypeLabel} Property Documents",
                              documentFields: documentFields,
                              isCommercialProperty: controller.isCommercialProperty,
                            ),
                          );
                        } else {
                          Get.snackbar(
                            "Warning!",
                            "Please fill all required fields correctly",
                            backgroundColor: Colors.red.shade100,
                            colorText: Colors.black,
                          );
                        }
                      } else {
                        Get.snackbar(
                          "Warning!",
                          "Form validation failed. Please check all fields.",
                          backgroundColor: Colors.red.shade100,
                          colorText: Colors.black,
                        );
                      }
                    },
                    buttonColor: AppColors.secondaryColor,
                    buttonTextColor: AppColors.white,
                  ),
                  kHeight(0.02),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}