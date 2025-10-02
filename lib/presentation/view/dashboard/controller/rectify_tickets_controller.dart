import 'dart:io';
import 'package:majan/data/repositories/api_services.dart';
import 'package:majan/domain/controller/technician_tickets_controller.dart' show TechnicianTicketsController;
import 'package:majan/presentation/view/dashboard/widgets/technician_dashboard.dart';
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
  var selectedWorkStatus = ''.obs; // Start with empty to detect when data is loaded
  var amountChanged = false.obs;
  var isPaid = false.obs;
  var ispaidStatus = false.obs;
  var isLoading = false.obs; // Add loading state
  var ticketLoaded = false.obs; // Track if ticket data has been loaded
  
  // Work status options - Updated to show "Started working" instead of "Pending"
  var workStatusOptions = <String>['Started working', 'In Progress', 'Completed'].obs;
  
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

  /// Load existing ticket data when entering the form
  Future<void> loadTicketData(String complaintId) async {
    try {
      isLoading.value = true;
      ticketLoaded.value = false;

       workDescriptionController.clear();
      
      // Get the current ticket data from fetchController
      final currentTicket = fetchController.tickets.firstWhereOrNull(
        (ticket) => ticket.complaintId == complaintId,
      );
      
      if (currentTicket != null) {
        // Set the current status from the ticket
        selectedWorkStatus.value = getStatusText(currentTicket.status);
        
        // Load other existing data if available
        if (currentTicket.replyByTechnician != null && currentTicket.replyByTechnician!.isNotEmpty) {
          workDescriptionController.text = currentTicket.replyByTechnician!;
        }
        
        // Load payment information if exists - amountPaid is a String, not a List
        if (currentTicket.amountPaid != null && currentTicket.amountPaid!.isNotEmpty) {
          // Since amountPaid is a String, use it directly
          amountController.text = currentTicket.amountPaid!;
          
          // Set payment status based on whether amount exists
          if (currentTicket.amountPaid!.isNotEmpty) {
            paymentStatus.value = 2; // Assume fully paid if amount exists
            selectedPaymentMethod.value = 1; // Default to card
            amountChanged.value = true;
          }
        }
        
        // If you have a separate payment status field in your ticket model, use it
        // Example: if (currentTicket.paymentStatus != null) {
        //   paymentStatus.value = int.tryParse(currentTicket.paymentStatus!) ?? 0;
        // }
        
        print("Loaded ticket data:");
        print("Status: ${selectedWorkStatus.value}");
        print("Description: ${workDescriptionController.text}");
        print("Amount: ${amountController.text}");
        print("Payment Status: ${paymentStatus.value}");
        
      } else {
        // If ticket not found, set default values - Updated to "Started working"
        selectedWorkStatus.value = 'Started working';
        print("Ticket not found, setting default status: Started working");
      }
      
      ticketLoaded.value = true;
    } catch (e) {
      print('Error loading ticket data: $e');
      // Set default values if loading fails - Updated to "Started working"
      selectedWorkStatus.value = 'Started working';
      ticketLoaded.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Convert status code to text - Updated to return "Started working" for status "0"
  String getStatusText(String statusCode) {
    switch (statusCode) {
      case "0":
        return "Started working";
      case "1":
        return "In Progress";
      case "2":
        return "Completed";
      case "3":
        return "Cancelled";
      default:
        return "Started working";
    }
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
      uploadedImages.add(File(photo.path));
      print("📸 Camera photo added: ${photo.path}");
      update();
    }
  }

  /// Work Status - Updated to handle status changes properly
  void changeWorkStatus(String status) {
    selectedWorkStatus.value = status;
    print("Status changed to: $status");
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

  /// Submit Logic - Updated with better validation
  // Add this to your controller class
  var isSubmitting = false.obs;

  Future<void> forceNavigateBack() async {
    print("=== FORCE NAVIGATION DEBUG ===");
    print("Current route: ${Get.currentRoute}");
    print("Route stack length: ${Get.routing.current}");
    print("Is dialog open: ${Get.isDialogOpen}");
    print("Is bottom sheet open: ${Get.isBottomSheetOpen}");
    print("Is snackbar open: ${Get.isSnackbarOpen}");
    
    // Close all possible overlays
    Get.closeAllSnackbars();
    
    if (Get.isDialogOpen == true) {
      print("Closing dialog...");
      Get.back();
      await Future.delayed(Duration(milliseconds: 50));
    }
    
    if (Get.isBottomSheetOpen == true) {
      print("Closing bottom sheet...");
      Get.back();
      await Future.delayed(Duration(milliseconds: 50));
    }
    
    // Wait a bit more
    await Future.delayed(Duration(milliseconds: 200));
    
    // Try different navigation methods in sequence
    bool navigationSuccessful = false;
    
    // Method 1: GetX back
    if (!navigationSuccessful) {
      try {
        print("Trying Get.back()...");
        Get.back();
        navigationSuccessful = true;
        print("Get.back() successful");
      } catch (e) {
        print("Get.back() failed: $e");
      }
    }
    
    // Method 2: Navigator pop with context
    if (!navigationSuccessful && Get.context != null) {
      try {
        print("Trying Navigator.pop with context...");
        Navigator.of(Get.context!).pop();
        navigationSuccessful = true;
        print("Navigator.pop() successful");
      } catch (e) {
        print("Navigator.pop() failed: $e");
      }
    }
    
    // Method 3: Get.until to first route
    if (!navigationSuccessful) {
      try {
        print("Trying Get.until...");
        Get.until((route) => route.settings.name == '/dashboard' || route.isFirst);
        navigationSuccessful = true;
        print("Get.until() successful");
      } catch (e) {
        print("Get.until() failed: $e");
      }
    }
    
    // Method 4: Nuclear option
    if (!navigationSuccessful) {
      print("All navigation methods failed, using nuclear option");
      Get.offAllNamed('/dashboard'); // Or your main route
    }
  }

Future submitUpdates(String complaintId) async {
  if (isSubmitting.value) return;
  
  isSubmitting.value = true;
  
  try {
    final description = workDescriptionController.text.trim();
    final amount = amountController.text.trim();
    
    if (selectedWorkStatus.value.isEmpty) {
      Get.snackbar('Error', 'Please select a work status',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    final String? technicianUid = FirebaseAuth.instance.currentUser?.uid;
    if (technicianUid == null) {
      Get.snackbar('Error', 'No logged-in technician found',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    final payments = amount.isNotEmpty ? [{
      'amount_paid': amount,
      'amount_status': paymentStatus.value.toString(),
      'payment_method': paymentStatus.value != 0
          ? selectedPaymentMethod.value.toString()
          : null,
      'payment_date': paymentStatus.value != 0
          ? DateTime.now().toIso8601String()
          : null,
    }] : [];
    
    print("About to call API...");
    print("Uploaded images count: ${uploadedImages.length}");
    print("Technician UID: $technicianUid");
    
    // Make API call
    final dynamic apiResponse = await _apiService.updateComplaint(
      uid: technicianUid,
      complaintId: complaintId,
      status: getStatusCode(selectedWorkStatus.value),
      reply: description,
      payments: payments.whereType<Map<String, dynamic>>().toList(),
      images: uploadedImages,
    );
    
    // Process response
    Map<String, dynamic> response;
    if (apiResponse is Map<String, dynamic>) {
      response = apiResponse;
    } else if (apiResponse is Map) {
      response = Map<String, dynamic>.from(apiResponse);
    } else {
      throw Exception("Invalid API response format");
    }
    
    // Check for success
    bool isSuccess = false;
    final successField = response['success'];
    
    if (successField is bool) {
      isSuccess = successField;
    } else if (successField is String) {
      isSuccess = successField.toLowerCase() == 'true';
    } else if (successField is int) {
      isSuccess = successField == 1;
    } else if (response.containsKey('status')) {
      final status = response['status'];
      isSuccess = status == 'success' || status == 200 || status == '200';
    }
    
   if (isSuccess) {
  print("✅ Update successful, now fetching complete ticket details...");
  
  // Fetch complete ticket details
  await fetchController.fetchComplaintDetails(complaintId);
  
  // Also refresh the tickets list
  await fetchController.fetchTickets(technicianUid);
  
  // ADD THIS: Get the refreshed complaint
  final refreshedComplaint = fetchController.tickets.firstWhereOrNull(
    (t) => t.complaintId == complaintId,
  );
  
  print("✅ Found refreshed complaint: ${refreshedComplaint != null}");
  if (refreshedComplaint != null) {
    print("  - Payment: ${refreshedComplaint.amountPaid}");
    print("  - Images: ${refreshedComplaint.complaintImages.technicianUploaded.length}");
  }
  
  // CHANGE THIS: Include the refreshed complaint in result
  Get.back(result: {
    'updated': true,
    'complaintId': complaintId,
    'updatedComplaint': refreshedComplaint, // ADD THIS LINE
    'message': response['message']?.toString() ?? 'Updated successfully',
  });
      
      print("✅ Navigation with refreshed data complete");
      
    } else {
      print("API call was not successful");
      print("Response: $response");
      Get.snackbar('Error', response['message']?.toString() ?? 'Failed to update',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
    
  } catch (e, stackTrace) {
    print("Submit error: $e");
    print("Stack trace: $stackTrace");
    Get.snackbar('Error', 'Something went wrong: $e',
        backgroundColor: Colors.red, colorText: Colors.white);
  } finally {
    print("Setting isSubmitting to false");
    isSubmitting.value = false;
  }
}
  /// Convert Status to Code - Updated to handle "Started working" 
  String getStatusCode(String status) {
    switch (status.toLowerCase()) {
      case 'started working':
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

  /// Reset Form - Updated to preserve status when needed
  void resetForm({bool preserveStatus = true}) {  // Changed default to true
  workDescriptionController.clear();
  amountController.text = '';
  if (!preserveStatus) {
    selectedWorkStatus.value = 'Started working';
  }
  amountChanged.value = false;
  isPaid.value = false;
  paymentStatus.value = 0;
  selectedPaymentMethod.value = 1;
  paymentTitleController.clear();
  paidByController.clear();
  uploadedImages.clear();
  ticketLoaded.value = false;
}

  /// Clear form when controller is disposed or new ticket is loaded
  void clearFormForNewTicket() {
    resetForm(preserveStatus: false);
  }

  @override
  void onClose() {
    workDescriptionController.dispose();
    amountController.dispose();
    paymentTitleController.dispose();
    paidByController.dispose();
    super.onClose();
  }
}