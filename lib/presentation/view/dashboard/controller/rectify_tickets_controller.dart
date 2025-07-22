import 'dart:io';
import 'package:dar_al_safwa/data/repositories/api_services.dart';
import 'package:dar_al_safwa/domain/controller/technician_tickets_controller.dart' show TechnicianTicketsController;
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/technician_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class RectifyTicketsController extends GetxController {
  final ImagePicker _imagePicker = ImagePicker();
  final ApiService _apiService = ApiService();
  final TechnicianTicketsController fetchController = Get.find<TechnicianTicketsController>();
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
 Future<void> pickFromCamera() async {
  final ImagePicker picker = ImagePicker();
  final XFile? photo = await picker.pickImage(source: ImageSource.camera);
  if (photo != null) {
    uploadedImages.add(File(photo.path));  // Correct way
    print("📸 Camera photo added: ${photo.path}");
    update(); // Only needed if using GetBuilder (not required for Obx with RxList)
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
  Future<void> submitUpdates(String complaintId) async {
  final description = workDescriptionController.text.trim();
  final amount = amountController.text.trim();

  if (description.isEmpty || amount.isEmpty) {
    Get.snackbar(
      'Error',
      'Please fill all fields',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    return;
  }

  print("=== SUBMIT UPDATE REQUEST ===");
  print("complaint_id: $complaintId");
  print("description: $description");
  print("status: ${selectedWorkStatus.value}");
  print("amount: $amount");
  print("is_paid: ${isPaid.value}");
  print("amount_changed: ${amountChanged.value}");
  print("images: ${uploadedImages.map((e) => e.path).toList()}");
  print("==============================");

  try {
    // ✅ Get the logged-in technician UID
    final String? technicianUid = FirebaseAuth.instance.currentUser?.uid;

    if (technicianUid == null) {
      Get.snackbar(
        'Error',
        'No logged-in technician found',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

     debugPrint("updatedImages: ${uploadedImages.map((e) => e.path).toList()}");

    final response = await _apiService.updateComplaint(
      uid: technicianUid,
      complaintId: complaintId, // ✅ Using dynamic complaintId
      status: getStatusCode(selectedWorkStatus.value),
      reply: description,
      amountPaid: amount,
      amountStatus: amountChanged.value,
      images: uploadedImages,
    );

    if (response['success'] == true) {
      Get.snackbar(
        'Success',
        response['message'],
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      final data = response['data'];
      print("Complaint Updated Successfully!");
      print("Complaint ID: ${data['complaint_id']}");
      print("Status: ${data['status']}");
      print("Updated Rows: ${data['updated_rows']}");

      if (data['images'] != null && data['images'] is List) {
        print("Images:");
        for (var img in data['images']) {
          print("  - $img");
        }
      }

      resetForm();
      
      await  fetchController.fetchTickets(technicianUid); // ✅ Refresh tickets list
 
      // ✅ Go back to the previous screen
      
        Get.back(
        );
   
    } else {
      Get.snackbar(
        'Error',
        response['message'] ?? 'Failed to update',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  } catch (e) {
    Get.snackbar(
      'Error',
      'Something went wrong: $e',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
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
