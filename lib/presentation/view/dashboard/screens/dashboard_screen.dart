
import 'package:majan/presentation/view/dashboard/widgets/agent_dashboard.dart';
import 'package:majan/presentation/view/dashboard/widgets/no_property_purchase%20.dart';
import 'package:majan/presentation/view/dashboard/widgets/tenant_dashboard.dart';
import 'package:majan/presentation/view_model/firebase_auth_controller.dart';
import 'package:majan/presentation/widgets/signup_warning_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


import '../../../controllers/network_controller.dart';
import '../../../widgets/no_internet_widegt.dart';
import '../../search/screens/search_screen.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final AuthService authService = Get.find<AuthService>();
  final NetworkController networkController = Get.find<NetworkController>();
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          showExitConfirmation();
        }
      },
      child: Obx(() {
        if (authService.userRole.value == 'agent') {
          return !networkController.isConnected.value
              ? NoInternetWidegt()
              : AgentDashboard();
        } else if (authService.userRole.value == 'tenant') {
          return !networkController.isConnected.value
              ? NoInternetWidegt()
              : TenantDashboard();
        } else if (authService.userRole.value == 'user') {
          return !networkController.isConnected.value
              ? NoInternetWidegt()
              : NoPropertyPurchaseScreen();
        } else {
          return !networkController.isConnected.value
              ? NoInternetWidegt()
              : SignupWarningScreen();
        }
      }),
    );
  }
}
