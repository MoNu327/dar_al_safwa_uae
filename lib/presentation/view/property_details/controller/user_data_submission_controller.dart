import 'package:image_picker/image_picker.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../../../data/model/user_data_submission_model.dart';
import '../../../../data/repositories/api_services.dart';

class UserDataSubmissionController extends GetxController {
  RxBool isEditMode = true.obs;
  
  // Updated to use the new UserProfile model
  Rx<UserDataSubmissionModel> user = UserDataSubmissionModel(
    uid: '',
    firstName: '',
    lastName: '',
    address: '',
    email: '',
    mobile: '',
    propertyId: '0',
    unitId: '0',
    citizenship: true,
    additionalDocuments: [],
  ).obs;

  final ApiService apiService = ApiService();
  final isLoading = false.obs;
  final errorMessage = Rx<String?>(null);

  // Form controllers
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();

  // Citizenship selection
  RxInt selectedCitizenship = 1.obs;

  // File handling
  var selectedFiles = <File>[].obs; // Stores multiple uploaded files

  @override
  void onInit() {
    super.onInit();
    _initializeFromArguments();
  }

  void _initializeFromArguments() {
    final args = Get.arguments;
    
    if (args != null && args is Map<String, dynamic>) {
      debugPrint('📥 Received arguments: $args');
      
      // Determine citizenship
      bool citizenship = true;
      if (args.containsKey('passportNo') && args['passportNo']?.toString().isNotEmpty == true) {
        citizenship = false;
        debugPrint('🔍 Found passport data, setting citizenship to Foreign (false)');
      }

      selectedCitizenship.value = citizenship ? 1 : 0;
      
      // Create user model using the new UserProfile
      user.value = UserDataSubmissionModel(
        uid: FirebaseAuth.instance.currentUser?.uid ?? '',
        firstName: args['firstName']?.toString() ?? '',
        lastName: args['lastName']?.toString() ?? '',
        address: args['address']?.toString() ?? '',
        email: args['email']?.toString() ?? '',
        mobile: args['mobileNo']?.toString() ?? '',
        propertyId: args['propertyId']?.toString() ?? '0',
        unitId: args['unitId']?.toString() ?? '0',
        citizenship: citizenship,
        additionalDocuments: [],
      );

      _populateControllers();
    }
  }

  void _populateControllers() {
    firstNameCtrl.text = user.value.firstName;
    lastNameCtrl.text = user.value.lastName;
    addressCtrl.text = user.value.address;
    emailCtrl.text = user.value.email;
    mobileCtrl.text = user.value.mobile;
  }

  void updateUserFromControllers() {
    String cleanMobile = mobileCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
    
    user.value = UserDataSubmissionModel(
      uid: user.value.uid,
      firstName: firstNameCtrl.text.trim(),
      lastName: lastNameCtrl.text.trim(),
      address: addressCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      mobile: cleanMobile,
      propertyId: user.value.propertyId,
      unitId: user.value.unitId,
      citizenship: selectedCitizenship.value == 1,
      additionalDocuments: user.value.additionalDocuments,
    );
  }

  void changeCitizenshipType(int citizenshipType) {
    selectedCitizenship.value = citizenshipType;
    updateUserFromControllers();
  }

  bool validateForm() {
    updateUserFromControllers();
    
    if (user.value.firstName.isEmpty ||
        user.value.lastName.isEmpty ||
        user.value.address.isEmpty ||
        user.value.email.isEmpty ||
        user.value.mobile.isEmpty) {
      errorMessage.value = 'Please fill all required basic fields';
      return false;
    }

    if (!GetUtils.isEmail(user.value.email)) {
      errorMessage.value = 'Please enter a valid email address';
      return false;
    }

    String cleanMobile = user.value.mobile.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanMobile.length < 8) {
      errorMessage.value = 'Please enter a valid mobile number (minimum 8 digits)';
      return false;
    }

    mobileCtrl.text = cleanMobile;
    errorMessage.value = null;
    return true;
  }

  void addAdditionalDocument(String title, DateTime expiryDate, [dynamic file]) {
    final newDocument = AdditionalDocument(
      title: title,
      expiryDate: expiryDate,
      file: file,
    );
    
    user.value = UserDataSubmissionModel(
      uid: user.value.uid,
      firstName: user.value.firstName,
      lastName: user.value.lastName,
      address: user.value.address,
      email: user.value.email,
      mobile: user.value.mobile,
      propertyId: user.value.propertyId,
      unitId: user.value.unitId,
      citizenship: user.value.citizenship,
      additionalDocuments: [...user.value.additionalDocuments, newDocument],
    );
  }

  void removeAdditionalDocument(int index) {
    final updatedDocuments = List<AdditionalDocument>.from(user.value.additionalDocuments);
    if (index < updatedDocuments.length) {
      updatedDocuments.removeAt(index);
    }
    
    user.value = UserDataSubmissionModel(
      uid: user.value.uid,
      firstName: user.value.firstName,
      lastName: user.value.lastName,
      address: user.value.address,
      email: user.value.email,
      mobile: user.value.mobile,
      propertyId: user.value.propertyId,
      unitId: user.value.unitId,
      citizenship: user.value.citizenship,
      additionalDocuments: updatedDocuments,
    );
  }

  // File handling methods
  void addFile(File file) {
    selectedFiles.add(file);
  }

  void removeFile(int index) {
    if (index < selectedFiles.length) {
      selectedFiles.removeAt(index);
    }
  }

  Future<void> pickAndAddFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 88,
      );
      
      if (pickedFile != null) {
        addFile(File(pickedFile.path));
        Get.snackbar(
          'Success',
          'File added successfully',
          backgroundColor: AppColors.onlineGreen,
          colorText: AppColors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick file: $e',
        backgroundColor: AppColors.redColor,
        colorText: AppColors.white,
      );
    }
  }

  Future<void> submitUserData() async {
    if (!validateForm()) return;

    try {
      isLoading.value = true;
      errorMessage.value = null;

      // Clean mobile number
      String cleanMobile = user.value.mobile.replaceAll(RegExp(r'[^\d]'), '');
      
      // Create the final user profile with cleaned data
      final cleanedUserData = UserDataSubmissionModel(
        uid: user.value.uid,
        firstName: user.value.firstName,
        lastName: user.value.lastName,
        address: user.value.address,
        email: user.value.email,
        mobile: cleanMobile,
        propertyId: user.value.propertyId,
        unitId: user.value.unitId,
        citizenship: user.value.citizenship,
        additionalDocuments: user.value.additionalDocuments,
      );

      // Use the updated API service method
      final response = await apiService.submitUserDetailsAndDoc(cleanedUserData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        
        if (responseData['status'] == true) {
          _clearFormAfterSubmission();
          Get.snackbar(
            'Success',
            'Application submitted successfully!',
            backgroundColor: AppColors.onlineGreen,
            colorText: AppColors.white,
          );
          Get.offAllNamed('/navbar', arguments: {'initialIndex': 0});
        } else {
          throw Exception(responseData['message'] ?? 'Submission failed');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Submission Failed',
        e.toString(),
        backgroundColor: AppColors.redColor,
        colorText: AppColors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _clearFormAfterSubmission() {
    firstNameCtrl.clear();
    lastNameCtrl.clear();
    addressCtrl.clear();
    emailCtrl.clear();
    mobileCtrl.clear();
    selectedFiles.clear();
    
    user.value = UserDataSubmissionModel(
      uid: FirebaseAuth.instance.currentUser?.uid ?? '',
      firstName: '',
      lastName: '',
      address: '',
      email: '',
      mobile: '',
      propertyId: '0',
      unitId: '0',
      citizenship: true,
      additionalDocuments: [],
    );
    
    isEditMode.value = true;
    selectedCitizenship.value = 1;
    errorMessage.value = null;
  }

  void toggleEdit() {
    isEditMode.value = !isEditMode.value;
  }

  // Helper getters
  bool get isNativeCitizen => selectedCitizenship.value == 1;
  bool get isForeignCitizen => selectedCitizenship.value == 0;
  
  @override
  void onClose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    addressCtrl.dispose();
    emailCtrl.dispose();
    mobileCtrl.dispose();
    super.onClose();
  }
}