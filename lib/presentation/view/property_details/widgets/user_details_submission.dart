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
    final controller = Get.put(UserDataSubmissionController());
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final propertyId = args['propertyId']?.toString() ?? '0';
    final unitId = args['unitId']?.toString() ?? '0';

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
                Get.snackbar(
                  "Success",
                  "Form submitted successfully",
                  backgroundColor: Colors.green.shade100,
                  colorText: Colors.black,
                );
              } else {
                Get.snackbar(
                  "Warning!",
                  "Please Add All Personal Details",
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
                      validator: (value) => Validator.validateName(value,
                          fieldName: "First Name"),
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
                      validator: (value) => Validator.validateLastname(value,
                          fieldName: "Last Name"),
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
                      validator: Validator.validateAddress,
                    ),

                    CustomRichTextWidget(
                      title: "PO No ",
                      subTitle: "*",
                      color: AppColors.black,
                      subTextColor: Colors.red,
                    ),
                    CustomTextFieldWidget(
                      hintText: 'Enter PO No',
                      controller: controller.poNoCtrl,
                      readOnly: !controller.isEditMode.value,
                      keyboardType: TextInputType.text,
                      validator: Validator.validatePoNumber,
                    ),

                    CustomTextWidget(
                      title: "Nationality",
                      fontWeight: FontWeight.w600,
                    ),
                    CustomTextFieldWidget(
                      hintText: 'Enter Nationality',
                      controller: controller.nationalityCtrl,
                      readOnly: !controller.isEditMode.value,
                      keyboardType: TextInputType.text,
                      validator: Validator.validateNationality,
                    ),

                    CustomTextWidget(
                      title: "Email",
                      fontWeight: FontWeight.w600,
                    ),
                    CustomTextFieldWidget(
                        hintText: 'Enter Email',
                        controller: controller.emailCtrl,
                        readOnly: !controller.isEditMode.value,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validator.validateEmail),

                    CustomTextWidget(
                      title: "Mobile",
                      fontWeight: FontWeight.w600,
                    ),
                    CustomTextFieldWidget(
                      hintText: 'Enter Mobile Number',
                      controller: controller.mobileCtrl,
                      readOnly: !controller.isEditMode.value,
                      keyboardType: TextInputType.phone,
                      validator: Validator.validateMobile,
                    ),

                    CustomTextWidget(
                      title: "Passport No",
                      fontWeight: FontWeight.w600,
                    ),
                    CustomTextFieldWidget(
                      hintText: 'Enter Passport No',
                      controller: controller.passportCtrl,
                      readOnly: !controller.isEditMode.value,
                      keyboardType: TextInputType.text,
                      validator: Validator.validatePassport,
                    ),

                    CustomTextWidget(
                      title: "Visa No",
                      fontWeight: FontWeight.w600,
                    ),
                    CustomTextFieldWidget(
                      hintText: 'Enter Visa No',
                      controller: controller.visaCtrl,
                      readOnly: !controller.isEditMode.value,
                      keyboardType: TextInputType.text,
                      validator: Validator.validateVisa,
                    ),

                    kHeight(0.02), // spacing
                    CustomButtonWidget(
                      buttonTitle: "Proceed",
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          controller.user.value = UserDataSubmissionModel(
                            propertyId: propertyId,
                            unitId: unitId,
                            uid: FirebaseAuth.instance.currentUser?.uid ?? "",
                            firstName: controller.firstNameCtrl.text,
                            lastName: controller.lastNameCtrl.text,
                            address: controller.addressCtrl.text,
                            poNo: controller.poNoCtrl.text,
                            nationality: controller.nationalityCtrl.text,
                            email: controller.emailCtrl.text,
                            mobile: controller.mobileCtrl.text,
                            passportNo: controller.passportCtrl.text,
                            visaNo: controller.visaCtrl.text,
                            fields: [],
                          );
                          Get.to(
                            DocumentUploadScreen(
                              screenTitle: "Upload Documents",
                              documentFields: [
                                DocumentField(
                                    title: "Passport",
                                    allowedTypes: FileTypeEnum.any,
                                    maxFiles: 1),
                                DocumentField(
                                    title: "Visa",
                                    allowedTypes: FileTypeEnum.image,
                                    maxFiles: 1),
                              ],
                            ),
                            // arguments: {
                            //   "firstName": controller.firstNameCtrl.text,
                            //   "lastName": controller.lastNameCtrl.text,
                            //   "address": controller.addressCtrl.text,
                            //   "poNo": controller.poNoCtrl.text,
                            //   "nationality": controller.nationalityCtrl.text,
                            //   "email": controller.emailCtrl.text,
                            //   "mobileNo": controller.mobileCtrl.text,
                            //   "passportNo": controller.passportCtrl.text,
                            //   "visa": controller.visaCtrl.text,
                            // },
                          );
                          Get.snackbar(
                            "Success",
                            "Form submitted successfully",
                            backgroundColor: Colors.green.shade100,
                            colorText: Colors.black,
                          );
                        } else {
                          Get.snackbar(
                            "Warning!",
                            "Please Add All Personal Details",
                            backgroundColor: Colors.red.shade100,
                            colorText: Colors.black,
                          );
                        }
                      },
                      buttonColor: AppColors.secondaryColor,
                      buttonTextColor: AppColors.white,
                      // buttonShape: "rect",
                    ),
                    kHeight(0.02),
                  ],
                ),
              )),
        ),
      ),
    );
  }
}
