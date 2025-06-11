import 'package:get/get.dart';

import '../../data/model/user_model.dart';

class UserController extends GetxController {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  set currentUser(UserModel? user) {
    _currentUser = user;
    update(); // Notify listeners
  }
}
