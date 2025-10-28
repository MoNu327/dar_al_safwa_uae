import 'package:majan/data/model/agent_chat_response.dart';
import 'package:get/get.dart';

import '../../../../data/repositories/api_services.dart';

class PropertyInterestController extends GetxController {
  // PropertyInterestController({});

  // State variables
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<AgentChatResponse?> chatData = Rx<AgentChatResponse?>(null);
  final ApiService _apiService = ApiService();

  /// Fetch agent chat reports and update states accordingly
  Future<void> fetchAgentChats(String uid) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _apiService.fetchingAgentChatReports(uid);

      if (response.statusCode == 200) {
        final data = AgentChatResponse.fromJson(response.data);
        chatData.value = data;
      } else {
        errorMessage.value =
            'Unexpected error: ${response.statusCode} ${response.statusMessage}';
      }
    } catch (e) {
      errorMessage.value = 'Failed to fetch chats: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
