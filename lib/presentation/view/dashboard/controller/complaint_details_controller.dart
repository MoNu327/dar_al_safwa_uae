import 'package:majan/data/model/complaint_details_model.dart';
import 'package:get/get.dart';
import 'package:majan/data/repositories/api_services.dart';

class ComplaintDetailsController extends GetxController {
  final ApiService _apiService = ApiService();

  /// Observables
  var isLoading = false.obs;
  var complaintDetails = Rxn<ComplaintDetailsModel>();
  var errorMessage = ''.obs;

  /// Fetch complaint details
  Future<void> fetchComplaintDetails(String complaintId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _apiService.getComplaintDetails(complaintId);

      // Parse JSON into model
      complaintDetails.value = ComplaintDetailsModel.fromJson(response);

    } catch (e) {
      errorMessage.value = 'Failed to fetch complaint details: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Helper: get technician images safely
  List<String> get technicianImages =>
      complaintDetails.value?.data.images.technicianImages ?? [];

  /// Helper: get tenant images safely
  List<String> get tenantImages =>
      complaintDetails.value?.data.images.tenantImages ?? [];
}
