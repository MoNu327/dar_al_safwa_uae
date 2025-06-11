import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/screens/dashboard_screen.dart';
import 'package:dar_al_safwa/presentation/view/home/screens/home_screen.dart';
import 'package:dar_al_safwa/presentation/view/inbox/screens/inbox_screen.dart';
import 'package:dar_al_safwa/presentation/view/profile/screens/profile_screen.dart';
import 'package:dar_al_safwa/presentation/view/search/screens/search_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class BottomNavbarController extends GetxController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  var selectedIndex = 0.obs;

  final pages = [
    HomeScreen(),
    SearchScreen(),
    DashboardScreen(),
    InboxScreen(),
    const ProfileScreen(),
  ];

  void changeIndex(int index) {
    selectedIndex.value = index;
  }

  // ✅ Function to reset navigation to Home tab
  void goToHome() {
    selectedIndex.value = 0;
    Get.offAllNamed(AppRoute.navbar);
  }

  void goToNavbarIndex(int index) {
    selectedIndex.value = index;
  }
}
