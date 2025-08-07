import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../../../data/model/user_data_submission_model.dart';
import '../../../../data/repositories/api_services.dart';

class UserDataSubmissionController extends GetxController {
  RxBool isEditMode = true.obs;
  
  // File management observables
  final RxMap<String, List<PlatformFile>> uploadedDocuments = <String, List<PlatformFile>>{}.obs;
  final RxMap<String, List<PlatformFile>> additionalDocuments = <String, List<PlatformFile>>{}.obs;
  final RxList<String> additionalDocumentTitles = <String>[].obs;
  
  // Document validation status
  final RxMap<String, bool> documentValidationStatus = <String, bool>{}.obs;
  
  // File upload progress
  final RxMap<String, double> uploadProgress = <String, double>{}.obs;
  final RxBool isUploadingFiles = false.obs;

  // Updated model initialization with new structure
  Rx<UserDataSubmissionModel> user = UserDataSubmissionModel(
    propertyId: 0,
    unitId: 0,
    uid: '',
    firstName: '',
    lastName: '',
    address: '',
    citizenship: 1, // Default to native (1)
    email: '',
    mobile: '',
    requiredDocumentTypes: [],
  ).obs;

  final ApiService apiService = ApiService();
  final isLoading = false.obs;
  final errorMessage = Rx<String?>(null);

  // Basic form controllers
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  
  // Native citizen controllers
  final civilIdCtrl = TextEditingController();
  final civilIdExpiryCtrl = TextEditingController();
  
  // Foreign citizen controllers
  final passportCtrl = TextEditingController();
  final visaCtrl = TextEditingController();
  final visaExpiryCtrl = TextEditingController();
  final expatCivilIdCtrl = TextEditingController();
  final expatCivilIdExpiryCtrl = TextEditingController();

  // Citizenship type selection
  RxInt selectedCitizenship = 1.obs; // 1 = native, 0 = foreign

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    
    if (args != null && args is Map<String, dynamic>) {
      // Determine citizenship based on available data
      int citizenship = 1; // Default to native
      if (args.containsKey('passportNo') && args['passportNo']?.isNotEmpty == true) {
        citizenship = 0; // Foreign if passport data exists
      }

      selectedCitizenship.value = citizenship;

      if (citizenship == 1) {
        // Native citizen
        user.value = UserDataSubmissionModel.native(
          propertyId: _parseToInt(args['propertyId']) ?? 0,
          unitId: _parseToInt(args['unitId']) ?? 0,
          uid: uid,
          firstName: args['firstName'] ?? '',
          lastName: args['lastName'] ?? '',
          address: args['address'] ?? '',
          email: args['email'] ?? '',
          mobile: args['mobileNo'] ?? '',
          civilId: args['civilId'] ?? '',
          civilIdExpiry: args['civilIdExpiry'] ?? '',
          requiredDocumentTypes: getRequiredDocTypes(citizenship),
        );
      } else {
        // Foreign citizen
        user.value = UserDataSubmissionModel.foreign(
          propertyId: _parseToInt(args['propertyId']) ?? 0,
          unitId: _parseToInt(args['unitId']) ?? 0,
          uid: uid,
          firstName: args['firstName'] ?? '',
          lastName: args['lastName'] ?? '',
          address: args['address'] ?? '',
          email: args['email'] ?? '',
          mobile: args['mobileNo'] ?? '',
          passportNo: args['passportNo'] ?? '',
          visaNo: args['visa'] ?? '',
          visaExpiryDate: args['visaExpiryDate'] ?? '',
          expatCivilId: args['expatCivilId'] ?? '',
          expatCivilIdExpiry: args['expatCivilIdExpiry'] ?? '',
          requiredDocumentTypes: getRequiredDocTypes(citizenship),
        );
      }

      _populateControllers();
      
      debugPrint('✅ User model initialized from arguments: ${user.value.toJson()}');
    } else {
      debugPrint('⚠️ No valid arguments passed to DocumentUploadScreen.');
    }
  }

  @override
  void onClose() {
    // Dispose all controllers to avoid memory leaks
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    addressCtrl.dispose();
    emailCtrl.dispose();
    mobileCtrl.dispose();
    civilIdCtrl.dispose();
    civilIdExpiryCtrl.dispose();
    passportCtrl.dispose();
    visaCtrl.dispose();
    visaExpiryCtrl.dispose();
    expatCivilIdCtrl.dispose();
    expatCivilIdExpiryCtrl.dispose();
    super.onClose();
  }

  // Helper method to parse string to int
  int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Get required document types based on citizenship (public method)
  List<String> getRequiredDocTypes(int citizenship) {
    if (citizenship == 1) {
      // Native citizen documents
      return ['civil_id_front', 'civil_id_back'];
    } else {
      // Foreign citizen documents
      return [
        'passport_first_page',
        'passport_last_page',
        'expat_civil_id_front',
        'expat_civil_id_back',
        'resident_visa'
      ];
    }
  }

  // Populate form controllers with user data
  void _populateControllers() {
    firstNameCtrl.text = user.value.firstName;
    lastNameCtrl.text = user.value.lastName;
    addressCtrl.text = user.value.address;
    emailCtrl.text = user.value.email;
    mobileCtrl.text = user.value.mobile;

    if (user.value.isNative) {
      civilIdCtrl.text = user.value.civilId ?? '';
      civilIdExpiryCtrl.text = user.value.civilIdExpiry ?? '';
    } else {
      passportCtrl.text = user.value.passportNo ?? '';
      visaCtrl.text = user.value.visaNo ?? '';
      visaExpiryCtrl.text = user.value.visaExpiryDate ?? '';
      expatCivilIdCtrl.text = user.value.expatCivilId ?? '';
      expatCivilIdExpiryCtrl.text = user.value.expatCivilIdExpiry ?? '';
    }
  }

  // Update user data from form controllers
  void updateUserFromControllers() {
    if (selectedCitizenship.value == 1) {
      // Native citizen
      user.value = UserDataSubmissionModel.native(
        propertyId: user.value.propertyId,
        unitId: user.value.unitId,
        uid: user.value.uid,
        firstName: firstNameCtrl.text,
        lastName: lastNameCtrl.text,
        address: addressCtrl.text,
        email: emailCtrl.text,
        mobile: mobileCtrl.text,
        civilId: civilIdCtrl.text,
        civilIdExpiry: civilIdExpiryCtrl.text,
        requiredDocumentTypes: getRequiredDocTypes(1),
        requiredDocuments: _getDocumentPaths(uploadedDocuments),
        additionalDocuments: _getDocumentPaths(additionalDocuments),
        additionalDocumentTitles: additionalDocumentTitles.toList(),
      );
    } else {
      // Foreign citizen
      user.value = UserDataSubmissionModel.foreign(
        propertyId: user.value.propertyId,
        unitId: user.value.unitId,
        uid: user.value.uid,
        firstName: firstNameCtrl.text,
        lastName: lastNameCtrl.text,
        address: addressCtrl.text,
        email: emailCtrl.text,
        mobile: mobileCtrl.text,
        passportNo: passportCtrl.text,
        visaNo: visaCtrl.text,
        visaExpiryDate: visaExpiryCtrl.text,
        expatCivilId: expatCivilIdCtrl.text,
        expatCivilIdExpiry: expatCivilIdExpiryCtrl.text,
        requiredDocumentTypes: getRequiredDocTypes(0),
        requiredDocuments: _getDocumentPaths(uploadedDocuments),
        additionalDocuments: _getDocumentPaths(additionalDocuments),
        additionalDocumentTitles: additionalDocumentTitles.toList(),
      );
    }
  }

  // Helper method to extract file paths from PlatformFile objects
  List<String>? _getDocumentPaths(Map<String, List<PlatformFile>> documents) {
    List<String> allPaths = [];
    
    for (var entry in documents.entries) {
      for (var file in entry.value) {
        if (file.path != null) {
          allPaths.add(file.path!);
        }
      }
    }
    
    return allPaths.isNotEmpty ? allPaths : null;
  }

  // Switch between native and foreign citizenship
  void changeCitizenshipType(int citizenshipType) {
    selectedCitizenship.value = citizenshipType;
    
    // Clear controllers when switching types
    if (citizenshipType == 1) {
      // Switched to native - clear foreign fields
      passportCtrl.clear();
      visaCtrl.clear();
      visaExpiryCtrl.clear();
      expatCivilIdCtrl.clear();
      expatCivilIdExpiryCtrl.clear();
    } else {
      // Switched to foreign - clear native fields
      civilIdCtrl.clear();
      civilIdExpiryCtrl.clear();
    }
    
    // Clear all documents as requirements change
    clearAllDocuments();
    
    updateUserFromControllers();
    
    debugPrint('🔄 Changed citizenship type to: ${citizenshipType == 1 ? 'Native' : 'Foreign'}');
  }

  // FILE PICKER METHODS

  // Pick files using file picker
  Future<List<PlatformFile>?> _pickFiles({
    bool allowMultiple = false,
    List<String>? allowedExtensions,
    FileType fileType = FileType.any,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: fileType,
        allowedExtensions: allowedExtensions,
        allowCompression: true,
      );

      if (result != null && result.files.isNotEmpty) {
        // Validate files before returning
        List<PlatformFile> validFiles = [];
        
        for (PlatformFile file in result.files) {
          if (await _validateFile(file)) {
            validFiles.add(file);
          }
        }
        
        return validFiles.isNotEmpty ? validFiles : null;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error picking files: $e');
      errorMessage('Error selecting files: ${e.toString()}');
      return null;
    }
  }

  // Validate selected file
  Future<bool> _validateFile(PlatformFile file) async {
    try {
      // Check file size (10MB limit)
      if (file.size > 10 * 1024 * 1024) {
        errorMessage('File "${file.name}" is too large. Maximum size is 10MB.');
        return false;
      }

      // Check if file path exists (for mobile platforms)
      if (file.path != null) {
        final fileObj = File(file.path!);
        if (!await fileObj.exists()) {
          errorMessage('File "${file.name}" not found.');
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error validating file: $e');
      errorMessage('Error validating file "${file.name}": ${e.toString()}');
      return false;
    }
  }

  // Pick and add required document
  Future<bool> pickAndAddRequiredDocument(String documentType) async {
    try {
      isUploadingFiles(true);
      uploadProgress[documentType] = 0.0;

      // Determine allowed file types based on document type
      List<String> allowedExtensions = _getAllowedExtensions(documentType);
      
      List<PlatformFile>? files = await _pickFiles(
        allowMultiple: false, // Most documents should be single files
        allowedExtensions: allowedExtensions,
        fileType: FileType.custom,
      );

      if (files != null && files.isNotEmpty) {
        PlatformFile file = files.first;
        
        // Additional validation for specific document types
        if (!_isValidFileTypeForDocument(file, documentType)) {
          errorMessage('Invalid file type for ${_getDocumentDisplayName(documentType)}. Please select: ${allowedExtensions.join(', ')}');
          return false;
        }

        // Add to uploaded documents
        if (!uploadedDocuments.containsKey(documentType)) {
          uploadedDocuments[documentType] = [];
        }
        
        uploadedDocuments[documentType]!.add(file);
        documentValidationStatus[documentType] = true;
        uploadProgress[documentType] = 1.0;
        
        // Update the user model
        updateUserFromControllers();
        
        debugPrint('✅ Added document: $documentType -> ${file.name}');
        
        Get.snackbar(
          'Success',
          'Document uploaded: ${_getDocumentDisplayName(documentType)}',
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
          duration: const Duration(seconds: 3),
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Error picking document: $e');
      errorMessage('Failed to select document: ${e.toString()}');
      return false;
    } finally {
      isUploadingFiles(false);
      uploadProgress.remove(documentType);
    }
  }

  // Pick and add additional document with title
  Future<bool> pickAndAddAdditionalDocument(String title) async {
    if (title.trim().isEmpty) {
      errorMessage('Please provide a title for the additional document');
      return false;
    }

    try {
      isUploadingFiles(true);
      final documentId = 'additional_${DateTime.now().millisecondsSinceEpoch}';
      uploadProgress[documentId] = 0.0;

      List<PlatformFile>? files = await _pickFiles(
        allowMultiple: false,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        fileType: FileType.custom,
      );

      if (files != null && files.isNotEmpty) {
        PlatformFile file = files.first;
        
        if (!additionalDocuments.containsKey(documentId)) {
          additionalDocuments[documentId] = [];
        }
        
        additionalDocuments[documentId]!.add(file);
        additionalDocumentTitles.add(title.trim());
        uploadProgress[documentId] = 1.0;
        
        updateUserFromControllers();
        debugPrint('✅ Added additional document: $title -> ${file.name}');
        
        Get.snackbar(
          'Success',
          'Additional document uploaded: $title',
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
          duration: const Duration(seconds: 3),
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Error adding additional document: $e');
      errorMessage('Failed to add additional document: ${e.toString()}');
      return false;
    } finally {
      isUploadingFiles(false);
    }
  }

  // Get allowed extensions for document type
  List<String> _getAllowedExtensions(String documentType) {
    // Images are required for ID documents
    final imageExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    final pdfExtensions = ['pdf'];
    
    // ID documents typically need to be images for better OCR
    if (documentType.contains('civil_id') || documentType.contains('passport')) {
      return imageExtensions;
    }
    
    // Visa documents can be PDF or images
    if (documentType.contains('visa')) {
      return [...imageExtensions, ...pdfExtensions];
    }
    
    // Default: allow all supported formats
    return [...imageExtensions, ...pdfExtensions];
  }

  // Check if file type is valid for specific document
  bool _isValidFileTypeForDocument(PlatformFile file, String documentType) {
    final allowedExtensions = _getAllowedExtensions(documentType);
    final fileExtension = file.extension?.toLowerCase();
    
    return fileExtension != null && allowedExtensions.contains(fileExtension);
  }

  // Remove required document
  void removeRequiredDocument(String documentType, PlatformFile file) {
    try {
      if (uploadedDocuments.containsKey(documentType)) {
        uploadedDocuments[documentType]!.removeWhere((f) => f.name == file.name);
        
        if (uploadedDocuments[documentType]!.isEmpty) {
          uploadedDocuments.remove(documentType);
          documentValidationStatus[documentType] = false;
        }
        
        updateUserFromControllers();
        debugPrint('🗑️ Removed document: $documentType -> ${file.name}');
        
        Get.snackbar(
          'Removed',
          'Document removed: ${_getDocumentDisplayName(documentType)}',
          backgroundColor: Get.theme.colorScheme.secondary,
          colorText: Get.theme.colorScheme.onSecondary,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint('❌ Error removing document: $e');
    }
  }

  // Remove additional document
  void removeAdditionalDocument(String documentId, PlatformFile file) {
    try {
      if (additionalDocuments.containsKey(documentId)) {
        final fileIndex = additionalDocuments[documentId]!.indexWhere((f) => f.name == file.name);
        if (fileIndex != -1) {
          additionalDocuments[documentId]!.removeAt(fileIndex);
          if (fileIndex < additionalDocumentTitles.length) {
            additionalDocumentTitles.removeAt(fileIndex);
          }
          
          if (additionalDocuments[documentId]!.isEmpty) {
            additionalDocuments.remove(documentId);
          }
          
          updateUserFromControllers();
          debugPrint('🗑️ Removed additional document: $documentId -> ${file.name}');
          
          Get.snackbar(
            'Removed',
            'Additional document removed',
            backgroundColor: Get.theme.colorScheme.secondary,
            colorText: Get.theme.colorScheme.onSecondary,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error removing additional document: $e');
    }
  }

  // Validate documents based on citizenship
  bool validateDocuments() {
    try {
      final requiredTypes = getRequiredDocTypes(selectedCitizenship.value);
      
      for (var docType in requiredTypes) {
        if (!uploadedDocuments.containsKey(docType) || uploadedDocuments[docType]!.isEmpty) {
          errorMessage('Missing required document: ${_getDocumentDisplayName(docType)}');
          return false;
        }
      }
      
      errorMessage(null);
      return true;
    } catch (e) {
      debugPrint('❌ Error validating documents: $e');
      errorMessage('Error validating documents: ${e.toString()}');
      return false;
    }
  }

  // Get human-readable document name
  String _getDocumentDisplayName(String documentType) {
    final displayNames = {
      'civil_id_front': 'Civil ID Front',
      'civil_id_back': 'Civil ID Back',
      'passport_first_page': 'Passport First Page',
      'passport_last_page': 'Passport Last Page',
      'passport_visa_page': 'Passport Visa Page',
      'resident_visa': 'Resident Visa',
      'expat_civil_id_front': 'Expat Civil ID Front',
      'expat_civil_id_back': 'Expat Civil ID Back',
    };
    
    return displayNames[documentType] ?? documentType.replaceAll('_', ' ').toUpperCase();
  }

  // Get document completion status
  double get documentCompletionPercentage {
    final requiredTypes = getRequiredDocTypes(selectedCitizenship.value);
    if (requiredTypes.isEmpty) return 1.0;
    
    int completedDocs = 0;
    for (var docType in requiredTypes) {
      if (uploadedDocuments.containsKey(docType) && uploadedDocuments[docType]!.isNotEmpty) {
        completedDocs++;
      }
    }
    
    return completedDocs / requiredTypes.length;
  }

  // Get missing documents
  List<String> get missingDocuments {
    final requiredTypes = getRequiredDocTypes(selectedCitizenship.value);
    final missing = <String>[];
    
    for (var docType in requiredTypes) {
      if (!uploadedDocuments.containsKey(docType) || uploadedDocuments[docType]!.isEmpty) {
        missing.add(_getDocumentDisplayName(docType));
      }
    }
    
    return missing;
  }

  // Check if specific document type is uploaded
  bool isDocumentUploaded(String documentType) {
    return uploadedDocuments.containsKey(documentType) && 
           uploadedDocuments[documentType]!.isNotEmpty;
  }

  // Get uploaded files count for a document type
  int getUploadedFilesCount(String documentType) {
    return uploadedDocuments[documentType]?.length ?? 0;
  }

  // Get uploaded files for a document type
  List<PlatformFile> getUploadedFiles(String documentType) {
    return uploadedDocuments[documentType] ?? [];
  }

  // Get file size in readable format
  String getFileSize(PlatformFile file) {
    double sizeInMB = file.size / (1024 * 1024);
    return '${sizeInMB.toStringAsFixed(2)} MB';
  }

  // Clear all documents (useful when switching citizenship types)
  void clearAllDocuments() {
    uploadedDocuments.clear();
    additionalDocuments.clear();
    additionalDocumentTitles.clear();
    documentValidationStatus.clear();
    uploadProgress.clear();
    updateUserFromControllers();
    debugPrint('🧹 Cleared all documents');
  }

  // Enhanced form validation
 // Enhanced form validation - FIXED VERSION
bool validateForm() {
  updateUserFromControllers();
  
  // Basic validation
  if (user.value.firstName.isEmpty ||
      user.value.lastName.isEmpty ||
      user.value.address.isEmpty ||
      user.value.email.isEmpty ||
      user.value.mobile.isEmpty) {
    errorMessage('Please fill all required basic fields');
    return false;
  }

  // Email validation
  if (!GetUtils.isEmail(user.value.email)) {
    errorMessage('Please enter a valid email address');
    return false;
  }

  // Mobile validation (simple check)
  if (user.value.mobile.length < 8) {
    errorMessage('Please enter a valid mobile number');
    return false;
  }

  // Citizenship-specific validation
  if (!user.value.isValid()) {
    if (user.value.isNative) {
      errorMessage('Please fill all required native citizen fields (Civil ID and expiry date)');
    } else {
      errorMessage('Please fill all required foreign citizen fields (Passport, Visa, Expat Civil ID details)');
    }
    return false;
  }

  // REMOVE DOCUMENT VALIDATION FROM HERE - Documents are validated on the upload screen
  // Document validation should only happen after user uploads documents
  
  errorMessage(null);
  return true;
}

// Separate method for document validation - only call this on document upload screen
bool validateDocumentsForSubmission() {
  try {
    final requiredTypes = getRequiredDocTypes(selectedCitizenship.value);
    
    for (var docType in requiredTypes) {
      if (!uploadedDocuments.containsKey(docType) || uploadedDocuments[docType]!.isEmpty) {
        errorMessage('Missing required document: ${_getDocumentDisplayName(docType)}');
        return false;
      }
    }
    
    errorMessage(null);
    return true;
  } catch (e) {
    debugPrint('❌ Error validating documents: $e');
    errorMessage('Error validating documents: ${e.toString()}');
    return false;
  }
}

// Updated submission method that validates documents only when submitting
Future<void> submitWithValidation() async {
  // First validate form data (without documents)
  if (validateForm()) {
    // Then validate documents only if we're submitting (documents should be uploaded by now)
    if (validateDocumentsForSubmission()) {
      await submitUserDataAndDocs(user.value);
    }
  }
}

  // Enhanced submission with better error handling
  Future<void> submitUserDataAndDocs(UserDataSubmissionModel userData) async {
    try {
      isLoading(true);
      errorMessage(null);

      debugPrint('📤 Submitting user data: ${userData.firstName} ${userData.lastName}');
      debugPrint('📄 Documents: ${userData.requiredDocuments?.length ?? 0} required, ${userData.additionalDocuments?.length ?? 0} additional');
      debugPrint('🏛️ Citizenship: ${userData.isNative ? 'Native' : 'Foreign'}');
      
      final response = await apiService.submitUserDetailsAndDoc(userData);
      
      debugPrint('📡 API Response: ${response.statusCode} - ${response.statusMessage}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final submitResponse = response.data;
        debugPrint("✅ Submission successful: ${submitResponse["data"]}");
        
        // Clear form after successful submission
        _clearFormAfterSubmission();
        
        Get.snackbar(
          'Success',
          'Application submitted successfully! You will receive a confirmation email shortly.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
          duration: const Duration(seconds: 5),
        );
        
        // Navigate to success screen or home
        Get.offAllNamed('/home');
        
      } else {
        debugPrint('❌ Submission failed: ${response.statusMessage}');
        throw Exception("Failed to submit application: ${response.statusMessage}");
      }
    } catch (e) {
      debugPrint('💥 Submission error: $e');
      errorMessage('Submission failed: ${e.toString()}');
      
      Get.snackbar(
        'Submission Error',
        'Failed to submit application. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading(false);
      debugPrint('📋 Submission process completed');
    }
  }

  

  // Clear form after successful submission
  void _clearFormAfterSubmission() {
    // Clear controllers
    firstNameCtrl.clear();
    lastNameCtrl.clear();
    addressCtrl.clear();
    emailCtrl.clear();
    mobileCtrl.clear();
    civilIdCtrl.clear();
    civilIdExpiryCtrl.clear();
    passportCtrl.clear();
    visaCtrl.clear();
    visaExpiryCtrl.clear();
    expatCivilIdCtrl.clear();
    expatCivilIdExpiryCtrl.clear();
    
    // Clear documents
    clearAllDocuments();
    
    // Reset form state
    isEditMode.value = true;
    selectedCitizenship.value = 1;
    errorMessage(null);
  }

  // Submit with validation
  // Future<void> submitWithValidation() async {
  //   if (validateForm()) {
  //     await submitUserDataAndDocs(user.value);
  //   }
  // }

  void toggleEdit() {
    isEditMode.value = !isEditMode.value;
  }

  // Helper getters for UI
  bool get isNativeCitizen => selectedCitizenship.value == 1;
  bool get isForeignCitizen => selectedCitizenship.value == 0;
  
  String get citizenshipLabel => isNativeCitizen ? 'Native' : 'Foreign';
  
  List<String> get requiredDocumentLabels {
    if (isNativeCitizen) {
      return ['Civil ID Front', 'Civil ID Back'];
    } else {
      return [
        'Passport First Page',
        'Passport Last Page', 
        'Expat Civil ID Front',
        'Expat Civil ID Back',
        'Resident Visa'
      ];
    }
  }



  // Get document types mapped to display names
  Map<String, String> get documentTypeMapping {
    if (isNativeCitizen) {
      return {
        'civil_id_front': 'Civil ID Front',
        'civil_id_back': 'Civil ID Back',
      };
    } else {
      return {
        'passport_first_page': 'Passport First Page',
        'passport_last_page': 'Passport Last Page',
        'expat_civil_id_front': 'Expat Civil ID Front',
        'expat_civil_id_back': 'Expat Civil ID Back',
        'resident_visa': 'Resident Visa',
      };
    }
  }

  // Get progress information for UI
  String get progressText {
    final percentage = (documentCompletionPercentage * 100).toStringAsFixed(1);
    return 'Documents completed: $percentage% (${uploadedDocuments.length} of ${getRequiredDocTypes(selectedCitizenship.value).length})';
  }
}