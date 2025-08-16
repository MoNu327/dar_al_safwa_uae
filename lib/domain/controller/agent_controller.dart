import 'package:majan/data/model/agent_model.dart';
import 'package:get/get.dart';

class AgentController extends GetxController {
  AgentModel? _currentUser;

  AgentModel? get currentUser => _currentUser;

  set currentUser(AgentModel? user) {
    _currentUser = user;
    update(); // Notify listeners
  }
}
