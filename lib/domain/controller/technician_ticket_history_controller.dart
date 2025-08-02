import 'package:dar_al_safwa/data/datasources/api_client.dart';
import 'package:dar_al_safwa/data/model/history_ticket_model.dart';
import 'package:dar_al_safwa/data/model/technican_ticket_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TechnicianTicketHistoryController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<TicketHistoryModel> tickets = <TicketHistoryModel>[].obs; // List of complaints
  var selectedTicket = Rxn<TicketModel>(); 

  final ApiClient apiClient = ApiClient(); // Assumes you have an ApiClient class

  @override
  void onInit() {
    super.onInit();
    fetchTechnicianResolvedTickets();
  }

  Future<void> fetchTechnicianResolvedTickets() async {
  isLoading.value = true;
  errorMessage.value = '';
  
  try {
    // 1. Get the current Firebase user
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      errorMessage.value = 'User not logged in';
      isLoading.value = false;
      return;
    }

    // 2. Make the API request with the Firebase UID
    final response = await apiClient.request(
      "technician-resolved-complaints",
      method: "post",
      data: {
        'uid': user.uid, // Firebase UID
      },
    );

    print("🔁 Response status: ${response.statusCode}");
    print("📦 Response data: ${response.data}");

    if (response.statusCode == 200) {
      if (response.data is Map && response.data['status'] == true) {
        final List data = response.data['data'] ?? [];
        
        print("📋 Parsed data: $data");

        final result = data.map((e) {
          print("🎯 Parsing item: $e");
          return TicketHistoryModel.fromJson(e);
        }).toList();

        tickets.assignAll(result);
      } else {
        errorMessage.value = response.data['message']['en'] ?? 'Invalid response format';
      }
    } else {
      errorMessage.value = response.data['message']['en'] ?? 'Server error occurred';
    }
  } catch (e) {
    errorMessage.value = 'Something went wrong. Please try again.';
    debugPrint('❌ Error fetching technician tickets: $e');
  } finally {
    isLoading.value = false;
  }
}
 Future<void> fetchComplaintDetails(String complaintId) async {
    try {
      isLoading.value = true;

      final response = await apiClient.request(
        "technician/complaints",
        method: "get", // Or "post" if API requires it
        data: {
          "complaint_id": complaintId,
        },
      );

      if (response.data['success'] == true) {
        selectedTicket.value = TicketModel.fromJson(response.data['data']);
        print("✅ Ticket details fetched: ${selectedTicket.value?.complaintNumber}");
      } else {
        print("⚠️ Failed to load ticket details: ${response.data['message']['en']}");
      }
    } catch (e) {
      print("❌ Error fetching complaint details: $e");
    } finally {
      isLoading.value = false;
    }
  }

}
