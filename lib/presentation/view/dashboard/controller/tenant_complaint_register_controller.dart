import 'dart:io';
import 'package:dar_al_safwa/data/model/compliant_model.dart';
import 'package:dar_al_safwa/data/model/tenant_compliant_model.dart';
import 'package:dar_al_safwa/data/model/tenant_compliant_subtitle.dart';
import 'package:dar_al_safwa/data/repositories/api_services.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TenantComplaintRegisterController extends GetxController {
  final ApiService apiService = ApiService();

  // Loading states
  var isLoadingSubmitCompliant = false.obs;
  var isLoadingCompliantList = false.obs;
  var isLoadingSubtitleCompliantList = false.obs;

  // Complaint categories
  var complaintRespond = Rxn<ComplaintCategoriesResponse>();
  var subtitleComplaintRespond = Rxn<ComplaintSubCategoriesResponse>();
  RxList<ComplaintCategory> complaintCategory = <ComplaintCategory>[].obs;
  RxList<ComplaintSubCategory> subtitleComplaintCategory = <ComplaintSubCategory>[].obs;

  // Selected values
  final RxString selectedComplaintType = ''.obs;
  final RxString selectedSubComplaintType = ''.obs;
  var selectedComplaintId = 0.obs;
  var selectedSubtitleComplaintId = 0.obs;

  // Text Controller for description
  final TextEditingController complaintDetailsController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    getComplaintList(); // Fetch complaint categories initially
  }

  /// ✅ Get Complaint Categories
  Future<void> getComplaintList() async {
    try {
      isLoadingCompliantList(true);
      final response = await apiService.getComplaintCategories();

      debugPrint('[getComplaintList] Response: ${response.data}');
      if (response.statusCode == 200) {
        final parsedResponse = ComplaintCategoriesResponse.fromJson(response.data);
        complaintRespond.value = parsedResponse;
        complaintCategory.value = parsedResponse.data ?? [];

        debugPrint('✅ Complaint Categories Loaded: ${complaintCategory.length}');
      } else {
        debugPrint('[getComplaintList] Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching complaint list: $e');
    } finally {
      isLoadingCompliantList(false);
    }
  }
  

  /// ✅ Get Sub-Complaint List based on selectedComplaintId
  Future<void> getSubCompliantList() async {
    if (selectedComplaintId.value == 0) {
      debugPrint('⚠ No Complaint ID selected for fetching subcategories.');
      return;
    }

    try {
      isLoadingSubtitleCompliantList(true);
      debugPrint('Fetching sub-complaints for ID: ${selectedComplaintId.value}');

      final response = await apiService.getSubtitleComplaintCategories(
        ComplaintSubCategoriesRequest(complaintId: selectedComplaintId.value),
      );

      debugPrint('[getSubCompliantList] Response: ${response.data}');
      if (response.statusCode == 200) {
        final parsedResponse = ComplaintSubCategoriesResponse.fromJson(response.data);
        subtitleComplaintRespond.value = parsedResponse;
        subtitleComplaintCategory.value = parsedResponse.data ?? [];

        debugPrint('✅ Sub-Complaint List Loaded: ${subtitleComplaintCategory.length}');
      } else {
        debugPrint('[getSubCompliantList] Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching sub-complaint list: $e');
    } finally {
      isLoadingSubtitleCompliantList(false);
    }
  }

  /// ✅ Submit Complaint
  Future<void> submitCompliant({
    required String propertyName,
    required int propertyId,
    required int unitAddressId,
    List<File> uploadedImages = const [],
  }) async {
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

      if (selectedComplaintId.value == 0 || selectedSubtitleComplaintId.value == 0) {
        CustomSnackbar.show(
          title: "Error",
          message: "Please select both category and subcategory.",
          status: 1,
        );
        return;
      }

      if (complaintDetailsController.text.trim().isEmpty) {
        CustomSnackbar.show(
          title: "Error",
          message: "Please provide a description for the complaint.",
          status: 1,
        );
        return;
      }

      debugPrint('📤 Submitting complaint...');
      debugPrint('Complaint Master ID: ${selectedComplaintId.value}');
      debugPrint('Sub-Complaint ID: ${selectedSubtitleComplaintId.value}');
      debugPrint('Property ID: $propertyId');
      debugPrint('Unit Address ID: $unitAddressId');
      debugPrint('Property Name: $propertyName');
      debugPrint('Description: ${complaintDetailsController.text}');

      final request = CreateComplaintRequest(
        complaintMasterId: selectedComplaintId.value,
        complaintSubtitleId: selectedSubtitleComplaintId.value,
        description: complaintDetailsController.text,
        userId: userId,
        propertyName: propertyName,
        propertyId: propertyId,
        unitAddressId: unitAddressId,
        // images : uploadedImages,
      );

      final response = await apiService.insertComplaint(request, uploadedImages);

      debugPrint('[submitCompliant] Response: ${response.data}');
      final responseData =
          response.data is Map ? response.data as Map<String, dynamic> : {};

      if (responseData["status"] == true) {
        CustomSnackbar.show(
          title: "Success",
          message: responseData["message"]["en"] ??
              "Complaint Registered Successfully",
          status: 2,
        );
        clearData();
      } else {
        CustomSnackbar.show(
          title: "Error",
          message: responseData["message"]["en"] ??
              "Failed to register complaint.",
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
    selectedComplaintType.value = '';
    selectedSubComplaintType.value = '';
    subtitleComplaintCategory.clear();
    debugPrint('✅ Complaint form cleared.');
  }
}
