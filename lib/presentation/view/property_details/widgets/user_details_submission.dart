import 'dart:io';

import 'package:majan/presentation/view/property_details/controller/user_data_submission_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validator.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_text_formfield_widget.dart';
import '../../../widgets/custom_text_widget.dart';

class UserDetailsSubmission extends StatefulWidget {
  @override
  _UserDetailsSubmissionState createState() => _UserDetailsSubmissionState();
}

class _UserDetailsSubmissionState extends State<UserDetailsSubmission> {
  final UserDataSubmissionController controller =
      Get.put(UserDataSubmissionController());

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for additional document form
  final TextEditingController _docTitleController = TextEditingController();
  DateTime? _selectedExpiryDate;
  File? _tempFile; // Temporary storage for file before adding document

  bool get _allFieldsFilled =>
      _docTitleController.text.isNotEmpty &&
      _selectedExpiryDate != null &&
      _tempFile != null;

  // Country code - Only Oman
  final String uaecountrycode = '+971';

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    print('UserDetailsSubmission - Received arguments: $args');
  }

  // Method to automatically add document when all fields are filled
  void _tryAutoAddDocument() {
    if (_docTitleController.text.isNotEmpty &&
        _selectedExpiryDate != null &&
        _tempFile != null) {
      // All required fields are filled, add the document automatically
      controller.addAdditionalDocument(
        _docTitleController.text,
        _selectedExpiryDate!,
        _tempFile!,
      );

      // Reset form
      _docTitleController.clear();
      setState(() {
        _selectedExpiryDate = null;
        _tempFile = null;
      });

      // Snackbar removed - document is added silently
    }
  }

  // Check if at least one image document exists
  bool _hasAtLeastOneImage() {
    return controller.user.value.additionalDocuments.any((doc) {
      if (doc.file is File) {
        final path = doc.file.path.toLowerCase();
        return path.endsWith('.jpg') || 
               path.endsWith('.jpeg') || 
               path.endsWith('.png');
      }
      return false;
    });
  }

  // Check if current temp file is an image
  bool _isImageFile(File? file) {
    if (file == null) return false;
    final path = file.path.toLowerCase();
    return path.endsWith('.jpg') || 
           path.endsWith('.jpeg') || 
           path.endsWith('.png');
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final propertyName = args['propertyName'] ?? 'Unknown Property';

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
                controller.submitUserData();
              }
            },
            child: Text(
              "save",
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
        return Padding(
          padding: EdgeInsets.all(screenWidth5),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  kHeight(0.01),

                  /// Citizenship Type Selection
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
                              ? (value) =>
                                  controller.changeCitizenshipType(value!)
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
                              ? (value) =>
                                  controller.changeCitizenshipType(value!)
                              : null,
                          activeColor: AppColors.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  kHeight(0.02),

                  /// Basic Information Section
                  CustomTextWidget(
                    title: "Basic Information",
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.secondaryColor,
                  ),
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
                    validator: (value) =>
                        Validator.validateName(value, fieldName: "First Name"),
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
                      validator: Validator.validateEmail),

                  CustomRichTextWidget(
                    title: "Mobile ",
                    subTitle: "*",
                    color: AppColors.black,
                    subTextColor: Colors.red,
                  ),

                  // Country Code (Fixed to Oman) and Mobile Number Row
                  Row(
                    children: [
                      // Fixed Oman Country Code Display
                      Container(
                        width: 100,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '🇴🇲',
                              style: TextStyle(fontSize: 20),
                            ),
                            SizedBox(width: 4),
                            Text(
                              uaecountrycode,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),

                      // Mobile Number Field
                      Expanded(
                        child: CustomTextFieldWidget(
                          hintText: 'Enter Mobile Number',
                          controller: controller.mobileCtrl,
                          readOnly: !controller.isEditMode.value,
                          keyboardType: TextInputType.phone,
                          validator: (value) =>
                              Validator.validateMobileWithCountryCode(value,
                                  countryCode: uaecountrycode),
                        ),
                      ),
                    ],
                  ),

                  // Helper text showing the full number format
                  Padding(
                    padding: EdgeInsets.only(top: 4, left: 110),
                    child: Text(
                      'Format: $uaecountrycode XXXX XXXX',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                  /// Additional Documents Section with Yellowish Background
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFFFF8E1), // Light yellowish background
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            Color(0xFFFFECB3), // Slightly darker yellow border
                        width: 1,
                      ),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CustomTextWidget(
                              title: "Additional Documents",
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppColors.secondaryColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "*",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        kHeight(0.005),
                        Text(
                          "At least one image document is required",
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        kHeight(0.01),

                        // Add Document Form
                        Card(
                          margin: EdgeInsets.only(bottom: 16),
                          color: Color(0xFFFFFDE7),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomTextWidget(
                                  title: "Add Document",
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                                kHeight(0.01),

                                // Document Title
                                CustomTextFieldWidget(
                                  hintText:
                                      'Document Title ( e.g., Emirates ID,Trade License)',
                                  controller: _docTitleController,
                                  keyboardType: TextInputType.text,
                                  onChanged: (value) {
                                    _tryAutoAddDocument();
                                  },
                                ),
                                kHeight(0.01),

                                // Expiry Date
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFF9C4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedExpiryDate == null
                                              ? 'Select Expiry Date *'
                                              : 'Expiry: ${_selectedExpiryDate!.toLocal().toString().split(' ')[0]}',
                                          style: TextStyle(
                                            color: _selectedExpiryDate == null
                                                ? Colors.red
                                                : AppColors.black,
                                            fontWeight:
                                                _selectedExpiryDate == null
                                                    ? FontWeight.w500
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          final DateTime? picked =
                                              await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime(2100),
                                          );
                                          if (picked != null) {
                                            setState(() {
                                              _selectedExpiryDate = picked;
                                              _tryAutoAddDocument();
                                            });
                                          }
                                        },
                                        child: Text(
                                          'Select Date',
                                          style: TextStyle(
                                            color: AppColors.secondaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                kHeight(0.01),

                                // File Upload with required indicator
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "File Upload ",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          "*",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final result =
                                            await FilePicker.platform.pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: [
                                            'jpg',
                                            'png',
                                            'pdf',
                                            'jpeg'
                                          ],
                                        );
                                        if (result != null &&
                                            result.files.single.path != null) {
                                          final file =
                                              File(result.files.single.path!);
                                          setState(() {
                                            _tempFile = file;
                                            _tryAutoAddDocument();
                                          });
                                        }
                                      },
                                      icon: Icon(Icons.upload_file,
                                          color: AppColors.white),
                                      label: Text(
                                        _tempFile == null
                                            ? "Choose File *"
                                            : "Change File (${_tempFile!.path.split('/').last})",
                                        style:
                                            TextStyle(color: AppColors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _tempFile == null
                                            ? AppColors.secondaryColor
                                            : AppColors.onlineGreen,
                                        foregroundColor: AppColors.white,
                                      ),
                                    ),
                                    if (_tempFile == null)
                                      Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          "Please select a file (required)",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    // Show image type indicator if file is selected
                                    if (_tempFile != null)
                                      Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _isImageFile(_tempFile)
                                                  ? Icons.check_circle
                                                  : Icons.info,
                                              size: 16,
                                              color: _isImageFile(_tempFile)
                                                  ? Colors.green
                                                  : Colors.orange,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              _isImageFile(_tempFile)
                                                  ? "Image file (JPG/PNG)"
                                                  : "PDF file (at least one image required)",
                                              style: TextStyle(
                                                color: _isImageFile(_tempFile)
                                                    ? Colors.green.shade700
                                                    : Colors.orange.shade700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                kHeight(0.01),
                              ],
                            ),
                          ),
                        ),

                        // List of Added Documents
                        Obx(() {
                          if (controller
                              .user.value.additionalDocuments.isEmpty) {
                            return Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.warning_amber_rounded, 
                                       color: Colors.red, size: 32),
                                  SizedBox(height: 8),
                                  Text(
                                    "No documents added yet",
                                    style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "At least one image document is required to submit",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          // Check if at least one image exists
                          final hasImage = _hasAtLeastOneImage();
                          
                          return Column(
                            children: [
                              // Warning banner if no image
                              if (!hasImage)
                                Container(
                                  padding: EdgeInsets.all(12),
                                  margin: EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, 
                                           color: Colors.orange, size: 24),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Please add at least one image document (JPG/PNG)",
                                          style: TextStyle(
                                            color: Colors.orange.shade900,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              
                              // Document list
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: controller
                                    .user.value.additionalDocuments.length,
                                itemBuilder: (context, index) {
                                  final doc = controller
                                      .user.value.additionalDocuments[index];
                                  final isImage = _isImageFile(doc.file as File?);
                                  
                                  return Card(
                                    margin: EdgeInsets.symmetric(vertical: 5),
                                    color: Color(0xFFFFFDE7),
                                    child: ListTile(
                                      leading: Stack(
                                        children: [
                                          Icon(
                                            _getDocumentIcon(doc.file),
                                            color: Color(0xFFFFA000),
                                            size: 32,
                                          ),
                                          if (isImage)
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                                size: 16,
                                              ),
                                            ),
                                        ],
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              doc.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          if (isImage)
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                "IMAGE",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.green.shade900,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        'Expires: ${doc.expiryDate.toLocal().toString().split(' ')[0]}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => controller
                                            .removeAdditionalDocument(index),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),

                  kHeight(0.03),

                  /// Information Box
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFFFF9C4)),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: AppColors.secondaryColor),
                              SizedBox(width: 8),
                              Expanded(
                                child: CustomTextWidget(
                                  title: "Application Information:",
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryColor,
                                ),
                              ),
                            ],
                          ),
                          kHeight(0.01),
                          _buildInfoRow("Property", propertyName),
                          _buildInfoRow(
                              "First Name",
                              controller.firstNameCtrl.text.isNotEmpty
                                  ? controller.firstNameCtrl.text
                                  : "Not provided"),
                          _buildInfoRow(
                              "Last Name",
                              controller.lastNameCtrl.text.isNotEmpty
                                  ? controller.lastNameCtrl.text
                                  : "Not provided"),
                          _buildInfoRow(
                              "Address",
                              controller.addressCtrl.text.isNotEmpty
                                  ? controller.addressCtrl.text
                                  : "Not provided"),
                          _buildInfoRow(
                              "Email",
                              controller.emailCtrl.text.isNotEmpty
                                  ? controller.emailCtrl.text
                                  : "Not provided"),
                          _buildInfoRow(
                              "Mobile",
                              controller.mobileCtrl.text.isNotEmpty
                                  ? "$uaecountrycode ${controller.mobileCtrl.text}"
                                  : "Not provided"),
                          _buildInfoRow(
                              "Citizenship",
                              controller.selectedCitizenship.value == 1
                                  ? "Native"
                                  : "Foreign"),
                          _buildInfoRow("Documents Added",
                              "${controller.user.value.additionalDocuments.length} document(s)"),

                          // Display the list of added documents if any
                          if (controller
                              .user.value.additionalDocuments.isNotEmpty) ...[
                            SizedBox(height: 8),
                            CustomTextWidget(
                              title: "Document Details:",
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryColor,
                              fontSize: 14,
                            ),
                            SizedBox(height: 4),
                          ],
                          for (var i = 0;
                              i <
                                  controller
                                      .user.value.additionalDocuments.length;
                              i++)
                            _buildInfoRow(
                              "  • ${controller.user.value.additionalDocuments[i].title}",
                              "Expires: ${controller.user.value.additionalDocuments[i].expiryDate.toLocal().toString().split(' ')[0]}",
                            ),
                        ]),
                  ),

                  kHeight(0.03),

                  /// Error Message Display
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

                  /// Submit Button
                  CustomButtonWidget(
                    buttonTitle: controller.isLoading.value
                        ? "Processing..."
                        : "Submit Application",
                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                            // Dismiss keyboard first
                            FocusScope.of(context).unfocus();
                            
                            // Validate form
                            if (!_formKey.currentState!.validate()) {
                              Get.snackbar(
                                "Form Error",
                                "Please fix the form errors and try again.",
                                backgroundColor: Colors.red.shade100,
                                colorText: Colors.black,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }
                            
                            // Check if at least one image document exists
                            if (!_hasAtLeastOneImage()) {
                              Get.snackbar(
                                "Missing Required Document",
                                "Please add at least one image document (JPG/PNG) before submitting.",
                                backgroundColor: Colors.red.shade100,
                                colorText: Colors.black,
                                snackPosition: SnackPosition.BOTTOM,
                                duration: Duration(seconds: 4),
                              );
                              return;
                            }
                            
                            // Format mobile number with country code before submission
                            final formattedMobile = uaecountrycode +
                                controller.mobileCtrl.text;
                            controller.mobileCtrl.text = formattedMobile;

                            await controller.submitUserData();
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

  IconData _getDocumentIcon(dynamic file) {
    if (file is File) {
      final path = file.path.toLowerCase();
      if (path.endsWith('.pdf')) return Icons.picture_as_pdf;
      if (path.endsWith('.jpg') ||
          path.endsWith('.jpeg') ||
          path.endsWith('.png')) {
        return Icons.image;
      }
    }
    return Icons.description;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _docTitleController.dispose();
    super.dispose();
  }
}