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

  // Changed from late int to int? to handle nullable values
  int? propertyOption;
  int? propertyType;
  int? propertyLocation;  // This will be mapped from 'property_locations'
  int? propertyBedsBath;  // This will be mapped from 'beds_bath'

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
    final params = Get.arguments as Map<String, dynamic>?;
    
    debugPrint('🔍 Received parameters: $params');
    
    if (params == null) {
      debugPrint('❌ No parameters received!');
      return;
    }
    
    // Debug each parameter
    params.forEach((key, value) {
      debugPrint('  $key: $value (${value.runtimeType})');
    });
    
    // FIXED: Map the correct parameter names and handle null values safely
    propertyOption = _safeIntCast(params['property_option']);
    propertyType = _safeIntCast(params['property_type']);
    propertyLocation = _safeIntCast(params['property_locations']); // Note: 'property_locations' with 's'
    propertyBedsBath = _safeIntCast(params['beds_bath']); // Note: 'beds_bath' not 'property_beds_bath'

    debugPrint('🎯 Parsed search parameters:');
    debugPrint('Property Option: $propertyOption');
    debugPrint('Property Type: $propertyType');
    debugPrint('Property Location: $propertyLocation');
    debugPrint('Property Beds/Bath: $propertyBedsBath');

    // Store the names
    propertyOptionName = params['property_option_name']?.toString();
    propertyTypeName = params['property_type_name']?.toString();
    propertyLocationName = params['property_location_name']?.toString();
    propertyBedsBathName = params['property_beds_bath_name']?.toString();

    debugPrint('🏷️ Filter names:');
    debugPrint('Option Name: $propertyOptionName');
    debugPrint('Type Name: $propertyTypeName');
    debugPrint('Location Name: $propertyLocationName');
    debugPrint('Beds/Bath Name: $propertyBedsBathName');

    fetchSearchResult();
  }

  // Helper method to safely cast values to int
  int? _safeIntCast(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  Future<void> fetchSearchResult() async {
    try {
      isLoadingSearchResults(true);
      debugPrint('🔄 [fetchSearchResult] Initiating property search...');
      searchResultErrorMessage('');

      // FIXED: Handle nullable values in the request
      final request = PropertySearchResultRequest(
        propertyOptions: propertyOption ?? 0, // Provide default if null
        propertyTypes: propertyType ?? 0,
        propertyLocations: propertyLocation ?? 0,
        propertyBedsBath: propertyBedsBath ?? 0,
      );

      debugPrint('📤 [fetchSearchResult] Request Payload:');
      debugPrint('Property Option: ${propertyOption ?? "null"}');
      debugPrint('Property Type: ${propertyType ?? "null"}');
      debugPrint('Property Location: ${propertyLocation ?? "null"}');
      debugPrint('Property Beds/Bath: ${propertyBedsBath ?? "null"}');
      debugPrint('Full Request: ${request.toJson()}');

      final response = await apiService.getPropertySearchResult(request);

      debugPrint('✅ API call completed. Status: ${response.statusCode}');
      debugPrint('📄 Raw Response Data: ${response.data}');

      if (response.statusCode == 200) {
        debugPrint('📦 [fetchSearchResult] Parsing response data...');
        
        // Check if response.data is null or empty
        if (response.data == null) {
          debugPrint('❌ Response data is null');
          searchResultErrorMessage('No data received from server');
          return;
        }

        // Try to parse the response
        try {
          searchResults.value = SearchPropertyResponse.fromJson(response.data);
          debugPrint('✅ Successfully parsed response');
          
          // Log the parsed data structure
          debugPrint('📊 Parsed Response Details:');
          debugPrint('Success: ${searchResults.value?.success}');
          debugPrint('Data is null: ${searchResults.value?.data == null}');
          debugPrint('Data length: ${searchResults.value?.data?.length ?? 0}');
          
          // If data exists, log first property details
          if (searchResults.value?.data != null && searchResults.value!.data!.isNotEmpty) {
            debugPrint('🏠 First Property Details:');
            final firstProperty = searchResults.value!.data!.first;
            debugPrint('Property ID: ${firstProperty.id}');
            debugPrint('Property Title EN: ${firstProperty.title?.en}');
            debugPrint('Property Title AR: ${firstProperty.title?.ar}');
            debugPrint('Property Type EN: ${firstProperty.type?.en}');
            debugPrint('Property Type AR: ${firstProperty.type?.ar}');
            debugPrint('Property Location EN: ${firstProperty.location?.en}');
            debugPrint('Property Location AR: ${firstProperty.location?.ar}');
            debugPrint('Property Price Raw: ${firstProperty.price?.raw}');
            debugPrint('Property Price EN: ${firstProperty.price?.formatted?.en}');
            debugPrint('Property Price AR: ${firstProperty.price?.formatted?.ar}');
            debugPrint('Property Deal Type EN: ${firstProperty.dealType?.en}');
            debugPrint('Property Deal Type AR: ${firstProperty.dealType?.ar}');
            debugPrint('Property Beds: ${firstProperty.specs?.beds}');
            debugPrint('Property Baths: ${firstProperty.specs?.baths}');
            debugPrint('Property Area EN: ${firstProperty.specs?.area?.en}');
            debugPrint('Property Area AR: ${firstProperty.specs?.area?.ar}');
            debugPrint('Property Image: ${firstProperty.image}');
          }

        } catch (parseError) {
          debugPrint('❌ Error parsing response: $parseError');
          debugPrint('📄 Response that failed to parse: ${response.data}');
          searchResultErrorMessage('Error parsing server response');
          return;
        }

        // Check if we have results
        if (searchResults.value?.data == null || searchResults.value!.data!.isEmpty) {
          debugPrint('📭 No properties found in response');
          searchResultErrorMessage(Get.locale?.languageCode == 'ar'
              ? 'لا توجد عقارات تطابق معايير البحث'
              : 'No properties found matching your criteria');
          
          // Don't set searchResults.value = null here, keep the empty response
          // searchResults.value = null;  // Comment this out
          return;
        }

        debugPrint('✅ Found ${searchResults.value!.data!.length} properties');
        
        // Log all property IDs to verify filtering
        debugPrint('🎯 All returned property IDs:');
        for (int i = 0; i < searchResults.value!.data!.length; i++) {
          final property = searchResults.value!.data![i];
          debugPrint('  [$i] ID: ${property.id}, Title: ${property.title?.en}');
        }
        
      } else {
        debugPrint('❌ API Error - Status: ${response.statusCode}');
        debugPrint('📄 Error Response: ${response.data}');
        
        final errorMessage = response.data?['message'] != null
            ? Get.locale?.languageCode == 'ar'
                ? response.data['message']['ar'] ?? 'حدث خطأ غير متوقع'
                : response.data['message']['en'] ?? 'An unexpected error occurred'
            : 'Error status: ${response.statusCode}';

        searchResultErrorMessage(errorMessage);
        searchResults.value = null;
      }
    } on DioException catch (e) {
      debugPrint('🚨 [fetchSearchResult] DioException: ${e.type}');
      debugPrint('📌 Error details: ${e.message}');
      debugPrint('📄 Response data: ${e.response?.data}');
      
      // Handle different error types
      if (e.type == DioExceptionType.connectionTimeout) {
        searchResultErrorMessage(Get.locale?.languageCode == 'ar'
            ? 'انتهت مهلة الاتصال بالخادم'
            : 'Connection timeout');
      } else if (e.response != null) {
        final errorMessage = e.response?.data?['message'] != null
            ? Get.locale?.languageCode == 'ar'
                ? e.response!.data['message']['ar'] ?? 'حدث خطأ غير متوقع'
                : e.response!.data['message']['en'] ?? 'An unexpected error occurred'
            : 'Error status: ${e.response?.statusCode}';
        searchResultErrorMessage(errorMessage);
      } else {
        searchResultErrorMessage(Get.locale?.languageCode == 'ar'
            ? 'حدث خطأ في الاتصال بالخادم'
            : 'Server connection error');
      }
      searchResults.value = null;
    } catch (e, stackTrace) {
      debugPrint('‼️ [fetchSearchResult] Unexpected error: $e');
      debugPrint('📝 Stack trace: $stackTrace');
      searchResultErrorMessage(Get.locale?.languageCode == 'ar'
          ? 'حدث خطأ غير متوقع'
          : 'An unexpected error occurred');
      searchResults.value = null;
    } finally {
      debugPrint('🏁 [fetchSearchResult] Completed. Loading: false');
      isLoadingSearchResults(false);
    }
  }

  void navigateToPropertyDetails(Property property) {
    debugPrint('📍 Navigating to property details for ID: ${property.id}');

    // Debug print the property details before navigation
    debugPrint('🏠 Property Details to Pass:');
    debugPrint('ID: ${property.id}');

    Get.toNamed(
      AppRoute.propertyDetails,
      arguments: {
        'propertyId': property.id,
        'propertyData': property.toJson(),
      },
    );
  }

  // Additional helper methods
  bool get hasFilters => 
    propertyOption != null || 
    propertyType != null || 
    propertyLocation != null || 
    propertyBedsBath != null;
    
  String get appliedFiltersText {
    final filters = <String>[];
    
    if (propertyOptionName != null) filters.add(propertyOptionName!);
    if (propertyTypeName != null) filters.add(propertyTypeName!);
    if (propertyLocationName != null) filters.add(propertyLocationName!);
    if (propertyBedsBathName != null) filters.add(propertyBedsBathName!);
    
    return filters.join(' • ');
  }

  // Method to retry the search
  Future<void> retrySearch() async {
    await fetchSearchResult();
  }

  // Method to clear search and go back
  void goBackToSearch() {
    Get.back();
  }
}