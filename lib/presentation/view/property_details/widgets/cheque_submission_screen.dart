import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_text_widget.dart';
import '../../../widgets/custom_text_formfield_widget.dart';

class ChequeSubmissionScreen extends StatefulWidget {
  const ChequeSubmissionScreen({super.key});

  @override
  State<ChequeSubmissionScreen> createState() => _ChequeSubmissionScreenState();
}

class _ChequeSubmissionScreenState extends State<ChequeSubmissionScreen> {
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _bankCodeController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _chequeNumberController = TextEditingController();
  final TextEditingController _chequeDateController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  File? _chequeImageFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _bankNameController.dispose();
    _bankCodeController.dispose();
    _amountController.dispose();
    _chequeNumberController.dispose();
    _chequeDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        surfaceTintColor: AppColors.white,
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
        title: CustomTextWidget(
          title: "Cheque Submission",
          fontSize: Get.height * 0.022,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitCheque,
            child: CustomTextWidget(
              title: "Submit",
              fontSize: Get.height * 0.018,
              fontWeight: FontWeight.w600,
              color: _isSubmitting ? AppColors.grey : AppColors.black,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight1),

                // Cheque Image Upload Section
                Center(
                  child: GestureDetector(
                    onTap: _pickChequeImage,
                    child: Container(
                      width: Get.width * 0.9,
                      height: Get.height * 0.25,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.lightGrey,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        color: AppColors.whiteLight,
                      ),
                      child: _chequeImageFile != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    _chequeImageFile!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _chequeImageFile = null;
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.redColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: AppColors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: Get.width * 0.12,
                                  color: AppColors.grey,
                                ),
                                SizedBox(height: screenHeight05),
                                CustomTextWidget(
                                  title: "Upload Cheque Image",
                                  fontSize: Get.height * 0.018,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.grey,
                                ),
                                SizedBox(height: screenHeight05),
                                CustomTextWidget(
                                  title: "Tap to select image",
                                  fontSize: Get.height * 0.014,
                                  color: AppColors.black500,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight2),

                // Payment Details Section
                CustomTextWidget(
                  title: "Payment Details",
                  fontSize: Get.height * 0.02,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),

                SizedBox(height: screenHeight1),

                // Account Number Field
                CustomTextFieldWidget(
                  isBoldTextNeeded: true,
                  hintText: "Enter account number",
                  labelText: "Account Number",
                  keyboardType: TextInputType.number,
                  controller: _accountNumberController,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter account number";
                    }
                    if (value.length < 8) {
                      return "Account number must be at least 8 digits";
                    }
                    return null;
                  },
                ),

                // Account Name Field
                CustomTextFieldWidget(
                  isBoldTextNeeded: true,
                  hintText: "Enter account holder name",
                  labelText: "Account Holder Name",
                  keyboardType: TextInputType.name,
                  controller: _accountNameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter account holder name";
                    }
                    return null;
                  },
                ),

                // Bank Name Field
                CustomTextFieldWidget(
                  isBoldTextNeeded: true,
                  hintText: "Enter bank name",
                  labelText: "Bank Name",
                  keyboardType: TextInputType.text,
                  controller: _bankNameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter bank name";
                    }
                    return null;
                  },
                ),

                // Bank Code Field
                CustomTextFieldWidget(
                  isBoldTextNeeded: true,
                  hintText: "Enter bank code/IFSC",
                  labelText: "Bank Code/IFSC",
                  keyboardType: TextInputType.text,
                  controller: _bankCodeController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter bank code";
                    }
                    // Basic IFSC validation
                    if (value.length != 11) {
                      return "Bank code should be 11 characters";
                    }
                    return null;
                  },
                ),

                // Amount Field
                CustomTextFieldWidget(
                  isBoldTextNeeded: true,
                  hintText: "Enter amount",
                  labelText: "Amount",
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  controller: _amountController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter amount";
                    }
                    double? amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return "Please enter a valid amount";
                    }
                    return null;
                  },
                ),

                // Cheque Number Field
                CustomTextFieldWidget(
                  isBoldTextNeeded: true,
                  hintText: "Enter cheque number",
                  labelText: "Cheque Number",
                  keyboardType: TextInputType.text,
                  controller: _chequeNumberController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter cheque number";
                    }
                    return null;
                  },
                ),

                // Cheque Date Field
                CustomTextFieldWidget(
                  isBoldTextNeeded: true,
                  hintText: "Select cheque date",
                  labelText: "Cheque Date",
                  keyboardType: TextInputType.none,
                  controller: _chequeDateController,
                  readOnly: true,
                  suffixIcon: true,

                  // suff: Icons.calendar_today,
                  suffixIconOnTap: _selectChequeDate,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please select cheque date";
                    }
                    return null;
                  },
                ),

                SizedBox(height: screenHeight3),

                // Submit Button
                CustomButtonWidget(
                  buttonTitle:
                      _isSubmitting ? "Submitting..." : "Submit Cheque",
                  onPressed: _isSubmitting ? null : _submitCheque,
                ),

                SizedBox(height: screenHeight2),

                // Important Note
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenWidth1),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primaryColor,
                            size: Get.width * 0.05,
                          ),
                          SizedBox(width: screenWidth1),
                          CustomTextWidget(
                            title: "Important Note",
                            fontSize: Get.height * 0.016,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight05),
                      CustomTextWidget(
                        title:
                            "• Ensure all details match exactly with your cheque\n• Upload a clear image of the cheque\n• Cheque should be signed and dated\n• Processing may take 3-5 business days",
                        fontSize: Get.height * 0.014,
                        color: AppColors.black500,
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pickChequeImage() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: Get.height * 0.25,
          padding: EdgeInsets.all(screenWidth1),
          child: Column(
            children: [
              CustomTextWidget(
                title: "Select Cheque Image",
                fontSize: Get.height * 0.02,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: screenHeight1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(screenWidth1),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: AppColors.primaryColor,
                            size: Get.width * 0.08,
                          ),
                        ),
                        SizedBox(height: screenHeight05),
                        CustomTextWidget(
                          title: "Camera",
                          fontSize: Get.height * 0.014,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(screenWidth1),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.photo_library,
                            color: AppColors.primaryColor,
                            size: Get.width * 0.08,
                          ),
                        ),
                        SizedBox(height: screenHeight05),
                        CustomTextWidget(
                          title: "Gallery",
                          fontSize: Get.height * 0.014,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _pickImageFromCamera() async {
    // Implement camera image picker
    // You'll need to add image_picker package to pubspec.yaml
    // final ImagePicker picker = ImagePicker();
    // final XFile? image = await picker.pickImage(source: ImageSource.camera);
    // if (image != null) {
    //   setState(() {
    //     _chequeImageFile = File(image.path);
    //   });
    // }

    // For now, showing a placeholder message
    Get.snackbar(
      'Info',
      'Camera functionality to be implemented',
      backgroundColor: AppColors.primaryColor,
      colorText: AppColors.white,
    );
  }

  void _pickImageFromGallery() async {
    // Implement gallery image picker
    // You'll need to add image_picker package to pubspec.yaml
    // final ImagePicker picker = ImagePicker();
    // final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    // if (image != null) {
    //   setState(() {
    //     _chequeImageFile = File(image.path);
    //   });
    // }

    // For now, showing a placeholder message
    Get.snackbar(
      'Info',
      'Gallery functionality to be implemented',
      backgroundColor: AppColors.primaryColor,
      colorText: AppColors.white,
    );
  }

  void _selectChequeDate() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _chequeDateController.text =
            DateFormat('dd/MM/yyyy').format(selectedDate);
      });
    }
  }

  Future<void> _submitCheque() async {
    if (_formKey.currentState!.validate()) {
      if (_chequeImageFile == null) {
        Get.snackbar(
          'Error',
          'Please upload cheque image',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        // Prepare cheque data
        Map<String, dynamic> chequeData = {
          'accountNumber': _accountNumberController.text.trim(),
          'accountName': _accountNameController.text.trim(),
          'bankName': _bankNameController.text.trim(),
          'bankCode': _bankCodeController.text.trim(),
          'amount': double.parse(_amountController.text.trim()),
          'chequeNumber': _chequeNumberController.text.trim(),
          'chequeDate': _chequeDateController.text.trim(),
          'chequeImage': _chequeImageFile,
        };

        // Call controller method to submit cheque
        // await _chequeController.submitCheque(chequeData);

        // Simulate API call
        await Future.delayed(Duration(seconds: 2));

        Get.snackbar(
          'Success',
          'Cheque submitted successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Clear form after successful submission
        _clearForm();

        // Navigate back or to success screen
        Get.back();
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to submit cheque: ${e.toString()}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _clearForm() {
    _accountNumberController.clear();
    _accountNameController.clear();
    _bankNameController.clear();
    _bankCodeController.clear();
    _amountController.clear();
    _chequeNumberController.clear();
    _chequeDateController.clear();
    setState(() {
      _chequeImageFile = null;
    });
  }
}
