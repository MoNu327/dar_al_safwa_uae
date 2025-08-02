import 'package:dar_al_safwa/data/model/agent_model.dart';
import 'package:dar_al_safwa/data/model/user_model.dart';
import 'package:dar_al_safwa/domain/controller/agent_controller.dart';
import 'package:dar_al_safwa/domain/controller/user_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileController extends GetxController {
  Rxn<UserModel> userCredential = Rxn<UserModel>();
  Rxn<AgentModel> agentCredential = Rxn<AgentModel>();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var userRole = ''.obs;
  var isLoading = true.obs;
  var isEditing = false.obs;
  var isSaving = false.obs;

  // Reactive variables for profile data
  var fullName = ''.obs;
  var phoneNumber = ''.obs;
  var whatsappNumber = ''.obs;
  var email = ''.obs;
  var gender = ''.obs;
  var dateOfBirth = ''.obs;
  var location = ''.obs;
  var profilePicUrl = ''.obs;

  // Agent-specific fields
  var agencyName = ''.obs;
  var licenseNumber = ''.obs;
  var yearsOfExperience = ''.obs;
  var workingCities = ''.obs;
  var agentStatus = ''.obs;

  // Text editing controllers for form fields
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController agencyNameController = TextEditingController();
  final TextEditingController licenseController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController citiesController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchUserCredentials();
  }

  @override
  void onClose() {
    // Dispose controllers
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

  void toggleEdit() {
    isEditing.value = !isEditing.value;
    if (isEditing.value) {
      _populateControllers();
    }
  }

  void _populateControllers() {
    fullNameController.text = fullName.value;
    phoneController.text = phoneNumber.value;
    whatsappController.text = whatsappNumber.value;
    emailController.text = email.value;
    locationController.text = location.value;

    if (userRole.value == 'agent') {
      agencyNameController.text = agencyName.value;
      licenseController.text = licenseNumber.value;
      experienceController.text = yearsOfExperience.value;
      citiesController.text = workingCities.value;
    }
  }

  Future<void> saveProfile() async {
    try {
      isSaving(true);
      final user = auth.currentUser;

      if (user == null) {
        Get.snackbar('Error', 'No user logged in');
        return;
      }

      if (userRole.value == 'agent') {
        await _updateAgentProfile(user.uid);
      } else {
        await _updateUserProfile(user.uid);
      }

      isEditing.value = false;
      Get.snackbar('Success', 'Profile updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: ${e.toString()}');
      debugPrint('Error updating profile: $e');
    } finally {
      isSaving(false);
    }
  }

  Future<void> _updateAgentProfile(String uid) async {
    final agentData = {
      'displayName': fullNameController.text.trim(),
      'mobile': phoneController.text.trim(),
      'whatsAppNumber': whatsappController.text.trim(),
      'location': locationController.text.trim(),
      'gender': gender.value,
      'dob': dateOfBirth.value,
      // 'agencyName': agencyNameController.text.trim(),
      // 'licenseNumber': licenseController.text.trim(),
      // 'yearsOfExperience': experienceController.text.trim(),
      // 'workingCities': citiesController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('agents').doc(uid).update(agentData);

    // Update local reactive variables
    fullName.value = fullNameController.text.trim();
    phoneNumber.value = phoneController.text.trim();
    whatsappNumber.value = whatsappController.text.trim();
    location.value = locationController.text.trim();
    // agencyName.value = agencyNameController.text.trim();
    // licenseNumber.value = licenseController.text.trim();
    // yearsOfExperience.value = experienceController.text.trim();
    workingCities.value = citiesController.text.trim();

    // Update the agent model
    if (agentCredential.value != null) {
      agentCredential.value = AgentModel(
        uid: agentCredential.value!.uid,
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
      'mobile': phoneController.text.trim(),
      'whatsAppNumber': whatsappController.text.trim(),
      'location': locationController.text.trim(),
      'gender': gender.value,
      'dob': dateOfBirth.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(uid).update(userData);

    // Update local reactive variables
    fullName.value = fullNameController.text.trim();
    phoneNumber.value = phoneController.text.trim();
    whatsappNumber.value = whatsappController.text.trim();
    location.value = locationController.text.trim();

    // Update the user model
    if (userCredential.value != null) {
      userCredential.value = UserModel(
        uid: userCredential.value!.uid,
        email: userCredential.value!.email,
        name: fullName.value,
        role: userCredential.value!.role,
        location: location.value,
        status: userCredential.value!.status,
      );
    }
  }

  Future<void> fetchUserCredentials() async {
    try {
      isLoading(true);
      final user = auth.currentUser;

      debugPrint('Current Firebase User: ${user?.uid}');

      if (user == null) {
        return;
      }

      // Check if user is agent first
      final agentDoc =
          await _firestore.collection('agents').doc(user.uid).get();

      if (agentDoc.exists) {
        // User is an agent
        userRole.value = 'agent';
        final agentData = agentDoc.data()!;

        agentCredential.value = AgentModel(
          dob: agentData['dob'] ?? '',
          gender: agentData['gender'] ?? '',
          location: agentData['location'] ?? '',
          uid: agentData['uid'] ?? user.uid,
          email: agentData['email'] ?? user.email ?? '',
          name: agentData['displayName'] ?? '',
          role: agentData['role'] ?? 'agent',
          status: agentData['status'] ?? 'pending',
        );

        // Populate reactive variables with agent data
        _populateAgentData(agentData);
        Get.find<AgentController>().currentUser = agentCredential.value;

        debugPrint('User Role: agent');
        debugPrint('Agent Name: ${agentCredential.value?.name}');
      } else {
        // User is a regular user
        userRole.value = 'user';
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          userCredential.value = UserModel(
            uid: userData['uid'] ?? user.uid,
            email: userData['email'] ?? user.email ?? '',
            name: userData['displayName'] ?? user.displayName ?? '',
            role: userData['role'] ?? 'user',
            location: userData['location'] ?? '',
            status: userData['status'] ?? 'active',
            imageUrl: userData['photoUrl'] ?? '',
          );

          // Populate reactive variables with user data
          _populateUserData(userData);
          Get.find<UserController>().currentUser = userCredential.value;

          debugPrint('User Role: user');
          debugPrint('User Name: ${userCredential.value?.name}');
        } else {
          debugPrint('No user document found in Firestore');
        }
      }
    } catch (e) {
      Get.snackbar(
          'Error', 'Failed to fetch user credentials: ${e.toString()}');
      debugPrint('Error fetching user credentials: $e');
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

    // Agent-specific fields
    agencyName.value = agentData['agencyName'] ?? '';
    licenseNumber.value = agentData['licenseNumber'] ?? '';
    yearsOfExperience.value = agentData['yearsOfExperience'] ?? '';
    workingCities.value = agentData['workingCities'] ?? '';
    agentStatus.value = agentData['status'] ?? 'pending';
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
  }

  // Date picker function
  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: dateOfBirth.value.isNotEmpty
          ? _parseDate(dateOfBirth.value)
          : DateTime.now().subtract(Duration(days: 6570)),
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
          int.parse(parts[2]), // year
          int.parse(parts[1]), // month
          int.parse(parts[0]), // day
        );
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    return DateTime.now().subtract(Duration(days: 6570));
  }

  // Getters for backward compatibility
  String? get displayName {
    if (userRole.value == 'user' || userRole.value == 'tenant') {
      return userCredential.value?.name ?? fullName.value;
    } else if (userRole.value == 'agent') {
      return agentCredential.value?.name ?? fullName.value;
    } else {
      return "Guest";
    }
  }

  String? get displayLocation {
    if (userRole.value == 'user' || userRole.value == 'tenant') {
      return userCredential.value?.location ?? location.value;
    } else if (userRole.value == 'agent') {
      return agentCredential.value?.location ?? location.value;
    } else {
      return "Not Available";
    }
  }

  String? get displayEmail {
    if (userRole.value == 'user' || userRole.value == 'tenant') {
      return userCredential.value?.email ?? email.value;
    } else if (userRole.value == 'agent') {
      return agentCredential.value?.email ?? email.value;
    }
    return email.value.isNotEmpty ? email.value : null;
  }
}
