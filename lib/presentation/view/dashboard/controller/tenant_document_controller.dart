import 'package:majan/data/model/tenant_document_model.dart';
import 'package:majan/data/repositories/api_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TenantDocumentController extends GetxController {
  final ApiService _apiService = ApiService();

  /// Observables
  var isLoading = false.obs;
  var tenantDocumentResponse = Rxn<TenantDocumentResponse>();
  var errorMessage = ''.obs;

  /// Fetch tenant documents
  Future<void> fetchTenantDocuments(String uid) async {
    try {
      isLoading(true);
      errorMessage('');

      final response = await _apiService.getTenantDocuments(uid);
      debugPrint('Response: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        tenantDocumentResponse.value =
            TenantDocumentResponse.fromJson(response.data);
      } else {
        errorMessage.value = "Failed to fetch tenant documents.";
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading(false);
    }
  }
}
