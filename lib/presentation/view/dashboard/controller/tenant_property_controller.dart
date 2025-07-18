import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:dar_al_safwa/data/model/tenatpropertymodel.dart';
import 'package:dar_al_safwa/data/repositories/api_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TenantPropertyController extends GetxController {
  final ApiService apiService = ApiService();

  var properties = <TenantPropertyModel>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTenantProperties();
  }

  Future<void> fetchTenantProperties() async {
  isLoading.value = true;
  errorMessage.value = '';

  try {
    String uid = "8JnK2Se9sBaHJFrPi6brY0ajme53"; // Replace with dynamic user UID

    final response = await apiService.getMyProperties(uid);

    // ✅ Print the full raw response
    debugPrint('API Response: ${response.data}');

    if (response.statusCode == 200 && response.data['success'] == true) {
      // ✅ Print success message and extracted data list
      debugPrint('Success: ${response.data['message']}');
      debugPrint('Data List: ${response.data['data']}');

      List<dynamic> dataList = response.data['data'];

      properties.value =
          dataList.map((e) {
            debugPrint('Parsing property: $e'); // ✅ Print each property
            return TenantPropertyModel.fromJson(e);
          }).toList();

      debugPrint('Total Properties Loaded: ${properties.length}');
    } else {
      errorMessage.value =
          response.data['message']['en'] ?? 'Failed to load properties';
      debugPrint('API Error: ${errorMessage.value}');
    }
  } catch (e) {
    errorMessage.value = 'Error: $e';
    debugPrint('Exception: $e');
  } finally {
    isLoading.value = false;
    debugPrint('Loading finished. Properties count: ${properties.length}');
  }
}


  void navigateToComplaintReg(String propertyName) {
    Get.toNamed(AppRoute.tenantComplaintReg,
        arguments: {"propertyName": propertyName});
  }
}
