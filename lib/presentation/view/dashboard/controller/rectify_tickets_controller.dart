import 'dart:io';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/technician_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class RectifyTicketsController extends GetxController {
  final ImagePicker _imagePicker = ImagePicker();

  /// Observables
  var uploadedImages = <File>[].obs;
  var selectedWorkStatus = 'Pending'.obs;
  var amountChanged = false.obs;
  var isPaid = false.obs;

  /// Controllers
  final workDescriptionController = TextEditingController();
  final amountController = TextEditingController(text: ''); // ✅ Default amount set

  @override
  void onInit() {
    super.onInit();
    workDescriptionController.text = ''; // Empty description
    amountController.text = ''; // ✅ Default amount
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
  void toggleAmountChanged(bool value) {
    amountChanged.value = value;
  }

  void togglePaidStatus(bool value) {
    isPaid.value = value;
  }

  /// Submit Logic
  void submitUpdates() {
    final description = workDescriptionController.text.trim();
    final amount = amountController.text.trim();

    if (description.isEmpty || amount.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // ✅ Log values or send API request
    print("Work Description: $description");
    print("Amount Charged: $amount");
    print("Paid Status: ${isPaid.value}");
    print("Amount Changed: ${amountChanged.value}");
    print("Uploaded Images: ${uploadedImages.length}");

    // ✅ Show Success Message
    Get.snackbar('Success', 'Updates submitted successfully',
        backgroundColor: Colors.green, colorText: Colors.white);

    // ✅ Reset form after submission
    resetForm();

    // ✅ Navigate to Technician Dashboard after submission
    Future.delayed(const Duration(seconds: 1), () {
      Get.offAll(() => TechnicianDashboard()); 
      // ✅ Make sure TechnicianDashboard() is your actual widget
    });
  }

  /// Reset Form
  void resetForm() {
    workDescriptionController.clear();
    amountController.text = ''; // ✅ Reset amount to default
    selectedWorkStatus.value = 'Pending'; // Reset status
    amountChanged.value = false; // Reset amount changed
    isPaid.value = false; // Reset Paid status
    uploadedImages.clear(); // Clear uploaded images
  }

  @override
  void onClose() {
    workDescriptionController.dispose();
    amountController.dispose();
    super.onClose();
  }
}
