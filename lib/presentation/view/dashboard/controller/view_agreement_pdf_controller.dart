import 'package:get/get.dart';
import 'package:majan/data/model/agreement_response_model.dart';
import 'package:majan/data/repositories/api_services.dart';

class ViewAgreementController extends GetxController {
  var isLoading = false.obs;
  var agreementList = <AgreementData>[].obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  final ApiService apiService = ApiService();

  Future<void> fetchAgreement(String uid, String unitAddressId) async {
    try {
      isLoading(true);
      hasError(false);
      errorMessage('');

      print("🔍 Fetching agreement for UID: $uid, Unit Address ID: $unitAddressId");

      final response = await apiService.getPropertyAgreement(uid, unitAddressId);

      print("✅ API Response Status: ${response.statusCode}");
      print("✅ API Response Data: ${response.data}");

      final agreementResponse = AgreementResponse.fromJson(response.data);

      agreementList.assignAll(agreementResponse.data);
      
      if (agreementList.isNotEmpty) {
        print("✅ PDF URL: ${agreementList.first.pdf_url}");
      }
    } catch (e) {
      hasError(true);
      errorMessage(e.toString());
      
      print("❌ Error fetching agreement: $e");
      
      // Try to get more specific error info
      if (e.toString().contains('400')) {
        errorMessage('Bad request - Invalid parameters');
      } else {
        errorMessage('Failed to load agreement');
      }
    } finally {
      isLoading(false);
    }
  }
}