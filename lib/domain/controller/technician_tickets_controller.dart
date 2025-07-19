import 'package:dar_al_safwa/data/datasources/api_client.dart';
import 'package:get/get.dart';
import '../../../../data/model/technician_complaints_response.dart';

class TechnicianTicketsController extends GetxController {
  var isLoading = false.obs;
  var tickets = <ComplaintData>[].obs; // Holds list of complaints

  /// Fetch technician complaints (tickets)
  Future<void> fetchTickets(String userId) async {
    try {
      isLoading.value = true;

      final apiClient = ApiClient();
      final response = await apiClient.request(
        "technician/complaints",
        method: "post",
        data: {"uid": userId},
        options: null,
      );

      // Parse response
      final parsedResponse = TechnicianComplaintsResponse.fromJson(response.data);

      if (parsedResponse.status == true && parsedResponse.data != null) {
        tickets
          ..clear()
          ..addAll(parsedResponse.data);

        print("✅ Complaints fetched: ${tickets.length}");
        for (var ticket in tickets) {
          print("Ticket ID: ${ticket.complaintId}, Status: ${ticket.statusText.en}");
        }
      } else {
        tickets.clear();
        print("⚠️ API Response returned status=false or data is empty");
      }
    } catch (e) {
      tickets.clear();
      print("❌ Error fetching complaints: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
