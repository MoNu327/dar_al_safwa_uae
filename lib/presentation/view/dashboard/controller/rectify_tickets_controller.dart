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
  var ispaidStatus =false.obs;
   final paymentTitleController = TextEditingController();
  final paidByController = TextEditingController();
  var selectedPaymentMethod = 1.obs; // Default to card (1)
  final paymentStatus = 0.obs; 
  /// Controllers
  final workDescriptionController = TextEditingController();
  final amountController = TextEditingController(text: '');
 

   final paymentMethods = [
    {'value': '1', 'label': 'Card'},
    {'value': '2', 'label': 'Cash'},
    {'value': '3', 'label': 'Others'},
  ];


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

  
  // New methods for payment handling
  void setPaymentStatus(int status) {
    paymentStatus.value = status;
    // Update isPaid based on status for backward compatibility
    isPaid.value = status != 0;
  }
  
  void setPaymentMethod(int method) {
    selectedPaymentMethod.value = method;
  }
  /// Submit Logic
 Future<void> submitUpdates(String complaintId) async {
  final description = workDescriptionController.text.trim();
  final amount = amountController.text.trim();
  // final paymentTitle = paymentTitleController.text.trim();
  // final paidBy = paidByController.text.trim();

  print("=== SUBMIT UPDATE REQUEST ===");
  print("complaint_id: $complaintId");
  print("description: $description");
  print("status: ${selectedWorkStatus.value}");
  print("amount: $amount");
  print("payment_status: ${paymentStatus.value}");
  print("payment_method: ${selectedPaymentMethod.value}");
  // print("payment_title: $paymentTitle");
  // print("paid_by: $paidBy");
  print("images: ${uploadedImages.map((e) => e.path).toList()}");

  try {
    final String? technicianUid = FirebaseAuth.instance.currentUser?.uid;
    if (technicianUid == null) {
      Get.snackbar('Error', 'No logged-in technician found',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // Prepare payments array according to validation rules
    final payments = amount.isNotEmpty ? [{
      'amount_paid': amount,
      'amount_status': paymentStatus.value.toString(), // 0, 1, or 2
      // 'payment_title': paymentTitle,
      // 'paid_by': paidBy,
      'payment_method': paymentStatus.value != 0 
          ? selectedPaymentMethod.value.toString()
          : null, // Only send if payment made
      'payment_date': paymentStatus.value != 0
          ? DateTime.now().toIso8601String()
          : null, // Only send if payment made
    }] : [];

    final response = await _apiService.updateComplaint(
      uid: technicianUid,
      complaintId: complaintId,
      status: getStatusCode(selectedWorkStatus.value),
      reply: description,
      payments: payments.whereType<Map<String, dynamic>>().toList(),
      images: uploadedImages,
    );

    if (response['success'] == true) {
  Get.snackbar('Success', response['message'],
      backgroundColor: Colors.green, colorText: Colors.white);
  resetForm();
  await fetchController.fetchTickets(technicianUid); // Wait for this to complete
  print("Navigating back");
  Get.back(); // Only call once
  print("After navigation");
}
 else {
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
Future<void> refreshData() async {
  try {
    await fetchController.fetchTickets(FirebaseAuth.instance.currentUser?.uid ?? '');
  } catch (e) {
    debugPrint("Error refreshing tickets: $e");
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
    amountController.dispose();
    paymentTitleController.dispose();
    paidByController.dispose();
    super.onClose();
  }
}
