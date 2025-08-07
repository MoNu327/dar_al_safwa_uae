import 'package:dar_al_safwa/presentation/view/property_details/controller/user_data_submission_controller.dart';
import 'package:dar_al_safwa/presentation/view/property_details/widgets/document_upload_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validator.dart';
import '../../../../data/model/user_data_submission_model.dart';
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
    final propertyId = int.tryParse(args['propertyId']?.toString() ?? '0') ?? 0;
    final unitId = int.tryParse(args['unitId']?.toString() ?? '0') ?? 0;

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
      body: Padding(
        padding: EdgeInsets.all(screenWidth5),
        child: SingleChildScrollView(
          child: Obx(() => Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    kHeight(0.01),
                    
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
                        validator: (value) => controller.isNativeCitizen && (value?.isEmpty ?? true) 
                          ? 'Civil ID is required for native citizens' 
                          : null,
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
                        validator: (value) => controller.isNativeCitizen && (value?.isEmpty ?? true) 
                          ? 'Civil ID expiry date is required for native citizens' 
                          : null,
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
                        validator: (value) => controller.isForeignCitizen && (value?.isEmpty ?? true) 
                          ? 'Passport number is required for foreign citizens' 
                          : null,
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
                        validator: (value) => controller.isForeignCitizen && (value?.isEmpty ?? true) 
                          ? 'Visa number is required for foreign citizens' 
                          : null,
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
                        validator: (value) => controller.isForeignCitizen && (value?.isEmpty ?? true) 
                          ? 'Visa expiry date is required for foreign citizens' 
                          : null,
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
                        validator: (value) => controller.isForeignCitizen && (value?.isEmpty ?? true) 
                          ? 'Expat Civil ID is required for foreign citizens' 
                          : null,
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
                        validator: (value) => controller.isForeignCitizen && (value?.isEmpty ?? true) 
                          ? 'Expat Civil ID expiry date is required for foreign citizens' 
                          : null,
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
                            title: "Required Documents for ${controller.citizenshipLabel}s:",
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
                    Obx(() {
                      if (controller.errorMessage.value != null) {
                        return Container(
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
                        );
                      }
                      return SizedBox.shrink();
                    }),

                    // Proceed Button
                    Obx(() => CustomButtonWidget(
                      buttonTitle: controller.isLoading.value ? "Processing..." : "Proceed to Document Upload",
                    onPressed: controller.isLoading.value ? null : () async {
  // First validate the form fields only (no document validation)
  if (_formKey.currentState!.validate()) {
    // Update user data from controllers
    controller.updateUserFromControllers();
    
    // Validate basic form data (without documents)
    bool isFormValid = true;
    
    // Basic validation
    if (controller.user.value.firstName.isEmpty ||
        controller.user.value.lastName.isEmpty ||
        controller.user.value.address.isEmpty ||
        controller.user.value.email.isEmpty ||
        controller.user.value.mobile.isEmpty) {
      controller.errorMessage('Please fill all required basic fields');
      isFormValid = false;
    }

    // Email validation
    if (isFormValid && !GetUtils.isEmail(controller.user.value.email)) {
      controller.errorMessage('Please enter a valid email address');
      isFormValid = false;
    }

    // Mobile validation
    if (isFormValid && controller.user.value.mobile.length < 8) {
      controller.errorMessage('Please enter a valid mobile number');
      isFormValid = false;
    }

    // Citizenship-specific validation
    if (isFormValid && !controller.user.value.isValid()) {
      if (controller.user.value.isNative) {
        controller.errorMessage('Please fill all required native citizen fields (Civil ID and expiry date)');
      } else {
        controller.errorMessage('Please fill all required foreign citizen fields (Passport, Visa, Expat Civil ID details)');
      }
      isFormValid = false;
    }

    if (isFormValid) {
      // Clear any error messages
      controller.errorMessage(null);
      
      // Update the user model with all current data
      controller.user.value = UserDataSubmissionModel(
        propertyId: propertyId,
        unitId: unitId,
        uid: FirebaseAuth.instance.currentUser?.uid ?? "",
        firstName: controller.firstNameCtrl.text,
        lastName: controller.lastNameCtrl.text,
        address: controller.addressCtrl.text,
        citizenship: controller.selectedCitizenship.value,
        email: controller.emailCtrl.text,
        mobile: controller.mobileCtrl.text,
        requiredDocumentTypes: controller.getRequiredDocTypes(controller.selectedCitizenship.value),
        civilId: controller.isNativeCitizen ? controller.civilIdCtrl.text : null,
        civilIdExpiry: controller.isNativeCitizen ? controller.civilIdExpiryCtrl.text : null,
        passportNo: controller.isForeignCitizen ? controller.passportCtrl.text : null,
        visaNo: controller.isForeignCitizen ? controller.visaCtrl.text : null,
        visaExpiryDate: controller.isForeignCitizen ? controller.visaExpiryCtrl.text : null,
        expatCivilId: controller.isForeignCitizen ? controller.expatCivilIdCtrl.text : null,
        expatCivilIdExpiry: controller.isForeignCitizen ? controller.expatCivilIdExpiryCtrl.text : null,
      );

      // Prepare document fields based on citizenship type
      List<DocumentField> documentFields = controller.isNativeCitizen
          ? [
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
            ]
          : [
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
            ];

      // Navigate to document upload screen
      Get.to(
        () => DocumentUploadScreen(
          screenTitle: "Upload ${controller.citizenshipLabel} Documents",
          documentFields: documentFields,
        ),
      );
    } else {
      // Show error snackbar if validation fails
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
                    )),
                    kHeight(0.02),
                  ],
                ),
              )),
        ),
      ),
    );
  }
}