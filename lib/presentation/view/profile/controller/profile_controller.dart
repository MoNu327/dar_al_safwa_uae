// import 'package:dar_al_safwa/data/model/agent_model.dart';
// import 'package:dar_al_safwa/domain/controller/agent_controller.dart';
// import 'package:dar_al_safwa/domain/controller/user_controller.dart';
// import 'package:get/get.dart';
// import '../../../../data/model/user_model.dart';
// import '../../../view_model/firebase_auth_controller.dart';

// class ProfileController extends GetxController {
//   late Rxn<UserModel> userCredential;
//   late Rxn<AgentModel> agentCredential;
//   var userRole = ''.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     // Initialize userCredential
//     userRole = Get.find<AuthService>().userRole;
//     if (userRole.value == 'user') {
//       userCredential = Rxn<UserModel>(Get.find<UserController>().currentUser);
//     } else if (userRole.value == 'agent') {
//       agentCredential =
//           Rxn<AgentModel>(Get.find<AgentController>().currentUser);
//     }
//   }
// }

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
  var userRole = ''.obs;
  var isLoading = true.obs;
  var isEditing = false.obs;

  var fullName = 'John Cartel'.obs;

  var phoneNumber = '+91 9876543210'.obs;
  var whatsappNumber = '+91 9876543210'.obs;
  var agencyName = 'Kerala Real Estate'.obs;
  var licenseNumber = 'KRL12345'.obs;
  var yearsOfExperience = '5Y'.obs;
  var workingCities = 'Kochi, Trivandrum'.obs;
  var gender = 'Male'.obs;
  var dateOfBirth = '01/01/1990'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserCredentials();
  }

  void toggleEdit() {
    isEditing.value = !isEditing.value;
  }

  void saveProfile() {
    isEditing.value = false;
    Get.snackbar('Success', 'Profile updated successfully');
  }

  Future<void> fetchUserCredentials() async {
    try {
      isLoading(true);
      // final auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      debugPrint('Current Firebase User: ${user?.uid}');

      if (user == null) {
        return;
      }

      // Check if user is agent first
      final agentDoc = await FirebaseFirestore.instance
          .collection('agents')
          .doc(user.uid)
          .get();

      if (agentDoc.exists) {
        // User is an agent
        userRole.value = 'agent';
        final agentData = agentDoc.data();
        agentCredential.value = AgentModel(
          uid: agentData?['uid'] ?? user.uid,
          email: agentData?['email'] ?? user.email,
          name: agentData?['displayName'] ?? '',
          role: agentData?['role'] ?? 'agent',
          status: agentData?['status'] ?? 'pending',
        );
        Get.find<AgentController>().currentUser = agentCredential.value;

        debugPrint('User Role: agent');
        debugPrint('Agent Name: ${agentCredential.value?.name}');
        debugPrint('Agent Email: ${agentCredential.value?.email}');
      } else {
        // User is a regular user
        userRole.value = 'user';
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          userCredential.value = UserModel(
            uid: userData?['uid'] ?? user.uid,
            email: userData?['email'] ?? user.email,
            name: userData?['displayName'] ?? user.displayName ?? '',
            role: userData?['role'] ?? 'user',
            status: userData?['status'] ?? 'active',
          );
          Get.find<UserController>().currentUser = userCredential.value;

          debugPrint('User Role: user');
          debugPrint('User Name: ${userCredential.value?.name}');
          debugPrint('User Email: ${userCredential.value?.email}');
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

  String? get displayName {
    if (userRole.value == 'user' || userRole.value == 'tenant') {
      return userCredential.value?.name;
    } else if (userRole.value == 'agent') {
      return agentCredential.value?.name;
    } else {
      return "Guest";
    }
  }

  String? get email {
    if (userRole.value == 'user' || userRole.value == 'tenant') {
      return userCredential.value?.email;
    } else if (userRole.value == 'agent') {
      return agentCredential.value?.email;
    }
    return null;
  }
}
