import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/model/compliant_model.dart';
import '../../../../data/model/tenant_compliant_model.dart';
import '../../../../data/model/tenant_compliant_subtitle.dart';
import '../../../../data/repositories/api_services.dart';
import '../../../widgets/custom_snackbar.dart';

class TenantComplaintRegisterController extends GetxController {
  final ApiService apiService = ApiService();

  var isLoadingSubmitCompliant = false.obs;
  var isLoadingCompliantList = false.obs;
  var isLoadingSubtitleCompliantList = false.obs;

  // Complaint categories
  late var complaintRespond = Rxn<ComplaintCategoriesResponse>();
  late var subtitleComplaintRespond = Rxn<ComplaintSubCategoriesResponse>();
  late RxList<ComplaintCategory> complaintCategory = <ComplaintCategory>[].obs;
  late RxList<ComplaintSubCategory> subtitleComplaintCategory =
      <ComplaintSubCategory>[].obs;

  // Selected values
  final RxString? selectedComplaintType = RxString('');
  final RxString? selectedSubComplaintType = RxString('');
  var selectedComplaintId = 0.obs;
  var selectedSubtitleComplaintId = 0.obs;

  // Input Controller
  final TextEditingController complaintDetailsController =
      TextEditingController();

  @override
  void onInit() {
    super.onInit();
    getComplaintList();
  }

  /// ✅ Get Complaint List
  Future<void> getComplaintList() async {
    try {
      isLoadingCompliantList(true);
      final response = await apiService.getComplaintCategories();

      debugPrint('[getComplaintList] Response: ${response.data}');
      if (response.statusCode == 200) {
        final parsedResponse =
            ComplaintCategoriesResponse.fromJson(response.data);
        complaintRespond.value = parsedResponse;

        complaintCategory.value = parsedResponse.data ?? [];
        debugPrint('✅ Complaint List Loaded: ${complaintCategory.length}');
      } else {
        debugPrint(
            '[getComplaintList] Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching complaint list: $e');
    } finally {
      isLoadingCompliantList(false);
    }
  }

  /// ✅ Get Sub-Complaint List
  Future<void> getSubCompliantList() async {
    try {
      isLoadingSubtitleCompliantList(true);
      debugPrint('Fetching sub-complaints for ID: ${selectedComplaintId.value}');

      final response = await apiService.getSubtitleComplaintCategories(
        ComplaintSubCategoriesRequest(complaintId: selectedComplaintId.value),
      );

      debugPrint('[getSubCompliantList] Response: ${response.data}');
      if (response.statusCode == 200) {
        final parsedResponse =
            ComplaintSubCategoriesResponse.fromJson(response.data);
        subtitleComplaintRespond.value = parsedResponse;

        subtitleComplaintCategory.value = parsedResponse.data ?? [];
        debugPrint(
            '✅ Sub-Complaint List Loaded: ${subtitleComplaintCategory.length}');
      } else {
        debugPrint(
            '[getSubCompliantList] Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching sub-complaint list: $e');
    } finally {
      isLoadingSubtitleCompliantList(false);
    }
  }

  /// ✅ Submit Complaint
  Future<void> submitCompliant(String propertyName) async {
    try {
      isLoadingSubmitCompliant(true);

      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        CustomSnackbar.show(
          title: "Error",
          message: "User not logged in!",
          status: 1,
        );
        return;
      }

      debugPrint('📤 Submitting complaint...');
      debugPrint('Complaint Master ID: ${selectedComplaintId.value}');
      debugPrint('Sub-Complaint ID: ${selectedSubtitleComplaintId.value}');
      debugPrint('Property Name: $propertyName');
      debugPrint('Description: ${complaintDetailsController.text}');

      final response = await apiService.insertComplaint(
        CreateComplaintRequest(
          complaintMasterId: selectedComplaintId.value,
          complaintSubtitleId: selectedSubtitleComplaintId.value,
          description: complaintDetailsController.text,
          userId: userId,
          propertyName: propertyName,
        ),
      );

      debugPrint('[submitCompliant] Response: ${response.data}');
      if (response.statusCode == 201) {
        CustomSnackbar.show(
          title: "Success",
          message: 'Complaint Registered Successfully',
          status: 2,
        );
        clearData();
      } else {
        debugPrint(
            '[submitCompliant] Failed with status: ${response.statusCode}');
        CustomSnackbar.show(
          title: "Error",
          message: "Failed to register complaint. Try again.",
          status: 1,
        );
      }
    } catch (e) {
      debugPrint('❌ Error submitting complaint: $e');
      CustomSnackbar.show(
        title: "Error",
        message: "Something went wrong. Please try again.",
        status: 1,
      );
    } finally {
      isLoadingSubmitCompliant(false);
    }
  }

  /// ✅ Clear all data after submission
  void clearData() {
    complaintDetailsController.clear();
    selectedComplaintId.value = 0;
    selectedSubtitleComplaintId.value = 0;
    selectedComplaintType?.value = '';
    selectedSubComplaintType?.value = '';
    debugPrint('✅ Complaint form cleared.');
  }
}
