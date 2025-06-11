import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:get/get.dart';

class TenantPropertyController extends GetxController {
  final tenantProperties = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadTenantProperties();
  }

  void loadTenantProperties() {
    final properties = [
      {
        'id': 1,
        'imageUrl': 'assets/images/apartment1.jpg',
        'propertyName': 'Villa in Al Mouj',
        'status': 'Rent',
        'location': 'Al Mouj, Muscat',
        'area': '2,500 sq.ft',
        'purchasedDate': '2022-05-15',
        'agreementExpiry': '2025-12-31',
        'purchasedAmount': '350,000 KWD',
        'securityAmount': '5,000 KWD',
        'agentName': 'Al Safwa Real Estate',
      },
      {
        'id': 2,
        'imageUrl': 'assets/images/apartment2.jpg',
        'propertyName': 'Apartment in Qurm',
        'status': 'Owned',
        'location': 'Qurm, Muscat',
        'area': '1,800 sq.ft',
        'purchasedDate': '2020-11-20',
        'agreementExpiry': 'N/A',
        'purchasedAmount': '280,000 KWD',
        'securityAmount': 'N/A',
        'agentName': 'Gulf Properties',
      },
    ];

    tenantProperties.assignAll(properties);
  }

  // navigate to register complaint screen
  void navigateToComplaintReg(String propertyName) {
    Get.toNamed(AppRoute.tenantComplaintReg,
        arguments: {"propertyName": propertyName});
  }
}
