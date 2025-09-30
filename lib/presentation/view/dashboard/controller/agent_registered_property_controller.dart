import 'package:majan/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/model/agent_properties_response_model.dart';
import '../../../../data/repositories/api_services.dart';

class AgentRegisteredPropertyController extends GetxController {
  final ApiService _apiService = Get.put(ApiService());

  final agentProperties = <AgentProperty>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxString('');
  final count = 0.obs;

  final selectedCurrency = 'AED'.obs;
  final selectedStatus = 'Available'.obs;

  final List<String> currencies = [
    'OMR',
    'USD',
    'EUR',
    'GBP',
    'INR',
    'AED',
    'SAR',
    'QAR',
    'KWD',
    'BHD'
  ];

  @override
  void onInit() {
    super.onInit();
    loadAgentProperties();
  }
//  Future<void> loadFcmTokenforagent(String uid,String fcmToken) async {
//     try {
//       final response = await _apiService.getFCMtokenforagent(uid,fcmToken);

//       if (response.statusCode == 201 || response.statusCode == 200) {
//         // Handle success if needed
//         debugPrint('✅ FCM Token updated successfully');
//       } else {
//         debugPrint('❌ Failed to update FCM Token: ${response.statusMessage}');
//       }
//     } catch (e) {
//       debugPrint('❌ Error updating FCM Token: $e');
//     }
//   }
  Future<void> loadAgentProperties() async {
    try {
      isLoading(true);
      errorMessage('');

      final response = await _apiService.getAgentPropertyList();

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseModel = AgentPropertyResponse.fromJson(response.data);

        if (responseModel.success == true) {
          agentProperties.assignAll(responseModel.properties ?? []);
          count.value = responseModel.count ?? 0;
        } else {
          errorMessage(_getLocalizedMessage(responseModel.message));
        }
      } else {
        errorMessage(response.statusMessage ?? 'Failed to load properties');
      }
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  String _getLocalizedMessage(LocalizedMessage? message) {
    if (message == null) return 'Unknown error occurred';
    return Get.locale?.languageCode == 'ar'
        ? message.ar ?? message.en ?? 'Unknown error'
        : message.en ?? 'Unknown error';
  }

  void updateCurrency(String? value) {
    if (value != null) selectedCurrency.value = value;
  }

  void updateStatus(String value) {
    selectedStatus.value = value;
  }

  /// Returns the appropriate color based on property status
  Color getStatusColor(String status) {
    final statusLower = status.toLowerCase();

    if (statusLower.contains('available') || statusLower.contains('for sale')) {
      return AppColors.onlineGreen;
    } else if (statusLower.contains('sold')) {
      return AppColors.redColor;
    } else if (statusLower.contains('pending') ||
        statusLower.contains('under')) {
      return AppColors.warning;
    } else if (statusLower.contains('rent')) {
      return AppColors.blueColor;
    } else if (statusLower.contains('reserved') ||
        statusLower.contains('hold')) {
      return AppColors.secondaryColor;
    }
    return AppColors.lightGrey;
  }

  /// Returns the background color with opacity for status badges
  Color getStatusBackgroundColor(String status) {
    return getStatusColor(status).withOpacity(0.1);
  }

  /// Returns formatted status text (capitalize first letter)
  String getFormattedStatus(LocalizedText? status) {
    if (status == null) return 'N/A';

    final rawStatus = Get.locale?.languageCode == 'ar'
        ? status.ar ?? status.en ?? 'N/A'
        : status.en ?? 'N/A';

    return rawStatus
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : word)
        .join(' ');
  }

  /// Helper to get localized address based on current locale
  String getLocalizedAddress(LocalizedText? address) {
    if (address == null) return 'No address';
    return Get.locale?.languageCode == 'ar'
        ? address.ar ?? address.en ?? 'No address'
        : address.en ?? 'No address';
  }

  /// Helper to get formatted price with currency
  /// Helper to get formatted price with currency
String getFormattedPrice(AgentPropertyPrice? price) {
  if (price == null) return '${selectedCurrency.value} 0';

  final formatted = price.formatted;
  final locale = Get.locale?.languageCode;

  // First try to get the localized formatted price
  if (locale == 'ar' && formatted?.ar != null) {
    return formatted!.ar!;
  } else if (formatted?.en != null) {
    debugPrint('Formatted price in English: ${formatted!.en}');
    return formatted!.en!;
  }
  
  // If formatted prices are null, fall back to the raw value
  final rawValue = formatted?.raw ?? '0';
  debugPrint('Raw price value: $rawValue');
  return '${selectedCurrency.value} $rawValue';
}

  /// Filter properties by status
  List<AgentProperty> get filteredProperties {
    if (selectedStatus.value == 'All') return agentProperties;

    return agentProperties.where((property) {
      final status = getFormattedStatus(property.status).toLowerCase();
      return status.contains(selectedStatus.value.toLowerCase());
    }).toList();
  }

  /// Sort properties by price (ascending or descending)
  void sortPropertiesByPrice({bool ascending = true}) {
    agentProperties.sort((a, b) {
      final priceA = double.tryParse(a.price?.formatted?.raw ?? '0') ?? 0;
      final priceB = double.tryParse(b.price?.formatted?.raw ?? '0') ?? 0;
      return ascending ? priceA.compareTo(priceB) : priceB.compareTo(priceA);
    });
  }

  /// Sort properties by assigned date (newest first)
  void sortPropertiesByDate() {
    agentProperties.sort((a, b) {
      final dateA = DateTime.tryParse(a.assignedDate ?? '') ?? DateTime(1970);
      final dateB = DateTime.tryParse(b.assignedDate ?? '') ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });
  }
}
