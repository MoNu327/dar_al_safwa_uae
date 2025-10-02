import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:majan/data/model/agent_model.dart';
import 'package:majan/data/model/user_model.dart';
import 'package:majan/domain/controller/agent_controller.dart';
import 'package:majan/domain/controller/user_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  Rxn<UserModel> userCredential = Rxn<UserModel>();
  Rxn<AgentModel> agentCredential = Rxn<AgentModel>();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  var userRole = ''.obs;
  var isLoading = true.obs;
  var isEditing = false.obs;
  var isSaving = false.obs;

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

  /// Toggle editing mode
  void toggleEdit() {
    isEditing.value = !isEditing.value;
    if (isEditing.value) {
      _populateControllers();
    }
  }

  /// Populate controllers with current values
  void _populateControllers() {
    fullNameController.text = fullName.value;
    phoneController.text = phoneNumber.value.replaceAll("+971", "");
    whatsappController.text = whatsappNumber.value.replaceAll("+971", "");
    emailController.text = email.value;
    locationController.text = location.value;

    if (userRole.value == 'agent') {
      agencyNameController.text = agencyName.value;
      licenseController.text = licenseNumber.value;
      experienceController.text = yearsOfExperience.value;
      citiesController.text = workingCities.value;
    }
  }

  /// Phone number validation (must be exactly 8 digits)
  bool validateUAEPhone(String number) {
    final regex = RegExp(r'^[0-9]{8}$');
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

    // Validate Oman phone numbers
    if (!validateUAEPhone(phoneController.text.trim())) {
      Get.snackbar('Error', 'Phone number must be exactly 10 digits.');
      return;
    }
    // if (!validateOmanPhone(whatsappController.text.trim())) {
    //   Get.snackbar('Error', 'WhatsApp number must be exactly 8 digits.');
    //   return;
    // }

    // Always prepend +971
    phoneNumber.value = "+971${phoneController.text.trim()}";
    whatsappNumber.value = "+971${whatsappController.text.trim()}";

    if (userRole.value == 'agent') {
      await _updateAgentProfile(user.uid);
    } else {
      await _updateUserProfile(user.uid);
    }

    // ✅ Clear all text fields after successful save
    fullNameController.clear();
    emailController.clear();
    phoneController.clear();
    locationController.clear();
    // If you have WhatsApp controller
    // whatsappController.clear();

    isEditing.value = false;
    Get.snackbar('Success', 'Profile updated successfully');
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
email.value = agentData['email'] as String? ?? '';
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
      'whatsAppNumber': whatsappNumber.value,
      'location': locationController.text.trim(),
      'gender': gender.value,
      'dob': dateOfBirth.value,
      'imageUrl': profilePicUrl.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(uid).update(userData);
fullName.value = userData['displayName'] as String? ?? '';
phoneNumber.value = userData['mobile'] as String? ?? '';
whatsappNumber.value = userData['whatsAppNumber'] as String? ?? '';
email.value = userData['email'] as String? ?? '';
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
        imageUrl: profilePicUrl.value,
      );
    }
  }

  /// Fetch user/agent credentials
  Future<void> fetchUserCredentials() async {
    try {
      isLoading(true);
      final user = auth.currentUser;

      if (user == null) return;

      final agentDoc = await _firestore.collection('agents').doc(user.uid).get();

      if (agentDoc.exists) {
        userRole.value = 'agent';
        final agentData = agentDoc.data()!;
        _populateAgentData(agentData);
        Get.find<AgentController>().currentUser = agentCredential.value;
      } else {
        userRole.value = 'user';
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          _populateUserData(userData);
          Get.find<UserController>().currentUser = userCredential.value;
        }
      }
    } catch (e) {
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
  }

  void _populateUserData(Map<String, dynamic> userData) {
    fullName.value = userData['displayName'] ?? '';
    phoneNumber.value = userData['mobile'] ?? '';
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
      imageUrl: profilePicUrl.value,
    );
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

      // update Firestore immediately
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
