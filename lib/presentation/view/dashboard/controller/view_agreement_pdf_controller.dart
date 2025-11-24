import 'package:get/get.dart';
import 'package:majan/data/model/agreement_response_model.dart';
import 'package:majan/data/repositories/api_services.dart';


class ViewAgreementController extends GetxController {
  var isLoading = false.obs;
  var agreementList = <AgreementData>[].obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  final ApiService apiService = ApiService();

  Future<void> fetchAgreement(String uid) async {
    try {
      isLoading(true);
      hasError(false);

      final response = await apiService.getPropertyAgreement(uid);

      final agreementResponse = AgreementResponse.fromJson(response.data);

      agreementList.assignAll(agreementResponse.data);
    } catch (e) {
      hasError(true);
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }
}
