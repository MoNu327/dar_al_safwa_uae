import 'package:dar_al_safwa/data/model/agent_model.dart';
import 'package:dar_al_safwa/data/model/technician_model.dart';
import 'package:get/get.dart';

class TechnicianController extends GetxController {
  TechnicianProfile? _currentUser;

  TechnicianProfile? get currentUser => _currentUser;

  set currentUser(TechnicianProfile? user) {
    _currentUser = user;
    update(); // Notify listeners
  }
}
