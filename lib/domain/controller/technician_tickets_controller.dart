import 'package:dar_al_safwa/data/datasources/api_client.dart';
import 'package:get/get.dart';
import '../../../../data/model/technican_viewticket_model.dart';

class TechnicianTicketsController extends GetxController {
  var isLoading = false.obs;
  var tickets = <ViewTicketData>[].obs;

  /// Fetch technician tickets using API
  Future<void> fetchTickets(String userId) async {
    try {
      isLoading.value = true;

      final apiClient = ApiClient();
      final response = await apiClient.request(
        "technician/complaints",
        method: "post",
        data: {"uid": userId}, options: null, // ✅ Dynamic UID
      );

      final parsedResponse = ViewTicketResponse.fromJson(response.data);

      // ✅ Clear old tickets and add new ones
      tickets.clear();
      tickets.addAll(parsedResponse.data);

      print("✅ Tickets fetched: ${tickets.length}");
      for (var ticket in tickets) {
        print("Ticket ID: ${ticket.complaintId}, Status: ${ticket.statusText}");
      }
    } catch (e) {
      print("❌ Error fetching tickets: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
