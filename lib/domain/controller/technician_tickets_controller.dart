import 'package:dar_al_safwa/data/datasources/api_client.dart';
import 'package:dar_al_safwa/data/model/technican_list_model.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../../../data/model/technician_complaints_response.dart';
import '../../../../data/model/technican_ticket_view_model.dart';

class TechnicianTicketsController extends GetxController {
  var isLoading = false.obs;
  var tickets = <ComplaintData>[].obs; // List of complaints
  var selectedTicket = Rxn<TicketModel>(); // Single ticket details
final RxMap<String, bool> isAssigningMap = <String, bool>{}.obs;
final RxList<Map<String, dynamic>> availableTechnicians = <Map<String, dynamic>>[].obs;
final RxMap<String, String> selectedTechnicianIds = <String, String>{}.obs;

  final ApiClient apiClient = ApiClient();  

  /// Fetch available technicians (excluding current technician)
Future<void> getAvailableTechnicians() async {
  try {
    print("🔄 Starting technician fetch...");
    isLoading.value = true;
    print("🔁 isLoading set to true");

    availableTechnicians.clear();
    print("🧹 Cleared availableTechnicians list");

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    print("🧑‍💻 Current User UID (to exclude): $currentUid");

    final response = await apiClient.request(
      "technicians/except",
      method: "post",
      data: {
        "exclude_uid": currentUid,
      },
    );

    print("📡 Response received from API with status: ${response.statusCode}");
    print("📥 Raw response data: ${response.data}");

    if (response.statusCode == 200) {
      final parsedResponse = TechnicianDropdownResponse.fromJson(response.data);
      print("✅ Parsed response: ${parsedResponse.success}, Message: ${parsedResponse.displayMessage}");

      if (parsedResponse.success) {
        final techniciansList = parsedResponse.data.technicians.map((tech) => {
          'id': tech.uid,
          'name': tech.fullName,
        }).toList();

        availableTechnicians.assignAll(techniciansList);
        print("📋 Assigned ${techniciansList.length} available technicians to list");
        for (var tech in techniciansList) {
          print("🧑 Technician => ID: ${tech['id']}, Name: ${tech['name']}");
        }
      } else {
        print("❌ API responded with failure: ${parsedResponse.displayMessage}");
      }
    } else {
      print("❌ Unexpected status code: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Erroroccurred while fetching technicians: $e");
  } finally {
    isLoading.value = false;
  }
}

Future<void> assignTechnician(String complaintId, String technicianId) async {
  print("🔄 Assigning technician: $technicianId to complaint: $complaintId");
  try {
    setAssigning(complaintId, true);

    final userUid = FirebaseAuth.instance.currentUser?.uid;
    if (userUid == null) {
      print("❌ User UID is null");
      Get.snackbar('Error', 'User not logged in');
      return;
    }

    final response = await apiClient.request(
      "complaints/escalate",
      method: "post",
      data: {
        "complaint_id": complaintId,
        "technician_uid": technicianId,
        "user_uid": userUid,
      },
    );
    
    print("📡 Escalate API Status: ${response.statusCode}");
    print("📥 Escalate API Raw Body: ${response.data}");
    
    if (response.data['success'] == true) {
      Get.snackbar('✅ Success', 'Technician assigned successfully');
      selectedTechnicianIds.remove(complaintId);
      
      // Instead of fetching all tickets, just remove the assigned one
      tickets.removeWhere((ticket) => ticket.complaintId == complaintId);
    } else {
      final errorMsg = response.data['message']?['en'] ?? 'Assignment failed';
      Get.snackbar('Error', errorMsg);
    }
  } catch (e) {
    Get.snackbar('Error', 'Failed to assign technician: ${e.toString()}');
  } finally {
    setAssigning(complaintId, false);
  }
}

  /// Fetch technician complaints (tickets)
  Future<void> fetchTickets(String userId) async {
    try {
      isLoading.value = true;

      final response = await apiClient.request(
        "technician/complaints",
        method: "post",
        data: {"uid": userId},
      );
      print("🔍 Fetched complaints: ${response.data ?? 0}");
      final parsedResponse = TechnicianComplaintsResponse.fromJson(response.data);
      print("🔍 Fetched complaints: ${parsedResponse.data?.length ?? 0}");
      if (parsedResponse.status == true && parsedResponse.data != null) {
        tickets
          ..clear()
          ..addAll(parsedResponse.data!);

        print("✅ Complaints fetched: ${tickets.length}");
      } else {
        tickets.clear();
        print("⚠️ API returned empty complaints list");
      }
    } catch (e) {
      tickets.clear();
      print("❌ Error fetching complaints: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch single complaint details by complaintId
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
  void setAssigning(String complaintId, bool value) {
  isAssigningMap[complaintId] = value;
}

}