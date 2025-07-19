import 'dart:io';
import 'package:dar_al_safwa/data/repositories/api_services.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/technician_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class RectifyTicketsController extends GetxController {
  final ImagePicker _imagePicker = ImagePicker();
  final ApiService _apiService = ApiService();

  /// Observables
  var uploadedImages = <File>[].obs;
  var selectedWorkStatus = 'Pending'.obs;
  var amountChanged = false.obs;
  var isPaid = false.obs;

  /// Controllers
  final workDescriptionController = TextEditingController();
  final amountController = TextEditingController(text: '');

  @override
  void onInit() {
    super.onInit();
    workDescriptionController.text = '';
    amountController.text = '';
  }

  /// Image Picker
  Future<void> pickImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage();
    if (images.isNotEmpty && uploadedImages.length + images.length <= 10) {
      uploadedImages.addAll(images.map((xFile) => File(xFile.path)));
    } else if (uploadedImages.length + images.length > 10) {
      Get.snackbar('Limit Reached', 'You can upload up to 10 images only.',
          backgroundColor: Colors.orange, colorText: Colors.white);
    }
  }

  /// Work Status
  void changeWorkStatus(String status) {
    selectedWorkStatus.value = status;
  }

  /// Toggle switches
  void toggleAmountChanged(bool value) => amountChanged.value = value;
  void togglePaidStatus(bool value) => isPaid.value = value;

  /// Submit Logic
  Future<void> submitUpdates() async {
    final description = workDescriptionController.text.trim();
    final amount = amountController.text.trim();

    if (description.isEmpty || amount.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    print("=== SUBMIT UPDATE REQUEST ===");
    print("complaint_id: 64");
    print("description: $description");
    print("status: ${selectedWorkStatus.value}");
    print("amount: $amount");
    print("is_paid: ${isPaid.value}");
    print("amount_changed: ${amountChanged.value}");
    print("images: ${uploadedImages.map((e) => e.path).toList()}");
    print("==============================");

    try {
      final response = await _apiService.updateComplaint(
        uid: "TECH_UID", // Replace with the logged-in technician UID
        complaintId: "64",
        status: getStatusCode(selectedWorkStatus.value),
        reply: description,
        amountPaid: amount,
        amountStatus: amountChanged.value,
        images: uploadedImages,
      );
if (response['success'] == true) {
  Get.snackbar('Success', response['message'],
      backgroundColor: Colors.green, colorText: Colors.white);

  final data = response['data'];
  print("Complaint Updated Successfully!");
  print("Complaint ID: ${data['complaint_id']}");
  print("Status: ${data['status']}");
  print("Updated Rows: ${data['updated_rows']}");
  print("Images:");
  if (data['images'] != null && data['images'] is List) {
    for (var img in data['images']) {
      print("  - $img");
    }
  }

  resetForm();

  // ✅ Go back to the previous screen instead of navigating to TechnicianDashboard
  Future.delayed(const Duration(seconds: 1), () {
    Get.back();
  });

} else {
  Get.snackbar('Error', response['message'] ?? 'Failed to update',
      backgroundColor: Colors.red, colorText: Colors.white);
}

    } catch (e) {
      Get.snackbar('Error', 'Something went wrong: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// Convert Status to Code
  String getStatusCode(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return "0";
      case 'in progress':
        return "1";
      case 'completed':
        return "2";
      case 'cancelled':
        return "3";
      default:
        return "0";
    }
  }

  /// Reset Form
  void resetForm() {
    workDescriptionController.clear();
    amountController.text = '';
    selectedWorkStatus.value = 'Pending';
    amountChanged.value = false;
    isPaid.value = false;
    uploadedImages.clear();
  }

  @override
  void onClose() {
    workDescriptionController.dispose();
    amountController.dispose();
    super.onClose();
  }
}
