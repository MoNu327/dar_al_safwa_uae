import 'package:dar_al_safwa/core/theme/app_colors.dart';
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
    RxString propertyName = ''.obs;
  RxString unitTypeName = ''.obs;
  RxInt unitTypeId = 0.obs;
  RxInt selectedCount = 1.obs;
  final RxMap<String, List<PlatformFile>> uploadedDocuments = <String, List<PlatformFile>>{}.obs;
  final RxMap<String, List<PlatformFile>> additionalDocuments = <String, List<PlatformFile>>{}.obs;
  final RxList<String> additionalDocumentTitles = <String>[].obs;
   RxBool isCheckingCommercialStatus = false.obs;
  RxBool isCommercialFromAPI = false.obs;
  
  
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
    propertyType: 'residential', // Default to residential
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

  // Commercial property controllers
  final crNumberCtrl = TextEditingController();
  final crExpiryCtrl = TextEditingController();
  final municipalityLicenseNumberCtrl = TextEditingController();
  final municipalityLicenseDateCtrl = TextEditingController();
  final companyAddressCtrl = TextEditingController();
  final poBoxCtrl = TextEditingController();

  // Citizenship type selection
  RxInt selectedCitizenship = 1.obs; // 1 = native, 0 = foreign
  RxString selectedPropertyType = 'residential'.obs; // 'residential' or 'commercial'

 @override
void onInit() {
  super.onInit();

  final args = Get.arguments;
  final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
  
  if (args != null && args is Map<String, dynamic>) {
    // DEBUG: Print received arguments
    debugPrint('📥 Received arguments: $args');
    
    // Determine citizenship based on available data - FIXED LOGIC
    int citizenship = 1; // Default to native
    if (args.containsKey('passportNo') && args['passportNo']?.toString().isNotEmpty == true) {
      citizenship = 0; // Foreign if passport data exists
      debugPrint('🔍 Found passport data, setting citizenship to Foreign (0)');
    } else {
      debugPrint('🔍 No passport data found, keeping citizenship as Native (1)');
    }

    // Determine property type
    String propertyType = args['propertyType']?.toString() ?? 'residential';
    debugPrint('🔍 Property type: $propertyType');

    // IMPORTANT: Set the reactive values BEFORE creating the user model
    selectedCitizenship.value = citizenship;
    selectedPropertyType.value = propertyType;
    
    debugPrint('✅ Set selectedCitizenship: ${selectedCitizenship.value}');
    debugPrint('✅ Set selectedPropertyType: ${selectedPropertyType.value}');

    // Create user model based on citizenship type
    if (citizenship == 1) {
      // Native citizen
      user.value = UserDataSubmissionModel.native(
        uid: uid,
        firstName: args['firstName']?.toString() ?? '',
        lastName: args['lastName']?.toString() ?? '',
        address: args['address']?.toString() ?? '',
        email: args['email']?.toString() ?? '',
        mobile: args['mobileNo']?.toString() ?? '',
        propertyId: _parseToInt(args['propertyId']) ?? 0,
        unitId: _parseToInt(args['unitId']) ?? 0,
        civilId: args['civilId']?.toString() ?? '',
        civilIdExpiry: args['civilIdExpiry']?.toString() ?? '',
        requiredDocumentTypes: getRequiredDocTypes(1, propertyType),
        propertyType: propertyType,
        // Commercial fields if applicable
        crNumber: propertyType == 'commercial' ? args['crNumber']?.toString() : null,
        crExpiryDate: propertyType == 'commercial' ? args['crExpiryDate']?.toString() : null,
        municipalityLicenseNumber: propertyType == 'commercial' ? args['municipalityLicenseNumber']?.toString() : null,
        municipalityLicenseDate: propertyType == 'commercial' ? args['municipalityLicenseDate']?.toString() : null,
        companyAddress: propertyType == 'commercial' ? args['companyAddress']?.toString() : null,
        poBox: propertyType == 'commercial' ? args['poBox']?.toString() : null,
      );
    } else {
      // Foreign citizen
      user.value = UserDataSubmissionModel.foreign(
        uid: uid,
        firstName: args['firstName']?.toString() ?? '',
        lastName: args['lastName']?.toString() ?? '',
        address: args['address']?.toString() ?? '',
        email: args['email']?.toString() ?? '',
        mobile: args['mobileNo']?.toString() ?? '',
        propertyId: _parseToInt(args['propertyId']) ?? 0,
        unitId: _parseToInt(args['unitId']) ?? 0,
        passportNo: args['passportNo']?.toString() ?? '',
        visaNo: args['visa']?.toString() ?? '',
        visaExpiryDate: args['visaExpiryDate']?.toString() ?? '',
        expatCivilId: args['expatCivilId']?.toString() ?? '',
        expatCivilIdExpiry: args['expatCivilIdExpiry']?.toString() ?? '',
        requiredDocumentTypes: getRequiredDocTypes(0, propertyType),
        propertyType: propertyType,
        // Commercial fields if applicable
        crNumber: propertyType == 'commercial' ? args['crNumber']?.toString() : null,
        crExpiryDate: propertyType == 'commercial' ? args['crExpiryDate']?.toString() : null,
        municipalityLicenseNumber: propertyType == 'commercial' ? args['municipalityLicenseNumber']?.toString() : null,
        municipalityLicenseDate: propertyType == 'commercial' ? args['municipalityLicenseDate']?.toString() : null,
        companyAddress: propertyType == 'commercial' ? args['companyAddress']?.toString() : null,
        poBox: propertyType == 'commercial' ? args['poBox']?.toString() : null,
      );
    }

    _populateControllers();
    
    debugPrint('✅ User model initialized - Citizenship: ${user.value.citizenship} (${user.value.isNative ? "Native" : "Foreign"})');
    debugPrint('✅ User model created: ${user.value.toJson()}');
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
    crNumberCtrl.dispose();
    crExpiryCtrl.dispose();
    municipalityLicenseNumberCtrl.dispose();
    municipalityLicenseDateCtrl.dispose();
    companyAddressCtrl.dispose();
    poBoxCtrl.dispose();
    super.onClose();
  }

  // Helper method to parse string to int
  int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Get required document types based on citizenship and property type
  List<String> getRequiredDocTypes(int citizenship, String propertyType) {
  List<String> documents = [];
  
  if (citizenship == 1) {
    // Native citizen documents
    documents.addAll(['civil_id_front', 'civil_id_back']);
  } else {
    // Foreign citizen documents  
    documents.addAll([
      'passport_first_page',
      'passport_last_page', 
      'passport_visa_page', // Added this back
      'resident_visa',
      'expat_civil_id_front',
      'expat_civil_id_back'
    ]);
  }
  
  if (propertyType == 'commercial') {
    // Commercial documents (matching Laravel backend)
    documents.addAll([
      'commercial_registration',
      'municipality_license',
      'board_resolution' // This matches your Laravel backend
    ]);
  }
  
  return documents;
}
  // Populate form controllers with user data
  void _populateControllers() {
    firstNameCtrl.text = user.value.firstName;
    lastNameCtrl.text = user.value.lastName;
    addressCtrl.text = user.value.address;
    emailCtrl.text = user.value.email;
    mobileCtrl.text = user.value.mobile;
    selectedPropertyType.value = user.value.propertyType ?? 'residential';

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

    // Commercial fields
    if (user.value.isCommercial) {
      crNumberCtrl.text = user.value.crNumber ?? '';
      crExpiryCtrl.text = user.value.crExpiryDate ?? '';
      municipalityLicenseNumberCtrl.text = user.value.municipalityLicenseNumber ?? '';
      municipalityLicenseDateCtrl.text = user.value.municipalityLicenseDate ?? '';
      companyAddressCtrl.text = user.value.companyAddress ?? '';
      poBoxCtrl.text = user.value.poBox ?? '';
    }
  }

  // Update user data from form controllers
void updateUserFromControllers() {
  // Clean mobile number first
  String cleanMobile = mobileCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
  
  if (selectedCitizenship.value == 1) {
    // Native citizen - Make sure foreign fields are null
    user.value = UserDataSubmissionModel.native(
      propertyId: user.value.propertyId,
      unitId: user.value.unitId,
      uid: user.value.uid,
      firstName: firstNameCtrl.text.trim(),
      lastName: lastNameCtrl.text.trim(),
      address: addressCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      mobile: cleanMobile,
      civilId: civilIdCtrl.text.trim(),
      civilIdExpiry: civilIdExpiryCtrl.text.trim(),
      requiredDocumentTypes: getRequiredDocTypes(1, selectedPropertyType.value),
      requiredDocuments: _getDocumentPaths(uploadedDocuments),
      additionalDocuments: _getDocumentPaths(additionalDocuments),
      additionalDocumentTitles: additionalDocumentTitles.toList(),
      propertyType: selectedPropertyType.value,
      // Commercial fields
      crNumber: selectedPropertyType.value == 'commercial' ? crNumberCtrl.text.trim() : null,
      crExpiryDate: selectedPropertyType.value == 'commercial' ? crExpiryCtrl.text.trim() : null,
      municipalityLicenseNumber: selectedPropertyType.value == 'commercial' ? municipalityLicenseNumberCtrl.text.trim() : null,
      municipalityLicenseDate: selectedPropertyType.value == 'commercial' ? municipalityLicenseDateCtrl.text.trim() : null,
      companyAddress: selectedPropertyType.value == 'commercial' ? companyAddressCtrl.text.trim() : null,
      poBox: selectedPropertyType.value == 'commercial' ? poBoxCtrl.text.trim() : null,
    );
  } else {
    // Foreign citizen - Make sure native fields are null
    user.value = UserDataSubmissionModel.foreign(
      propertyId: user.value.propertyId,
      unitId: user.value.unitId,
      uid: user.value.uid,
      firstName: firstNameCtrl.text.trim(),
      lastName: lastNameCtrl.text.trim(),
      address: addressCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      mobile: cleanMobile,
      passportNo: passportCtrl.text.trim(),
      visaNo: visaCtrl.text.trim(),
      visaExpiryDate: visaExpiryCtrl.text.trim(),
      expatCivilId: expatCivilIdCtrl.text.trim(),
      expatCivilIdExpiry: expatCivilIdExpiryCtrl.text.trim(),
      requiredDocumentTypes: getRequiredDocTypes(0, selectedPropertyType.value),
      requiredDocuments: _getDocumentPaths(uploadedDocuments),
      additionalDocuments: _getDocumentPaths(additionalDocuments),
      additionalDocumentTitles: additionalDocumentTitles.toList(),
      propertyType: selectedPropertyType.value,
      // Commercial fields
      crNumber: selectedPropertyType.value == 'commercial' ? crNumberCtrl.text.trim() : null,
      crExpiryDate: selectedPropertyType.value == 'commercial' ? crExpiryCtrl.text.trim() : null,
      municipalityLicenseNumber: selectedPropertyType.value == 'commercial' ? municipalityLicenseNumberCtrl.text.trim() : null,
      municipalityLicenseDate: selectedPropertyType.value == 'commercial' ? municipalityLicenseDateCtrl.text.trim() : null,
      companyAddress: selectedPropertyType.value == 'commercial' ? companyAddressCtrl.text.trim() : null,
      poBox: selectedPropertyType.value == 'commercial' ? poBoxCtrl.text.trim() : null,
    );
  }
  
  debugPrint('🔄 Updated user model - Citizenship: ${selectedCitizenship.value == 1 ? "Native" : "Foreign"}');
  debugPrint('📋 User data: ${user.value.toJson()}');
}

void debugSubmissionData() {
  updateUserFromControllers();
  
  debugPrint('=== SUBMISSION DEBUG INFO ===');
  debugPrint('Selected Citizenship: ${selectedCitizenship.value} (${selectedCitizenship.value == 1 ? "Native" : "Foreign"})');
  debugPrint('Selected Property Type: ${selectedPropertyType.value}');
  debugPrint('User Model Citizenship: ${user.value.citizenship}');
  debugPrint('User Model isNative: ${user.value.isNative}');
  debugPrint('User Model isForeign: ${!user.value.isNative}');
  
  if (selectedCitizenship.value == 1) {
    debugPrint('--- Native Fields ---');
    debugPrint('Civil ID: "${civilIdCtrl.text}"');
    debugPrint('Civil ID Expiry: "${civilIdExpiryCtrl.text}"');
    debugPrint('Passport (should be null): ${user.value.passportNo}');
    debugPrint('Visa (should be null): ${user.value.visaNo}');
  } else {
    debugPrint('--- Foreign Fields ---');
    debugPrint('Passport: "${passportCtrl.text}"');
    debugPrint('Visa: "${visaCtrl.text}"');
    debugPrint('Visa Expiry: "${visaExpiryCtrl.text}"');
    debugPrint('Expat Civil ID: "${expatCivilIdCtrl.text}"');
    debugPrint('Expat Civil ID Expiry: "${expatCivilIdExpiryCtrl.text}"');
    debugPrint('Civil ID (should be null): ${user.value.civilId}');
  }
  
  if (selectedPropertyType.value == 'commercial') {
    debugPrint('--- Commercial Fields ---');
    debugPrint('CR Number: "${crNumberCtrl.text}"');
    debugPrint('CR Expiry: "${crExpiryCtrl.text}"');
    debugPrint('Municipality License: "${municipalityLicenseNumberCtrl.text}"');
    debugPrint('Municipality License Date: "${municipalityLicenseDateCtrl.text}"');
    debugPrint('Company Address: "${companyAddressCtrl.text}"');
    debugPrint('PO Box: "${poBoxCtrl.text}"');
  }
  
  debugPrint('Mobile (cleaned): ${user.value.mobile}');
  debugPrint('Required Doc Types: ${user.value.requiredDocumentTypes}');
  debugPrint('=== END DEBUG INFO ===');
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

  // Switch between residential and commercial property type
  void changePropertyType(String type) {
    selectedPropertyType.value = type;
    
    // Clear commercial fields if switching to residential
    if (type == 'residential') {
      crNumberCtrl.clear();
      crExpiryCtrl.clear();
      municipalityLicenseNumberCtrl.clear();
      municipalityLicenseDateCtrl.clear();
      companyAddressCtrl.clear();
      poBoxCtrl.clear();
    }
    
    // Clear all documents as requirements change
    clearAllDocuments();
    
    updateUserFromControllers();
    
    debugPrint('🔄 Changed property type to: $type');
  }

  // FILE PICKER METHODS (remain the same as before)
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
      withData: false, // Don't load file data into memory
      withReadStream: false, // Don't create read streams
    );

    if (result != null && result.files.isNotEmpty) {
      List<PlatformFile> validFiles = [];
      
      for (PlatformFile file in result.files) {
        debugPrint('📁 Checking file: ${file.name} (${getFileSize(file)})');
        
        if (await _validateFile(file)) {
          validFiles.add(file);
          debugPrint('✅ File valid: ${file.name}');
        } else {
          debugPrint('❌ File invalid: ${file.name}');
        }
      }
      
      if (validFiles.isEmpty) {
        errorMessage('No valid files selected');
        return null;
      }
      
      return validFiles;
    }
    
    return null;
  } catch (e) {
    debugPrint('❌ FilePicker error: $e');
    errorMessage('Error selecting files: ${e.toString()}');
    return null;
  }
}

Future<bool> _validateFile(PlatformFile file) async {
  try {
    // Check file size (10MB limit)
    if (file.size > 10 * 1024 * 1024) {
      errorMessage('File "${file.name}" is too large (${getFileSize(file)}). Max: 10MB');
      return false;
    }

    // Minimum file size check (1KB)
    if (file.size < 1024) {
      errorMessage('File "${file.name}" is too small (${file.size} bytes). Minimum: 1KB');
      return false;
    }

    // Check if file path exists (for mobile platforms)
    if (file.path != null) {
      final fileObj = File(file.path!);
      if (!await fileObj.exists()) {
        errorMessage('File "${file.name}" not found at path');
        return false;
      }
      
      // Check readable
      try {
        await fileObj.readAsBytes();
      } catch (e) {
        errorMessage('Cannot read file "${file.name}"');
        return false;
      }
    }

    // Check file extension
    final extension = file.extension?.toLowerCase();
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'pdf'];
    
    if (extension == null || !allowedExtensions.contains(extension)) {
      errorMessage('Invalid file type "${extension}". Allowed: ${allowedExtensions.join(', ')}');
      return false;
    }

    return true;
  } catch (e) {
    debugPrint('❌ File validation error: $e');
    errorMessage('Error validating "${file.name}": ${e.toString()}');
    return false;
  }
}
    Future<void> checkCommercialPropertyStatus(int unitId) async {
  try {
    isCheckingCommercialStatus(true);
    errorMessage(null);
    
    debugPrint('🔍 Checking commercial status for unit: $unitId');
    
    // Create minimal payload
    final requestPayload = {
      'unitid': unitId,
      'user_id': FirebaseAuth.instance.currentUser?.uid ?? "",
    };
    
    debugPrint('📤 Request payload: $requestPayload');
    
    final response = await apiService.getCommercialPropertyStatus(unitId);
    
    debugPrint('📡 Response: ${response.statusCode}');
    debugPrint('📄 Response data: ${response.data}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = response.data;
      
      if (responseData['success'] == true) {
        bool isCommercial = responseData['data']['is_commercial'] ?? false;
        isCommercialFromAPI.value = isCommercial;
        changePropertyType(isCommercial ? "commercial" : "residential");
        
        debugPrint('✅ Property type: ${isCommercial ? "Commercial" : "Residential"}');
      } else {
        String errorMsg = responseData['message']?['en'] ?? 'Failed to check property type';
        errorMessage(errorMsg);
        debugPrint('❌ API Error: $errorMsg');
      }
    } else if (response.statusCode == 422) {
      // Special handling for validation errors
      final errorData = response.data;
      String errorMsg = 'Validation Error: ';
      
      if (errorData is Map && errorData.containsKey('errors')) {
        errorMsg += errorData['errors'].entries
          .map((e) => '${e.key}: ${e.value.join(', ')}')
          .join('; ');
      } else {
        errorMsg += 'Invalid request data';
      }
      
      debugPrint('❌ 422 Validation Error Details: $errorMsg');
      errorMessage(errorMsg);
    } else {
      String httpErrorMsg = 'HTTP Error ${response.statusCode}';
      errorMessage(httpErrorMsg);
      debugPrint('❌ HTTP Error: $httpErrorMsg');
    }
  } catch (e) {
    debugPrint('💥 Exception: $e');
    errorMessage('Failed to check property type');
  } finally {
    isCheckingCommercialStatus(false);
  }
}
  

  Future<bool> pickAndAddRequiredDocument(String documentType) async {
    try {
      isUploadingFiles(true);
      uploadProgress[documentType] = 0.0;

      // Determine allowed file types based on document type
      List<String> allowedExtensions = _getAllowedExtensions(documentType);
      
      List<PlatformFile>? files = await _pickFiles(
        allowMultiple: false,
        allowedExtensions: allowedExtensions,
        fileType: FileType.custom,
      );

      if (files != null && files.isNotEmpty) {
        PlatformFile file = files.first;
        
        if (!_isValidFileTypeForDocument(file, documentType)) {
          errorMessage('Invalid file type for ${_getDocumentDisplayName(documentType)}. Please select: ${allowedExtensions.join(', ')}');
          return false;
        }

        if (!uploadedDocuments.containsKey(documentType)) {
          uploadedDocuments[documentType] = [];
        }
        
        uploadedDocuments[documentType]!.add(file);
        documentValidationStatus[documentType] = true;
        uploadProgress[documentType] = 1.0;
        
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

  List<String> _getAllowedExtensions(String documentType) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    final pdfExtensions = ['pdf'];
    
    if (documentType.contains('civil_id') || documentType.contains('passport')) {
      return imageExtensions;
    }
    
    if (documentType.contains('visa') || documentType.contains('license')) {
      return [...imageExtensions, ...pdfExtensions];
    }
    
    return [...imageExtensions, ...pdfExtensions];
  }

  bool _isValidFileTypeForDocument(PlatformFile file, String documentType) {
    final allowedExtensions = _getAllowedExtensions(documentType);
    final fileExtension = file.extension?.toLowerCase();
    
    return fileExtension != null && allowedExtensions.contains(fileExtension);
  }

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
     
//      void debugSubmissionData() {
//   updateUserFromControllers();
  
//   debugPrint('=== SUBMISSION DEBUG INFO ===');
//   debugPrint('Selected Citizenship: ${selectedCitizenship.value} (${selectedCitizenship.value == 1 ? "Native" : "Foreign"})');
//   debugPrint('Selected Property Type: ${selectedPropertyType.value}');
//   debugPrint('User Model Citizenship: ${user.value.citizenship}');
//   debugPrint('User Model isNative: ${user.value.isNative}');
//   debugPrint('User Model isForeign: ${!user.value.isNative}');
  
//   if (selectedCitizenship.value == 1) {
//     debugPrint('--- Native Fields ---');
//     debugPrint('Civil ID: "${civilIdCtrl.text}"');
//     debugPrint('Civil ID Expiry: "${civilIdExpiryCtrl.text}"');
//     debugPrint('Passport (should be null): ${user.value.passportNo}');
//     debugPrint('Visa (should be null): ${user.value.visaNo}');
//   } else {
//     debugPrint('--- Foreign Fields ---');
//     debugPrint('Passport: "${passportCtrl.text}"');
//     debugPrint('Visa: "${visaCtrl.text}"');
//     debugPrint('Visa Expiry: "${visaExpiryCtrl.text}"');
//     debugPrint('Expat Civil ID: "${expatCivilIdCtrl.text}"');
//     debugPrint('Expat Civil ID Expiry: "${expatCivilIdExpiryCtrl.text}"');
//     debugPrint('Civil ID (should be null): ${user.value.civilId}');
//   }
  
//   if (selectedPropertyType.value == 'commercial') {
//     debugPrint('--- Commercial Fields ---');
//     debugPrint('CR Number: "${crNumberCtrl.text}"');
//     debugPrint('CR Expiry: "${crExpiryCtrl.text}"');
//     debugPrint('Municipality License: "${municipalityLicenseNumberCtrl.text}"');
//     debugPrint('Municipality License Date: "${municipalityLicenseDateCtrl.text}"');
//     debugPrint('Company Address: "${companyAddressCtrl.text}"');
//     debugPrint('PO Box: "${poBoxCtrl.text}"');
//   }
  
//   debugPrint('Mobile (cleaned): ${user.value.mobile}');
//   debugPrint('Required Doc Types: ${user.value.requiredDocumentTypes}');
//   debugPrint('=== END DEBUG INFO ===');
// }
   

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
      'cr_copy': 'Commercial Registration Copy',
      'municipality_license': 'Municipality License',
      'company_authorization_letter': 'Company Authorization Letter',
    };
    
    return displayNames[documentType] ?? documentType.replaceAll('_', ' ').toUpperCase();
  }

  // Enhanced form validation
 bool validateForm() {
  updateUserFromControllers();
  
  // Basic validation for all users
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

  // Mobile validation
  String cleanMobile = user.value.mobile.replaceAll(RegExp(r'[^\d]'), '');
  if (cleanMobile.length < 8) {
    errorMessage('Please enter a valid mobile number (minimum 8 digits)');
    return false;
  }

  // Update mobile with clean digits
  mobileCtrl.text = cleanMobile;
  
  // CITIZENSHIP-SPECIFIC VALIDATION
  if (isNativeCitizen) {
    // Native citizen validation
    if (civilIdCtrl.text.isEmpty || civilIdExpiryCtrl.text.isEmpty) {
      errorMessage('Please fill all required native citizen fields (Civil ID and expiry date)');
      return false;
    }
  } else {
    // Foreign citizen validation - more detailed checks
    final missingFields = <String>[];
    
    if (passportCtrl.text.isEmpty) missingFields.add('Passport Number');
    if (visaCtrl.text.isEmpty) missingFields.add('Visa Number');
    if (visaExpiryCtrl.text.isEmpty) missingFields.add('Visa Expiry Date');
    if (expatCivilIdCtrl.text.isEmpty) missingFields.add('Expat Civil ID');
    if (expatCivilIdExpiryCtrl.text.isEmpty) missingFields.add('Expat Civil ID Expiry');
    
    if (missingFields.isNotEmpty) {
      errorMessage('Missing required foreign citizen fields:\n${missingFields.join('\n')}');
      return false;
    }
  }

  // Commercial property validation
  if (isCommercialProperty) {
    final missingCommercialFields = <String>[];
    
    if (crNumberCtrl.text.isEmpty) missingCommercialFields.add('CR Number');
    if (crExpiryCtrl.text.isEmpty) missingCommercialFields.add('CR Expiry Date');
    if (municipalityLicenseNumberCtrl.text.isEmpty) missingCommercialFields.add('Municipality License Number');
    if (municipalityLicenseDateCtrl.text.isEmpty) missingCommercialFields.add('Municipality License Date');
    if (companyAddressCtrl.text.isEmpty) missingCommercialFields.add('Company Address');
    if (poBoxCtrl.text.isEmpty) missingCommercialFields.add('PO Box');
    
    if (missingCommercialFields.isNotEmpty) {
      errorMessage('Missing required commercial fields:\n${missingCommercialFields.join('\n')}');
      return false;
    }
  }

  errorMessage(null);
  return true;
}
bool validateDocumentsForSubmission() {
  try {
    final requiredTypes = getRequiredDocTypes(selectedCitizenship.value, selectedPropertyType.value);
    
    // Check if we have files for each required type
    for (var docType in requiredTypes) {
      if (!uploadedDocuments.containsKey(docType) || uploadedDocuments[docType]!.isEmpty) {
        errorMessage('Missing: ${_getDocumentDisplayName(docType)}');
        return false;
      }
      
      // Check if files actually exist
      for (var file in uploadedDocuments[docType]!) {
        if (file.path == null || !File(file.path!).existsSync()) {
          errorMessage('File not found: ${file.name}');
          return false;
        }
      }
    }
    
    errorMessage(null);
    debugPrint('✅ All ${requiredTypes.length} required documents validated');
    return true;
  } catch (e) {
    debugPrint('❌ Document validation error: $e');
    errorMessage('Document validation failed');
    return false;
  }
}

  Future<void> submitWithValidation() async {
    if (validateForm()) {
      if (validateDocumentsForSubmission()) {
        await submitUserDataAndDocs(user.value);
      }
    }
  }

Future<void> submitUserDataAndDocs(UserDataSubmissionModel userData) async {
  try {
    debugPrint('🔹 [1] Function called: submitUserDataAndDocs');
    isLoading(true);
    debugPrint('📋 USER DATA DETAILS:');
    debugPrint('   📱 Mobile: ${userData.mobile}');
    debugPrint('   🆔 Civil ID: ${userData.civilId}');
    debugPrint('   🏛️ Citizenship: ${userData.isForeign ? "Foreign" : "Native"}');
    debugPrint('   🏢 Property Type: ${userData.propertyType}');
    debugPrint('🔹 [2] isLoading set to TRUE');

    if (userData.isForeign) {
      debugPrint('🛂 FOREIGN NATIONAL DETAILS:');
      debugPrint('   🛂 Passport No: ${userData.passportNo}');
      debugPrint('   ✈️ Visa No: ${userData.visaNo}');
      debugPrint('   📅 Visa Expiry: ${userData.visaExpiryDate}');
      debugPrint('   🆔 Expat Civil ID: ${userData.expatCivilId}');
      debugPrint('   📅 Expat Civil ID Expiry: ${userData.expatCivilIdExpiry}');
    }

    errorMessage(null);
    debugPrint('🔹 [3] errorMessage reset to null');

    // Clean mobile number before submission
    debugPrint('🔹 [4] Original mobile: ${userData.mobile}');
    String cleanMobile = userData.mobile.replaceAll(RegExp(r'[^\d]'), '');
    debugPrint('🔹 [5] Cleaned mobile: $cleanMobile');

    // CRITICAL FIX: Ensure all foreign fields are properly set from controllers
    UserDataSubmissionModel cleanedUserData;
    
    if (userData.isForeign) {
      // For foreign nationals, explicitly ensure all required fields are set
      cleanedUserData = UserDataSubmissionModel.foreign(
        uid: userData.uid,
        firstName: userData.firstName,
        lastName: userData.lastName,
        address: userData.address,
        email: userData.email,
        mobile: cleanMobile,
        propertyId: userData.propertyId,
        unitId: userData.unitId,
        passportNo: passportCtrl.text.trim().isNotEmpty ? passportCtrl.text.trim() : userData.passportNo ?? '',
        visaNo: visaCtrl.text.trim().isNotEmpty ? visaCtrl.text.trim() : userData.visaNo ?? '',
        visaExpiryDate: visaExpiryCtrl.text.trim().isNotEmpty ? visaExpiryCtrl.text.trim() : userData.visaExpiryDate ?? '',
        expatCivilId: expatCivilIdCtrl.text.trim().isNotEmpty ? expatCivilIdCtrl.text.trim() : userData.expatCivilId ?? '',
        expatCivilIdExpiry: expatCivilIdExpiryCtrl.text.trim().isNotEmpty ? expatCivilIdExpiryCtrl.text.trim() : userData.expatCivilIdExpiry ?? '',
        requiredDocumentTypes: userData.requiredDocumentTypes,
        propertyType: userData.propertyType,
        requiredDocuments: userData.requiredDocuments,
        additionalDocuments: userData.additionalDocuments,
        additionalDocumentTitles: userData.additionalDocumentTitles,
        // Commercial fields if applicable
        crNumber: userData.propertyType == 'commercial' ? crNumberCtrl.text.trim() : null,
        crExpiryDate: userData.propertyType == 'commercial' ? crExpiryCtrl.text.trim() : null,
        municipalityLicenseNumber: userData.propertyType == 'commercial' ? municipalityLicenseNumberCtrl.text.trim() : null,
        municipalityLicenseDate: userData.propertyType == 'commercial' ? municipalityLicenseDateCtrl.text.trim() : null,
        companyAddress: userData.propertyType == 'commercial' ? companyAddressCtrl.text.trim() : null,
        poBox: userData.propertyType == 'commercial' ? poBoxCtrl.text.trim() : null,
      );
    } else {
      // For native citizens
      cleanedUserData = UserDataSubmissionModel.native(
        uid: userData.uid,
        firstName: userData.firstName,
        lastName: userData.lastName,
        address: userData.address,
        email: userData.email,
        mobile: cleanMobile,
        propertyId: userData.propertyId,
        unitId: userData.unitId,
        civilId: civilIdCtrl.text.trim().isNotEmpty ? civilIdCtrl.text.trim() : userData.civilId ?? '',
        civilIdExpiry: civilIdExpiryCtrl.text.trim().isNotEmpty ? civilIdExpiryCtrl.text.trim() : userData.civilIdExpiry ?? '',
        requiredDocumentTypes: userData.requiredDocumentTypes,
        propertyType: userData.propertyType,
        requiredDocuments: userData.requiredDocuments,
        additionalDocuments: userData.additionalDocuments,
        additionalDocumentTitles: userData.additionalDocumentTitles,
        // Commercial fields if applicable
        crNumber: userData.propertyType == 'commercial' ? crNumberCtrl.text.trim() : null,
        crExpiryDate: userData.propertyType == 'commercial' ? crExpiryCtrl.text.trim() : null,
        municipalityLicenseNumber: userData.propertyType == 'commercial' ? municipalityLicenseNumberCtrl.text.trim() : null,
        municipalityLicenseDate: userData.propertyType == 'commercial' ? municipalityLicenseDateCtrl.text.trim() : null,
        companyAddress: userData.propertyType == 'commercial' ? companyAddressCtrl.text.trim() : null,
        poBox: userData.propertyType == 'commercial' ? poBoxCtrl.text.trim() : null,
      );
    }
    
    debugPrint('🔹 [6] Created cleanedUserData object');

    // Validate foreign national fields before submission
    if (cleanedUserData.isForeign) {
      final missingFields = <String>[];
      if (cleanedUserData.passportNo?.isEmpty ?? true) missingFields.add('passport_no');
      if (cleanedUserData.visaNo?.isEmpty ?? true) missingFields.add('visa_no');
      if (cleanedUserData.visaExpiryDate?.isEmpty ?? true) missingFields.add('visa_expiry_date');
      if (cleanedUserData.expatCivilId?.isEmpty ?? true) missingFields.add('expat_civil_id');
      if (cleanedUserData.expatCivilIdExpiry?.isEmpty ?? true) missingFields.add('expat_civil_id_expiry');

      if (missingFields.isNotEmpty) {
        throw Exception('Missing required fields for foreign nationals: ${missingFields.join(', ')}');
      }
      
      debugPrint('✅ All foreign national fields validated');
      debugPrint('   🛂 Final Passport No: ${cleanedUserData.passportNo}');
      debugPrint('   ✈️ Final Visa No: ${cleanedUserData.visaNo}');
      debugPrint('   📅 Final Visa Expiry: ${cleanedUserData.visaExpiryDate}');
      debugPrint('   🆔 Final Expat Civil ID: ${cleanedUserData.expatCivilId}');
      debugPrint('   📅 Final Expat Civil ID Expiry: ${cleanedUserData.expatCivilIdExpiry}');
    }

    // Log user data fields for verification
    debugPrint('📤 [7] Preparing submission...');
    debugPrint('   📱 Mobile: $cleanMobile');
    debugPrint('   📄 Documents count: ${cleanedUserData.requiredDocuments?.length ?? 0}');
    debugPrint('   🏛️ Citizenship: ${cleanedUserData.isNative ? 'Native' : 'Foreign'}');
    debugPrint('   🏢 Property Type: ${cleanedUserData.propertyType}');

    // Verify all required files exist before submission
    if (cleanedUserData.requiredDocuments != null) {
      debugPrint('🔹 [8] Checking document list...');
      for (var filePath in cleanedUserData.requiredDocuments!) {
        debugPrint('   ➡ Checking file: $filePath');
        File file = File(filePath);

        if (!file.existsSync()) {
          debugPrint('💥 File not found: $filePath');
          throw Exception('File not found: $filePath');
        } else {
          debugPrint('✅ File exists: ${filePath.split('/').last}');
        }

        int fileSize = await file.length();
        debugPrint('   📏 File size: ${(fileSize / 1024).toStringAsFixed(1)} KB');

        if (fileSize > 10 * 1024 * 1024) {
          debugPrint('💥 File too large: ${filePath.split('/').last} - ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB');
          throw Exception('File too large: ${filePath.split('/').last} (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB). Maximum size is 10MB.');
        }
      }
    } else {
      debugPrint('ℹ No documents provided');
    }

    // Final validation before API call
    debugPrint('🔹 [9] Final model validation...');
    final modelJson = cleanedUserData.toJson();
    debugPrint('📦 Final model JSON: $modelJson');

    debugPrint('🔹 [10] Sending API request...');
    final response = await apiService.submitUserDetailsAndDoc(cleanedUserData);
    debugPrint('📡 [11] API Response Status: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('🔹 [12] Success HTTP code received');
      final responseData = response.data;
      debugPrint('📦 [13] Response Data: $responseData');

      if (responseData['success'] == true) {
        debugPrint('✅ [14] Submission marked as successful by server');
        _clearFormAfterSubmission();
        debugPrint('🔹 [15] Form cleared');

        Get.snackbar(
          'Success',
          'Application submitted successfully!',
          backgroundColor: AppColors.onlineGreen,
          colorText: AppColors.white,
          duration: const Duration(seconds: 3),
        );

        debugPrint('🔹 [16] Navigating to /home');
        Get.offAllNamed('/navbar', arguments: {'initialIndex': 0});
      
      } else {
        debugPrint('💥 [17] Server responded with success=false');
        throw Exception(responseData['message'] ?? 'Submission failed');
      }
    } else {
      debugPrint('💥 [18] Non-success HTTP status: ${response.statusCode}');
      final errorData = response.data;
      debugPrint('📦 Error Response Data: $errorData');

      String errorMsg = 'HTTP ${response.statusCode}';
      if (errorData is Map) {
        if (errorData.containsKey('message')) {
          errorMsg += ': ${errorData['message']}';
        }

        if (errorData.containsKey('errors')) {
          errorMsg += '\nDetails: ';
          final errors = errorData['errors'] as Map;
          errors.forEach((key, value) {
            if (value is List) {
              errorMsg += '\n• $key: ${value.join(', ')}';
            } else {
              errorMsg += '\n• $key: $value';
            }
          });
        }

        if (errorData.containsKey('debug_info')) {
          debugPrint('🐛 Debug info: ${errorData['debug_info']}');
        }
      }

      throw Exception(errorMsg);
    }
  } catch (e) {
    debugPrint('💥 [CATCH] Exception caught: $e');
    String friendlyError = e.toString();

    // Make errors more user-friendly
    if (friendlyError.contains('mobile field format is invalid')) {
      friendlyError = 'Invalid mobile number format. Please check your mobile number.';
    } else if (friendlyError.contains('required_documents') || friendlyError.contains('must be a file')) {
      friendlyError = 'Document upload failed. Please try selecting your documents again.';
    } else if (friendlyError.contains('File too large')) {
      friendlyError = friendlyError.replaceAll('Exception: ', '');
    } else if (friendlyError.contains('File not found')) {
      friendlyError = 'One or more selected files could not be found. Please select your documents again.';
    } else if (friendlyError.contains('NetworkException') || friendlyError.contains('DioException')) {
      friendlyError = 'Network error. Please check your connection and try again.';
    }

    errorMessage(friendlyError);
    debugPrint('💬 [Error Message Set] $friendlyError');

    Get.snackbar(
      'Submission Failed',
      friendlyError,
      backgroundColor: AppColors.redColor,
      colorText: AppColors.white,
      duration: const Duration(seconds: 5),
    );
  } finally {
    debugPrint('🔹 [FINALLY] Setting isLoading to FALSE');
    isLoading(false);
  }
}

  void _clearFormAfterSubmission() {
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
    crNumberCtrl.clear();
    crExpiryCtrl.clear();
    municipalityLicenseNumberCtrl.clear();
    municipalityLicenseDateCtrl.clear();
    companyAddressCtrl.clear();
    poBoxCtrl.clear();
    
    clearAllDocuments();
    
    isEditMode.value = true;
    selectedCitizenship.value = 1;
    selectedPropertyType.value = 'residential';
    errorMessage(null);
  }

  void toggleEdit() {
    isEditMode.value = !isEditMode.value;
  }

  // Helper getters for UI
  bool get isNativeCitizen => selectedCitizenship.value == 1;
  bool get isForeignCitizen => selectedCitizenship.value == 0;
  bool get isResidentialProperty => selectedPropertyType.value == 'residential';
  bool get isCommercialProperty => selectedPropertyType.value == 'commercial';
  
  String get citizenshipLabel => isNativeCitizen ? 'Native' : 'Foreign';
  String get propertyTypeLabel => isResidentialProperty ? 'Residential' : 'Commercial';
  
  List<String> get requiredDocumentLabels {
    return getRequiredDocTypes(selectedCitizenship.value, selectedPropertyType.value)
      .map((type) => _getDocumentDisplayName(type))
      .toList();
  }

  Map<String, String> get documentTypeMapping {
    Map<String, String> mapping = {};
    
    if (isNativeCitizen) {
      mapping.addAll({
        'civil_id_front': 'Civil ID Front',
        'civil_id_back': 'Civil ID Back',
      });
    } else {
      mapping.addAll({
        'passport_first_page': 'Passport First Page',
        'passport_last_page': 'Passport Last Page',
        'expat_civil_id_front': 'Expat Civil ID Front',
        'expat_civil_id_back': 'Expat Civil ID Back',
        'resident_visa': 'Resident Visa',
      });
    }
    
    if (isCommercialProperty) {
      mapping.addAll({
        'cr_copy': 'Commercial Registration Copy',
        'municipality_license': 'Municipality License',
        'company_authorization_letter': 'Company Authorization Letter',
      });
    }
    
    return mapping;
  }

  String get progressText {
    final requiredTypes = getRequiredDocTypes(selectedCitizenship.value, selectedPropertyType.value);
    if (requiredTypes.isEmpty) return '100% Complete';
    
    final percentage = (documentCompletionPercentage * 100).toStringAsFixed(1);
    return 'Documents completed: $percentage% (${uploadedDocuments.length} of ${requiredTypes.length})';
  }

  double get documentCompletionPercentage {
    final requiredTypes = getRequiredDocTypes(selectedCitizenship.value, selectedPropertyType.value);
    if (requiredTypes.isEmpty) return 1.0;
    
    int completedDocs = 0;
    for (var docType in requiredTypes) {
      if (uploadedDocuments.containsKey(docType) && uploadedDocuments[docType]!.isNotEmpty) {
        completedDocs++;
      }
    }
    
    return completedDocs / requiredTypes.length;
  }

  List<String> get missingDocuments {
    final requiredTypes = getRequiredDocTypes(selectedCitizenship.value, selectedPropertyType.value);
    final missing = <String>[];
    
    for (var docType in requiredTypes) {
      if (!uploadedDocuments.containsKey(docType) || uploadedDocuments[docType]!.isEmpty) {
        missing.add(_getDocumentDisplayName(docType));
      }
    }
    
    return missing;
  }

  bool isDocumentUploaded(String documentType) {
    return uploadedDocuments.containsKey(documentType) && 
           uploadedDocuments[documentType]!.isNotEmpty;
  }

  int getUploadedFilesCount(String documentType) {
    return uploadedDocuments[documentType]?.length ?? 0;
  }

  List<PlatformFile> getUploadedFiles(String documentType) {
    return uploadedDocuments[documentType] ?? [];
  }

  String getFileSize(PlatformFile file) {
    double sizeInMB = file.size / (1024 * 1024);
    return '${sizeInMB.toStringAsFixed(2)} MB';
  }

  void clearAllDocuments() {
    uploadedDocuments.clear();
    additionalDocuments.clear();
    additionalDocumentTitles.clear();
    documentValidationStatus.clear();
    uploadProgress.clear();
    updateUserFromControllers();
    debugPrint('🧹 Cleared all documents');
  }
}