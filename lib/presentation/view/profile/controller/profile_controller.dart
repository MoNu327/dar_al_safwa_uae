import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:majan/data/model/agent_model.dart';
import 'package:majan/data/model/property_interest_history_model.dart';
import 'package:majan/data/model/user_model.dart';
import 'package:majan/data/repositories/api_services.dart';
import 'package:majan/domain/controller/agent_controller.dart';
import 'package:majan/domain/controller/user_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileController extends GetxController {
  Rxn<UserModel> userCredential = Rxn<UserModel>();
  Rxn<AgentModel> agentCredential = Rxn<AgentModel>();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ApiService apiService = ApiService();

  var userRole = ''.obs;
  var isLoading = true.obs;
  var isEditing = false.obs;
  var isSaving = false.obs;

  // Track current user ID to detect changes
  var currentUserId = ''.obs;

  // Property interests
  var propertyInterests = <PropertyInterestUser>[].obs;
  var isLoadingInterests = false.obs;
  var interestsError = ''.obs;

  // Reactive profile data
  var fullName = ''.obs;
  var phoneNumber = ''.obs;
  var whatsappNumber = ''.obs;
  var email = ''.obs;
  var gender = ''.obs;
  var dateOfBirth = ''.obs;
  var location = ''.obs;
  var profilePicUrl = ''.obs;

  // Agent-specific
  var agencyName = ''.obs;
  var licenseNumber = ''.obs;
  var yearsOfExperience = ''.obs;
  var workingCities = ''.obs;
  var agentStatus = ''.obs;

  // Text controllers
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final whatsappController = TextEditingController();
  final emailController = TextEditingController();
  final locationController = TextEditingController();
  final agencyNameController = TextEditingController();
  final licenseController = TextEditingController();
  final experienceController = TextEditingController();
  final citiesController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // Check if user has changed
        if (currentUserId.value != user.uid) {
          debugPrint('🔄 User changed from ${currentUserId.value} to ${user.uid}');
          currentUserId.value = user.uid;
          _clearAllData();
          fetchUserCredentials();
        }
      } else {
        _clearAllData();
      }
    });
    
    fetchUserCredentials();
  }

  @override
  void onClose() {
    fullNameController.dispose();
    phoneController.dispose();
    whatsappController.dispose();
    emailController.dispose();
    locationController.dispose();
    agencyNameController.dispose();
    licenseController.dispose();
    experienceController.dispose();
    citiesController.dispose();
    super.onClose();
  }

  /// Clear all cached data when user changes
  void _clearAllData() {
    debugPrint('🧹 Clearing all cached profile data');
    
    // Clear user/agent credentials
    userCredential.value = null;
    agentCredential.value = null;
    
    // Clear all reactive variables
    fullName.value = '';
    phoneNumber.value = '';
    whatsappNumber.value = '';
    email.value = '';
    gender.value = '';
    dateOfBirth.value = '';
    location.value = '';
    profilePicUrl.value = '';
    userRole.value = '';
    
    // Clear agent-specific data
    agencyName.value = '';
    licenseNumber.value = '';
    yearsOfExperience.value = '';
    workingCities.value = '';
    agentStatus.value = '';
    
    // Clear property interests
    propertyInterests.clear();
    interestsError.value = '';
    
    // Clear all text controllers
    _clearControllers();
    
    // Reset states
    isEditing.value = false;
    isSaving.value = false;
  }

  /// Fetch property interests history
  Future<void> fetchPropertyInterests() async {
    try {
      isLoadingInterests(true);
      interestsError('');
      
      final user = auth.currentUser;
      if (user == null) {
        interestsError('No user logged in');
        return;
      }

      final response = await apiService.getpropertyinteresthistory(user.uid);
      
      if (response.statusCode == 200 && response.data != null) {
        final propertyInterestsResponse = PropertyInterestsResponse.fromJson(response.data);
        
        if (propertyInterestsResponse.status) {
          propertyInterests.value = propertyInterestsResponse.data;
        } else {
          interestsError(propertyInterestsResponse.message.en ?? 'Failed to fetch property interests');
        }
      } else {
        interestsError('Failed to fetch property interests');
      }
    } catch (e) {
      interestsError('Error fetching property interests: $e');
      debugPrint('Error fetching property interests: $e');
    } finally {
      isLoadingInterests(false);
    }
  }

  /// Refresh property interests
  Future<void> refreshPropertyInterests() async {
    await fetchPropertyInterests();
  }

  /// Get property interest count
  int get propertyInterestCount => propertyInterests.length;

  /// Check if user has property interests
  bool get hasPropertyInterests => propertyInterests.isNotEmpty;

  /// Populate controllers without toggling edit mode (for tenant/user screens)
  void populateControllersForEdit() {
    _populateControllers();
  }

  /// Toggle editing mode
  void toggleEdit() {
    isEditing.value = !isEditing.value;
    if (isEditing.value) {
      _populateControllers();
    } else {
      // Clear controllers when exiting edit mode
      _clearControllers();
    }
  }

  /// Clear all text controllers
  void _clearControllers() {
    fullNameController.clear();
    phoneController.clear();
    whatsappController.clear();
    emailController.clear();
    locationController.clear();
    agencyNameController.clear();
    licenseController.clear();
    experienceController.clear();
    citiesController.clear();
  }

  Future<void> openWebsite(String url) async {
    if (url.isEmpty) return;

    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  /// Strip country code prefix from phone number for display
  String _stripCountryCode(String phoneNumber) {
    if (phoneNumber.startsWith('+971')) {
      return phoneNumber.substring(4); // Remove "+971"
    } else if (phoneNumber.startsWith('971')) {
      return phoneNumber.substring(3); // Remove "971"
    } else if (phoneNumber.startsWith('0') && phoneNumber.length == 10) {
      return phoneNumber.substring(1); // Remove leading "0"
    }
    return phoneNumber;
  }

  /// Populate controllers with current values
  void _populateControllers() {
    fullNameController.text = fullName.value;
    // Strip +971 prefix when populating controllers
    phoneController.text = _stripCountryCode(phoneNumber.value);
    whatsappController.text = _stripCountryCode(whatsappNumber.value);
    emailController.text = email.value;
    locationController.text = location.value;

    if (userRole.value == 'agent') {
      agencyNameController.text = agencyName.value;
      licenseController.text = licenseNumber.value;
      experienceController.text = yearsOfExperience.value;
      citiesController.text = workingCities.value;
    }
  }

  /// Phone number validation (must be exactly 9 digits for UAE)
  bool validateUAEPhone(String number) {
    final regex = RegExp(r'^[0-9]{9}$');
    return regex.hasMatch(number);
  }

  /// Save profile changes
  Future<void> saveProfile() async {
    try {
      isSaving(true);
      final user = auth.currentUser;

      if (user == null) {
        Get.snackbar('Error', 'No user logged in');
        return;
      }

      // Get the raw phone numbers from controllers (without prefix)
      String rawPhone = phoneController.text.trim();
      String rawWhatsApp = whatsappController.text.trim();

      // Strip any existing prefix before validation
      rawPhone = _stripCountryCode(rawPhone);
      rawWhatsApp = _stripCountryCode(rawWhatsApp);

      // Validate phone number (must be exactly 9 digits for UAE)
      if (!validateUAEPhone(rawPhone)) {
        Get.snackbar('Error', 'Phone number must be exactly 9 digits.');
        return;
      }

      // Validate WhatsApp if provided
      if (rawWhatsApp.isNotEmpty && !validateUAEPhone(rawWhatsApp)) {
        Get.snackbar('Error', 'WhatsApp number must be exactly 9 digits.');
        return;
      }

      // NOW add +971 prefix for storage in Firestore
      phoneNumber.value = "+971$rawPhone";
      
      // Only add WhatsApp number if provided
      if (rawWhatsApp.isNotEmpty) {
        whatsappNumber.value = "+971$rawWhatsApp";
      } else {
        whatsappNumber.value = "";
      }

      if (userRole.value == 'agent') {
        await _updateAgentProfile(user.uid);
      } else {
        await _updateUserProfile(user.uid);
      }

      // CRITICAL FIX: Set editing mode to false FIRST
      isEditing.value = false;
      
      // Refresh the profile data
      await fetchUserCredentials();

      // Show success message
      Get.snackbar('Success', 'Profile updated successfully');

      // For tenant/user, just go back instead of navigating to navbar
      if (userRole.value == 'tenant' || userRole.value == 'user') {
        // Close the edit screen and return to profile view
        Get.back();
      } else {
        // For agents using inline edit, the Obx will automatically switch to ProfileViewScreen
        // No navigation needed
      }

    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: $e');
      debugPrint('Error updating profile: $e');
    } finally {
      isSaving(false);
    }
  }

  Future<void> _updateAgentProfile(String uid) async {
    final agentData = {
      'displayName': fullNameController.text.trim(),
      'mobile': phoneNumber.value,
      'whatsAppNumber': whatsappNumber.value,
      'location': locationController.text.trim(),
      'gender': gender.value,
      'dob': dateOfBirth.value,
      'profilePic': profilePicUrl.value,
      'agencyName': agencyNameController.text.trim(),
      'licenseNumber': licenseController.text.trim(),
      'yearsOfExperience': experienceController.text.trim(),
      'workingCities': citiesController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('agents').doc(uid).update(agentData);

    fullName.value = agentData['displayName'] as String? ?? '';
    phoneNumber.value = agentData['mobile'] as String? ?? '';
    whatsappNumber.value = agentData['whatsAppNumber'] as String? ?? '';
    gender.value = agentData['gender'] as String? ?? '';
    dateOfBirth.value = agentData['dob'] as String? ?? '';
    location.value = agentData['location'] as String? ?? '';
    profilePicUrl.value = agentData['profilePic'] as String? ?? '';

    if (agentCredential.value != null) {
      agentCredential.value = AgentModel(
        uid: uid,
        email: email.value,
        name: fullName.value,
        role: agentCredential.value!.role,
        status: agentCredential.value!.status,
        dob: dateOfBirth.value,
        gender: gender.value,
        location: location.value,
      );
    }
  }

  Future<void> _updateUserProfile(String uid) async {
    final userData = {
      'displayName': fullNameController.text.trim(),
      'mobile': phoneNumber.value,
      'phoneNumber': phoneNumber.value, // Also update phoneNumber field
      'whatsAppNumber': whatsappNumber.value,
      'location': locationController.text.trim(),
      'gender': gender.value,
      'dob': dateOfBirth.value,
      'imageUrl': profilePicUrl.value,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(uid).update(userData);
    
    fullName.value = userData['displayName'] as String? ?? '';
    phoneNumber.value = userData['mobile'] as String? ?? '';
    whatsappNumber.value = userData['whatsAppNumber'] as String? ?? '';
    gender.value = userData['gender'] as String? ?? '';
    dateOfBirth.value = userData['dob'] as String? ?? '';
    location.value = userData['location'] as String? ?? '';
    profilePicUrl.value = userData['imageUrl'] as String? ?? '';

    if (userCredential.value != null) {
      userCredential.value = UserModel(
        uid: uid,
        email: userCredential.value!.email,
        name: fullName.value,
        role: userCredential.value!.role,
        location: location.value,
        status: userCredential.value!.status,
        phoneNumber: phoneNumber.value,
        imageUrl: profilePicUrl.value,
      );
    }
  }

  /// Fetch user/agent credentials
  Future<void> fetchUserCredentials() async {
    try {
      isLoading(true);
      final user = auth.currentUser;

      if (user == null) {
        _clearAllData();
        return;
      }

      debugPrint('🔄 ProfileController: Fetching credentials for: ${user.uid}');
      debugPrint('📧 Firebase Auth Email: ${user.email}');
      debugPrint('👤 Firebase Auth Display Name: ${user.displayName}');

      // Check if user changed during fetch
      if (currentUserId.value.isNotEmpty && currentUserId.value != user.uid) {
        debugPrint('⚠️ User changed during fetch, clearing data');
        _clearAllData();
        currentUserId.value = user.uid;
      }

      final agentDoc = await _firestore.collection('agents').doc(user.uid).get();

      if (agentDoc.exists) {
        userRole.value = 'agent';
        final agentData = agentDoc.data()!;
        debugPrint('✅ Agent data found: ${agentData['displayName']}');
        _populateAgentData(agentData);
        try {
          Get.find<AgentController>().currentUser = agentCredential.value;
        } catch (e) {
          debugPrint('⚠️ AgentController not found: $e');
        }
      } else {
        userRole.value = 'user';
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          debugPrint('✅ User data found: ${userData['displayName']}');
          _populateUserData(userData);
          try {
            Get.find<UserController>().currentUser = userCredential.value;
          } catch (e) {
            debugPrint('⚠️ UserController not found: $e');
          }
        } else {
          debugPrint('⚠️ No user or agent data found for: ${user.uid}');
        }
      }

      // Fetch property interests after loading user data
      await fetchPropertyInterests();
    } catch (e) {
      debugPrint('❌ Error fetching profile: $e');
      Get.snackbar('Error', 'Failed to fetch profile: $e');
    } finally {
      isLoading(false);
    }
  }

  void _populateAgentData(Map<String, dynamic> agentData) {
    fullName.value = agentData['displayName'] ?? '';
    phoneNumber.value = agentData['mobile'] ?? '';
    whatsappNumber.value = agentData['whatsAppNumber'] ?? '';
    email.value = agentData['email'] ?? '';
    gender.value = agentData['gender'] ?? '';
    dateOfBirth.value = agentData['dob'] ?? '';
    location.value = agentData['location'] ?? '';
    profilePicUrl.value = agentData['profilePic'] ?? '';

    agencyName.value = agentData['agencyName'] ?? '';
    licenseNumber.value = agentData['licenseNumber'] ?? '';
    yearsOfExperience.value = agentData['yearsOfExperience'] ?? '';
    workingCities.value = agentData['workingCities'] ?? '';
    agentStatus.value = agentData['status'] ?? 'pending';

    agentCredential.value = AgentModel(
      uid: agentData['uid'] ?? '',
      email: agentData['email'] ?? '',
      name: agentData['displayName'] ?? '',
      role: agentData['role'] ?? 'agent',
      status: agentData['status'] ?? 'pending',
      dob: dateOfBirth.value,
      gender: gender.value,
      location: location.value,
    );
    
    debugPrint('✅ Agent data populated: ${fullName.value}');
  }

  void _populateUserData(Map<String, dynamic> userData) {
    fullName.value = userData['displayName'] ?? '';
    // Handle both 'mobile' and 'phoneNumber' fields
    phoneNumber.value = userData['mobile'] ?? userData['phoneNumber'] ?? '';
    whatsappNumber.value = userData['whatsAppNumber'] ?? '';
    email.value = userData['email'] ?? '';
    gender.value = userData['gender'] ?? '';
    dateOfBirth.value = userData['dob'] ?? '';
    location.value = userData['location'] ?? '';
    profilePicUrl.value = userData['imageUrl'] ?? '';

    userCredential.value = UserModel(
      uid: userData['uid'] ?? '',
      email: userData['email'] ?? '',
      name: userData['displayName'] ?? '',
      role: userData['role'] ?? 'user',
      location: userData['location'] ?? '',
      status: userData['status'] ?? 'active',
      phoneNumber: phoneNumber.value,
      imageUrl: profilePicUrl.value,
    );
    
    debugPrint('✅ User data populated: ${fullName.value}');
  }

  /// Date picker
  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: dateOfBirth.value.isNotEmpty
          ? _parseDate(dateOfBirth.value)
          : DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      dateOfBirth.value =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
    }
  }

  DateTime _parseDate(String dateString) {
    try {
      final parts = dateString.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
    return DateTime.now().subtract(const Duration(days: 6570));
  }

  /// Pick and upload profile image
  Future<void> pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final uid = auth.currentUser?.uid;

      if (uid == null) return;

      final ref = _storage.ref().child("profile_pics/$uid.jpg");
      await ref.putFile(file);

      final downloadUrl = await ref.getDownloadURL();
      profilePicUrl.value = downloadUrl;

      final collection = userRole.value == 'agent' ? 'agents' : 'users';
      await _firestore.collection(collection).doc(uid).update({
        userRole.value == 'agent' ? 'profilePic' : 'imageUrl': downloadUrl,
      });
    } catch (e) {
      Get.snackbar("Error", "Failed to upload image: $e");
    }
  }

  // Display helpers
  String? get displayName {
    if (userRole.value == 'agent') return agentCredential.value?.name ?? '';
    return userCredential.value?.name ?? '';
  }

  String? get displayLocation {
    if (userRole.value == 'agent') return agentCredential.value?.location ?? '';
    return userCredential.value?.location ?? '';
  }

  String? get displayEmail {
    if (userRole.value == 'agent') return agentCredential.value?.email ?? '';
    return userCredential.value?.email ?? '';
  }
}