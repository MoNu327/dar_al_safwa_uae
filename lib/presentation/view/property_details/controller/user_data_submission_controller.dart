import 'package:cloud_firestore/cloud_firestore.dart';
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
  final isFetchingUserData =
      false.obs; // New loading state for fetching user data
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
    _initializeUserData();
  }

  // Method to extract only the last 8 digits (remove country code)
  String _extractPhoneNumber(String fullNumber) {
    if (fullNumber.isEmpty) return '';

    // Remove all non-digit characters first
    String cleanNumber = fullNumber.replaceAll(RegExp(r'[^\d]'), '');

    // If number is longer than 8 digits, take the last 8 digits
    if (cleanNumber.length > 8) {
      return cleanNumber.substring(cleanNumber.length - 8);
    }

    // If it's exactly 8 digits or less, return as is
    return cleanNumber;
  }

  // Method to format phone number for display (without country code)
  String _formatPhoneNumberForDisplay(String phoneNumber) {
    String extracted = _extractPhoneNumber(phoneNumber);

    if (extracted.isEmpty) return '';

    // Format as XXXX XXXX if we have 8 digits
    if (extracted.length == 8) {
      return '${extracted.substring(0, 4)} ${extracted.substring(4)}';
    }

    return extracted;
  }

  // New method to fetch user data from Firestore
  Future<Map<String, String>> _fetchUserDataFromFirestore() async {
    try {
      isFetchingUserData.value = true;
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint('❌ No authenticated user found');
        return {};
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        debugPrint('📥 Fetched user data from Firestore: $data');

        // Extract user data with fallbacks
        final firebaseEmail = user.email ?? '';
        final firestoreEmail = data?['email']?.toString() ?? '';
        final phoneNumber = data?['phoneNumber']?.toString() ?? '';
        final phone = data?['phone']?.toString() ?? '';
        final firstName = data?['firstName']?.toString() ?? '';
        final lastName = data?['lastName']?.toString() ?? '';
        final address = data?['address']?.toString() ?? '';

        // Determine which email to use (prioritize Firebase auth email)
        final finalEmail =
            firebaseEmail.isNotEmpty ? firebaseEmail : firestoreEmail;

        // Determine which mobile number to use (prioritize phoneNumber field)
        final finalMobile = phoneNumber.isNotEmpty ? phoneNumber : phone;

        // Extract only the last 8 digits for display
        final displayMobile = _extractPhoneNumber(finalMobile);

        debugPrint(
            '📧 Email - Firebase: $firebaseEmail, Firestore: $firestoreEmail, Final: $finalEmail');
        debugPrint('📱 Mobile - Raw: $finalMobile, Extracted: $displayMobile');

        return {
          'email': finalEmail,
          'mobile': displayMobile, // Use extracted 8 digits for display
          'mobileFull': finalMobile, // Keep full number for submission
          'firstName': firstName,
          'lastName': lastName,
          'address': address,
        };
      } else {
        debugPrint('📭 No user document found in Firestore');
        return {};
      }
    } catch (e) {
      debugPrint('❌ Error fetching user data from Firestore: $e');
      return {};
    } finally {
      isFetchingUserData.value = false;
    }
  }

  Future<void> _initializeUserData() async {
    try {
      // First fetch existing user data from Firestore
      final userData = await _fetchUserDataFromFirestore();

      // Then process arguments (arguments can override existing data)
      final args = Get.arguments;

      if (args != null && args is Map<String, dynamic>) {
        debugPrint('📥 Received arguments: $args');

        // Determine citizenship from arguments
        bool citizenship = true;
        if (args.containsKey('passportNo') &&
            args['passportNo']?.toString().isNotEmpty == true) {
          citizenship = false;
          debugPrint(
              '🔍 Found passport data, setting citizenship to Foreign (false)');
        }

        selectedCitizenship.value = citizenship ? 1 : 0;

        // Extract mobile number from arguments if present
        final argumentMobile = args['mobileNo']?.toString() ?? '';
        final displayArgumentMobile = _extractPhoneNumber(argumentMobile);

        // Create user model using the new UserProfile
        // Use existing user data as fallback for empty argument values
        user.value = UserDataSubmissionModel(
          uid: FirebaseAuth.instance.currentUser?.uid ?? '',
          firstName:
              args['firstName']?.toString() ?? userData['firstName'] ?? '',
          lastName: args['lastName']?.toString() ?? userData['lastName'] ?? '',
          address: args['address']?.toString() ?? userData['address'] ?? '',
          email: args['email']?.toString() ?? userData['email'] ?? '',
          mobile: displayArgumentMobile.isNotEmpty
              ? displayArgumentMobile
              : userData['mobile'] ?? '',
          propertyId: args['propertyId']?.toString() ?? '0',
          unitId: args['unitId']?.toString() ?? '0',
          citizenship: citizenship,
          additionalDocuments: [],
        );

        _populateControllers();

        debugPrint('✅ Final populated data:');
        debugPrint('   First Name: ${user.value.firstName}');
        debugPrint('   Last Name: ${user.value.lastName}');
        debugPrint('   Address: ${user.value.address}');
        debugPrint('   Email: ${user.value.email}');
        debugPrint('   Mobile (display): ${user.value.mobile}');
      } else {
        // No arguments, use only Firestore data
        debugPrint('📭 No arguments provided, using Firestore data only');

        user.value = UserDataSubmissionModel(
          uid: FirebaseAuth.instance.currentUser?.uid ?? '',
          firstName: userData['firstName'] ?? '',
          lastName: userData['lastName'] ?? '',
          address: userData['address'] ?? '',
          email: userData['email'] ?? '',
          mobile:
              userData['mobile'] ?? '', // This is already extracted 8 digits
          propertyId: '0',
          unitId: '0',
          citizenship: true,
          additionalDocuments: [],
        );

        _populateControllers();
      }
    } catch (e) {
      debugPrint('❌ Error initializing user data: $e');
    }
  }

  void _populateControllers() {
    firstNameCtrl.text = user.value.firstName;
    lastNameCtrl.text = user.value.lastName;
    addressCtrl.text = user.value.address;
    emailCtrl.text = user.value.email;

    // Format mobile number for display (XXXX XXXX format)
    mobileCtrl.text = _formatPhoneNumberForDisplay(user.value.mobile);

    debugPrint('🎯 Controllers populated:');
    debugPrint('   First Name Ctrl: ${firstNameCtrl.text}');
    debugPrint('   Last Name Ctrl: ${lastNameCtrl.text}');
    debugPrint('   Email Ctrl: ${emailCtrl.text}');
    debugPrint('   Mobile Ctrl: ${mobileCtrl.text}');
  }

  void updateUserFromControllers() {
    // For mobile, we only store the 8 digits (country code will be added during submission)
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
      errorMessage.value =
          'Please enter a valid mobile number (minimum 8 digits)';
      return false;
    }

    // Format the mobile number for display
    mobileCtrl.text = _formatPhoneNumberForDisplay(cleanMobile);
    errorMessage.value = null;
    return true;
  }

  void addAdditionalDocument(String title, DateTime expiryDate,
      [dynamic file]) {
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
    final updatedDocuments =
        List<AdditionalDocument>.from(user.value.additionalDocuments);
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

      // Clean mobile number (should be 8 digits without country code)
      String cleanMobile = user.value.mobile.replaceAll(RegExp(r'[^\d]'), '');

      // The mobile stored in user.value should already be 8 digits without country code
      debugPrint(
          '📱 Mobile for submission: $cleanMobile (8 digits without country code)');

      // Create the final user profile with cleaned data
      final cleanedUserData = UserDataSubmissionModel(
        uid: user.value.uid,
        firstName: user.value.firstName,
        lastName: user.value.lastName,
        address: user.value.address,
        email: user.value.email,
        mobile: cleanMobile, // This should be 8 digits without country code
        propertyId: user.value.propertyId,
        unitId: user.value.unitId,
        citizenship: user.value.citizenship,
        additionalDocuments: user.value.additionalDocuments,
      );

      // Debug the data structure before sending
      debugPrint('🔍 Final data structure:');
      debugPrint('   First Name: ${user.value.firstName}');
      debugPrint('   Last Name: ${user.value.lastName}');
      debugPrint('   Email: ${user.value.email}');
      debugPrint('   Mobile: $cleanMobile (8 digits)');
      debugPrint('   Citizenship: ${user.value.citizenship}');
      debugPrint(
          '   Additional Documents: ${user.value.additionalDocuments.length}');

      for (int i = 0; i < user.value.additionalDocuments.length; i++) {
        var doc = user.value.additionalDocuments[i];
        debugPrint('   Document $i: ${doc.title} - ${doc.expiryDate}');
      }

      // Use the updated API service method
      final response =
          await apiService.submitUserDetailsAndDoc(cleanedUserData);

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
        // Handle API errors with more detail
        String errorMsg = 'HTTP ${response.statusCode}';
        if (response.data != null && response.data is Map) {
          var errorData = response.data as Map;
          if (errorData.containsKey('message')) {
            errorMsg += ': ${errorData['message']}';
          }
          if (errorData.containsKey('errors')) {
            errorMsg += '\nErrors: ${errorData['errors']}';
          }
        }
        throw Exception(errorMsg);
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
