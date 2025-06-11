import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:dar_al_safwa/core/utils/data_utlis.dart';
import 'package:dar_al_safwa/data/model/search_property_model.dart';
import 'package:dar_al_safwa/data/repositories/api_services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/model/search_property_model.dart' as search_results;

class PropertyListingController extends GetxController {
  final ApiService apiService = ApiService();

  late int propertyOption;
  late int propertyType;
  late int propertyLocation;
  late int propertyBedsBath;

  // filter names
  String? propertyOptionName;
  String? propertyTypeName;
  String? propertyLocationName;
  String? propertyBedsBathName;

  // Fetch Property Search Results
  final Rxn<SearchPropertyResponse> searchResults =
      Rxn<SearchPropertyResponse>();
  final RxString searchResultErrorMessage = ''.obs;
  final RxBool isLoadingSearchResults = false.obs;

  @override
  void onInit() {
    super.onInit();
    final params = Get.arguments as Map<String, dynamic>;
    propertyOption = params['property_option'];
    propertyType = params['property_type'];
    propertyLocation = params['property_location'];
    propertyBedsBath = params['property_beds_bath'];

    // Store the names from the parameters
    propertyOptionName = params['property_option_name'];
    propertyTypeName = params['property_type_name'];
    propertyLocationName = params['property_location_name'];
    propertyBedsBathName = params['property_beds_bath_name'];

    fetchSearchResult();
  }

  // Future<void> fetchSearchResult() async {
  //   try {
  //     isLoadingSearchResults(true);
  //     debugPrint('🔄 [fetchSearchResult] Initiating property search...');
  //     searchResultErrorMessage('');

  //     final request = PropertySearchResultRequest(
  //       propertyOptions: propertyOption,
  //       propertyTypes: propertyType,
  //       propertyLocations: propertyLocation,
  //       propertyBedsBath: propertyBedsBath,
  //     );

  //     // Print request payload
  //     debugPrint('📤 [fetchSearchResult] Request Payload:');
  //     debugPrint(request.toJson().toString());

  //     final response = await apiService.getPropertySearchResult(request);

  //     // Print response
  //     debugPrint(response.toString());
  //     debugPrint('✅ API call completed. Status: ${response.statusCode}');

  //     if (response.statusCode == 200) {
  //       debugPrint('📦 [fetchSearchResult] Parsing response data...');
  //       debugPrint('📄 Response Data: ${response.data}');

  //       searchResults.value =
  //           search_results.SearchPropertyResponse.fromJson(response.data);

  //       // Print parsed results
  //       debugPrint('📊 [fetchSearchResult] Parsed Search Results:');
  //       debugPrint('Success: ${searchResults.value?.success}');
  //       debugPrint('Message (en): ${searchResults.value?.message?.english}');
  //       debugPrint('Message (ar): ${searchResults.value?.message?.arabic}');
  //       debugPrint(
  //           'Properties found: ${searchResults.value?.data?.length ?? 0}');

  //       debugPrint(
  //           '📊 [fetchSearchResult] Received Search Results: ${(searchResults.value)?.toJson()}');

  //       if (searchResults.value?.data != null ||
  //           searchResults.value!.data!.isEmpty) {
  //         for (var property in searchResults.value!.data!) {
  //           debugPrint('🏠 Property ID: ${property.id}');
  //           debugPrint('   Title (en): ${property.propertyTitle?.english}');
  //           debugPrint('   Title (ar): ${property.propertyTitle?.arabic}');
  //           debugPrint('   Price: ${property.propertyPrice?.raw}');
  //           debugPrint('   Type (en): ${property.propertyType?.english}');
  //           debugPrint(
  //               '   Location (en): ${property.propertyLocation?.english}');
  //         }

  //         searchResultErrorMessage(Get.locale?.languageCode == 'ar'
  //             ? 'لا توجد عقارات تطابق معايير البحث'
  //             : 'No properties found matching your criteria');
  //         searchResults.value = null;
  //         return;
  //       }
  //     } else {
  //       debugPrint('📄 Search response: ${response.data}');

  //       final errorMessage = response.data['message'] != null
  //           ? Get.locale?.languageCode == 'ar'
  //               ? response.data['message']['ar'] ?? 'حدث خطأ غير متوقع'
  //               : response.data['message']['en'] ??
  //                   'An unexpected error occurred'
  //           : 'Error status: ${response.statusCode}';

  //       searchResultErrorMessage(errorMessage);
  //       searchResults.value = null;

  //       debugPrint(
  //           '❌ [fetchSearchResult] API error: Status ${response.statusCode}');
  //       debugPrint('📄 Response body: ${response.data}');
  //       throw DioException(
  //         requestOptions: response.requestOptions,
  //         response: response,
  //         error: 'Failed to load banners: ${response.statusCode}',
  //       );
  //     }
  //   } on DioException catch (e) {
  //     debugPrint('🚨 [fetchSearchResult] DioException caught: ${e.type}');
  //     debugPrint('📌 Error details: ${e.message}');
  //     if (e.response != null) {
  //       debugPrint('⚡ Response status: ${e.response?.statusCode}');
  //       debugPrint('📄 Response data: ${e.response?.data}');
  //     }
  //     // searchResultErrorMessage(parseDioError(e));
  //     if (e.type == DioExceptionType.connectionTimeout) {
  //       searchResultErrorMessage(Get.locale?.languageCode == 'ar'
  //           ? 'انتهت مهلة الاتصال بالخادم'
  //           : 'Connection timeout');
  //     } else if (e.response != null) {
  //       debugPrint('⚡ Response status: ${e.response?.statusCode}');
  //       debugPrint('📄 Response data: ${e.response?.data}');

  //       final errorMessage = e.response?.data['message'] != null
  //           ? Get.locale?.languageCode == 'ar'
  //               ? e.response!.data['message']['ar'] ?? 'حدث خطأ غير متوقع'
  //               : e.response!.data['message']['en'] ??
  //                   'An unexpected error occurred'
  //           : 'Error status: ${e.response?.statusCode}';

  //       searchResultErrorMessage(errorMessage);
  //     } else {
  //       searchResultErrorMessage(Get.locale?.languageCode == 'ar'
  //           ? 'حدث خطأ في الاتصال بالخادم'
  //           : 'Server connection error');
  //     }
  //     searchResults.value = null;
  //     rethrow;
  //   } catch (e, stackTrace) {
  //     debugPrint('‼️ [fetchSearchResult] Unexpected error: ${e.toString()}');
  //     debugPrint('📝 Stack trace: $stackTrace');
  //     // searchResultErrorMessage('Unexpected error: ${e.toString()}');
  //     searchResultErrorMessage(Get.locale?.languageCode == 'ar'
  //         ? 'حدث خطأ غير متوقع'
  //         : 'An unexpected error occurred');
  //     searchResults.value = null;
  //     rethrow;
  //   } finally {
  //     debugPrint(
  //         '🏁 [fetchSearchResult] Fetch completed. Loading state: false');
  //     isLoadingSearchResults(false);
  //   }
  // }

  Future<void> fetchSearchResult() async {
    try {
      isLoadingSearchResults(true);
      debugPrint('🔄 [fetchSearchResult] Initiating property search...');
      searchResultErrorMessage('');

      final request = PropertySearchResultRequest(
        propertyOptions: propertyOption,
        propertyTypes: propertyType,
        propertyLocations: propertyLocation,
        propertyBedsBath: propertyBedsBath,
      );

      debugPrint('📤 [fetchSearchResult] Request Payload:');
      debugPrint(request.toJson().toString());

      final response = await apiService.getPropertySearchResult(request);

      debugPrint(response.toString());
      debugPrint('✅ API call completed. Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('📦 [fetchSearchResult] Parsing response data...');
        debugPrint('📄 Response Data: ${response.data}');

        searchResults.value = SearchPropertyResponse.fromJson(response.data);

        debugPrint('📊 [fetchSearchResult] Parsed Search Results:');
        debugPrint('Success: ${searchResults.value?.success}');
        debugPrint('Message (en): ${searchResults.value?.message?.english}');
        debugPrint('Message (ar): ${searchResults.value?.message?.arabic}');
        debugPrint(
            'Properties found: ${searchResults.value?.data?.length ?? 0}');

        debugPrint(
            '📊 [fetchSearchResult] Received Search Results: ${(searchResults.value)?.toJson()}');

        // FIXED: Moved this condition outside the property iteration
        if (searchResults.value?.data == null ||
            searchResults.value!.data!.isEmpty) {
          searchResultErrorMessage(Get.locale?.languageCode == 'ar'
              ? 'لا توجد عقارات تطابق معايير البحث'
              : 'No properties found matching your criteria');
          searchResults.value = null;
          return;
        }

        // Only show properties if they exist
        for (var property in searchResults.value!.data!) {
          debugPrint('🏠 Property ID: ${property.id}');
          debugPrint('   Title (en): ${property.propertyTitle?.english}');
          debugPrint('   Title (ar): ${property.propertyTitle?.arabic}');
          debugPrint('   Price: ${property.propertyPrice?.raw}');
          debugPrint('   Type (en): ${property.propertyType?.english}');
          debugPrint('   Location (en): ${property.propertyLocation?.english}');
        }
      } else {
        debugPrint('📄 Search response: ${response.data}');
        final errorMessage = response.data['message'] != null
            ? Get.locale?.languageCode == 'ar'
                ? response.data['message']['ar'] ?? 'حدث خطأ غير متوقع'
                : response.data['message']['en'] ??
                    'An unexpected error occurred'
            : 'Error status: ${response.statusCode}';

        searchResultErrorMessage(errorMessage);
        searchResults.value = null;

        debugPrint(
            '❌ [fetchSearchResult] API error: Status ${response.statusCode}');
        debugPrint('📄 Response body: ${response.data}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to load banners: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('🚨 [fetchSearchResult] DioException caught: ${e.type}');
      debugPrint('📌 Error details: ${e.message}');
      if (e.response != null) {
        debugPrint('⚡ Response status: ${e.response?.statusCode}');
        debugPrint('📄 Response data: ${e.response?.data}');
      }
      if (e.type == DioExceptionType.connectionTimeout) {
        searchResultErrorMessage(Get.locale?.languageCode == 'ar'
            ? 'انتهت مهلة الاتصال بالخادم'
            : 'Connection timeout');
      } else if (e.response != null) {
        final errorMessage = e.response?.data['message'] != null
            ? Get.locale?.languageCode == 'ar'
                ? e.response!.data['message']['ar'] ?? 'حدث خطأ غير متوقع'
                : e.response!.data['message']['en'] ??
                    'An unexpected error occurred'
            : 'Error status: ${e.response?.statusCode}';

        searchResultErrorMessage(errorMessage);
      } else {
        searchResultErrorMessage(Get.locale?.languageCode == 'ar'
            ? 'حدث خطأ في الاتصال بالخادم'
            : 'Server connection error');
      }
      searchResults.value = null;
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('‼️ [fetchSearchResult] Unexpected error: $e');
      debugPrint('📝 Stack trace: $stackTrace');
      searchResultErrorMessage(Get.locale?.languageCode == 'ar'
          ? 'حدث خطأ غير متوقع'
          : 'An unexpected error occurred');
      searchResults.value = null;
      rethrow;
    } finally {
      debugPrint(
          '🏁 [fetchSearchResult] Fetch completed. Loading state: false');
      isLoadingSearchResults(false);
    }
  }

  void navigateToPropertyDetails(Property property) {
    debugPrint('📍 Navigating to property details for ID: ${property.id}');

    // Debug print the property details before navigation
    debugPrint('🏠 Property Details to Pass:');
    debugPrint('ID: ${property.id}');
    debugPrint('Title (en): ${property.propertyTitle?.english}');
    debugPrint('Title (ar): ${property.propertyTitle?.arabic}');
    debugPrint('Price: ${property.propertyPrice?.raw} OMR');
    debugPrint('Type: ${property.propertyType?.english}');
    debugPrint('Location: ${property.propertyLocation?.english}');
    debugPrint(
        'Beds: ${property.propertyBed}, Baths: ${property.propertyBath}');

    Get.toNamed(
      AppRoute.propertyDetails,
      arguments: {
        'propertyId': property.id,
        'propertyData': property.toJson(),
      },
    );
  }
}
