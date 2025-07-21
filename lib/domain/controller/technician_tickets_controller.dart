import 'package:dar_al_safwa/data/datasources/api_client.dart';
import 'package:get/get.dart';
import '../../../../data/model/technician_complaints_response.dart';
import '../../../../data/model/technican_ticket_view_model.dart';

class TechnicianTicketsController extends GetxController {
  var isLoading = false.obs;
  var tickets = <ComplaintData>[].obs; // List of complaints
  var selectedTicket = Rxn<TicketModel>(); // Single ticket details

  final ApiClient apiClient = ApiClient();

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
        "technician/complaint-details",
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
