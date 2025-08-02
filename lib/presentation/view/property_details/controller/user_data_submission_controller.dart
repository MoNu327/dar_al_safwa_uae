import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../../data/model/user_data_submission_model.dart';
import '../../../../data/repositories/api_services.dart';

class UserDataSubmissionController extends GetxController {
  RxBool isEditMode = true.obs;

  Rx<UserDataSubmissionModel> user = UserDataSubmissionModel(
      propertyId: '',
      unitId: '',
      uid: '',
      firstName: '',
      lastName: '',
      address: '',
      nationality: '',
      email: '',
      mobile: '',
      passportNo: '',
      visaNo: '',
      fields: []).obs;

  final ApiService apiService = ApiService();
  final isLoading = false.obs;

  final errorMessage = Rx<String?>(null);

  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final nationalityCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final passportCtrl = TextEditingController();
  final visaCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (args != null && args is Map<String, dynamic>) {
      user.value = UserDataSubmissionModel(
        propertyId: '',
        unitId: '',
        uid: uid,
        firstName: args['firstName'] ?? '',
        lastName: args['lastName'] ?? '',
        address: args['address'] ?? '',
        nationality: args['nationality'] ?? '',
        email: args['email'] ?? '',
        mobile: args['mobileNo'] ?? '',
        passportNo: args['passportNo'] ?? '',
        visaNo: args['visa'] ?? '',
        fields: [],
      );

      firstNameCtrl.text = user.value.firstName;
      lastNameCtrl.text = user.value.lastName;
      addressCtrl.text = user.value.address;
      nationalityCtrl.text = user.value.nationality;
      emailCtrl.text = user.value.email;
      mobileCtrl.text = user.value.mobile;
      passportCtrl.text = user.value.passportNo;
      visaCtrl.text = user.value.visaNo;

      debugPrint(
          '✅ User model initialized from arguments: ${user.value.toJson()}');
    } else {
      debugPrint('⚠️ No valid arguments passed to DocumentUploadScreen.');
    }
  }

  @override
  void onClose() {
    // 🔥 Dispose all controllers to avoid memory leaks
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    addressCtrl.dispose();
    nationalityCtrl.dispose();
    emailCtrl.dispose();
    mobileCtrl.dispose();
    passportCtrl.dispose();
    visaCtrl.dispose();
    super.onClose();
  }

  Future<void> submitUserDataAndDocs(UserDataSubmissionModel userData) async {
    try {
      isLoading(true);
      errorMessage(null);

      debugPrint(
          'Posting userData: ${userData.firstName}, ${userData.lastName}');
      final response = await apiService.submitUserDetailsAndDoc(userData);
      debugPrint(
          '🎉 API response: ${response.statusCode}, ${response.statusMessage}, ${response}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final submitResponse = response.data;
        debugPrint("🔔 Submission response: ${submitResponse["data"]}");
      } else {
        debugPrint('😔 Failed to post user details: ${response.statusMessage}');
        throw Exception("Failed to post user details and doc");
      }
    } catch (e) {
      debugPrint('😔 Error in Post User Details: $e');
      errorMessage(e.toString());
    } finally {
      isLoading(false);
      debugPrint('Post details completed');
    }
  }

  void toggleEdit() {
    isEditMode.value = !isEditMode.value;
  }
}
