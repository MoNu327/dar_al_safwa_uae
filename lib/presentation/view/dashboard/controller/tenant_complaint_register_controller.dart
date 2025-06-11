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
  late var complaintRespond = Rxn<ComplaintCategoriesResponse>();
  late var subtitleComplaintRespond = Rxn<ComplaintSubCategoriesResponse>();
  late var subComplaintRespond = Rxn<ComplaintSubCategoriesResponse>();
  late RxList<ComplaintCategory> complaintCategory = <ComplaintCategory>[].obs;
  late RxList<ComplaintSubCategory> subtitleComplaintCategory =
      <ComplaintSubCategory>[].obs;
  final RxString? selectedComplaintType = RxString('');
  var selectedComplaintId = 0.obs;
  var selectedSubtitleComplaintId = 0.obs;
  final RxString? selectedSubComplaintType = RxString('');
  final TextEditingController complaintDetailsController =
      TextEditingController();
  var items = <String>[].obs;
  var selectedItem = ''.obs;
  late final String propertyName;

  @override
  void onInit() {
    propertyName = Get.arguments['propertyName'];
    debugPrint('Property Name: $propertyName');
    getComplaintList();
    super.onInit();
  }

  ///Get Complaint List
  Future<void> getComplaintList() async {
    try {
      isLoadingCompliantList(true);
      final response = await apiService.getComplaintCategories();

      debugPrint('[getCompliantList] Response data: ${response.data}');
      debugPrint('[getCompliantList] Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        // Parse the JSON response into your model class
        final parsedResponse =
            ComplaintCategoriesResponse.fromJson(response.data);
        complaintRespond.value =
            parsedResponse; // Assuming complaintRespond is an Rxn

        if (parsedResponse.data != null) {
          complaintCategory = (parsedResponse.data ?? []).obs;
        } else {
          debugPrint('No complaint categories found in the response.');
        }

        debugPrint('complaint  List: $complaintCategory');
      } else {
        debugPrint(
            '[getCompliantList] API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching complaint list: $e');
    } finally {
      isLoadingCompliantList(false);
    }
  }

  //get sub complaint list
  Future<void> getSubCompliantList() async {
    try {
      isLoadingSubtitleCompliantList(true);
      debugPrint(
          'Selected Complaint ID in subtitle fun: ${selectedComplaintId.value}');

      final response = await apiService.getSubtitleComplaintCategories(
          ComplaintSubCategoriesRequest(
              complaintId: selectedComplaintId.value));
      debugPrint('[subtitleComplaint] Response data: ${response.data}');

      debugPrint('[subtitleComplaint] Response data: ${response.data}');
      debugPrint('[subtitleComplaint] Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        // Parse the JSON response into your model class
        final parsedResponse =
            ComplaintSubCategoriesResponse.fromJson(response.data);
        subtitleComplaintRespond.value = parsedResponse;
        ; // Assuming complaintRespond is an Rxn

        if (parsedResponse.data != null) {
          subtitleComplaintCategory = (parsedResponse.data ?? []).obs;
        } else {
          debugPrint('No subtitleComplaint categories found in the response.');
        }

        debugPrint('subtitleComplaint List: $subtitleComplaintCategory');
      } else {
        debugPrint(
            '[subtitleComplaint] API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching subtitleComplaint list: $e');
    } finally {
      isLoadingSubtitleCompliantList(false);
    }
  }

  Future<void> submitCompliant() async {
    try {
      isLoadingSubmitCompliant(true);
      debugPrint(
          'Selected Complaint ID in subtitle fun: ${selectedComplaintId.value}');

      final response = await apiService.insertComplaint(
        CreateComplaintRequest(
            complaintMasterId: selectedComplaintId.value,
            complaintSubtitleId: selectedSubtitleComplaintId.value,
            description: complaintDetailsController.text,
            userId: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .id,
            propertyName: propertyName),
      );
      debugPrint('[subtitleComplaint] Response data: ${response.data}');

      debugPrint('[subtitleComplaint] Response data: ${response.data}');
      debugPrint('[subtitleComplaint] Response status: ${response.statusCode}');
      if (response.statusCode == 201) {
        CustomSnackbar.show(
          title: "Success",
          message: 'Complaint Registered Successfully',
          isDismissible: true,
          status: 2,
          durationInSeconds: 2,
          isPersistent: false,
        );
        debugPrint("statusCode ${response.statusCode}");
        debugPrint('response Submit Complaint:${response.data}');
        clearData();
      } else {
        debugPrint(
            '[subtitleComplaint] API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching subtitleComplaint list: $e');
    } finally {
      isLoadingSubmitCompliant(false);
    }
  }

  void clearData() {
    complaintDetailsController.clear();
    selectedComplaintId.value = 0;
    selectedSubtitleComplaintId.value = 0;
    selectedComplaintType?.value = '';
    selectedSubComplaintType?.value = '';
    propertyName = '';
  }
}
