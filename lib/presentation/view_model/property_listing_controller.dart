import 'package:majan/core/routes/app_route.dart';
import 'package:majan/core/utils/data_utlis.dart';
import 'package:majan/data/model/search_property_model.dart';
import 'package:majan/data/repositories/api_services.dart';
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

  // ADD: Commercial filtering flag
  bool? isCommercialSearch;
  bool? shouldFilterCommercial;
  String? locationSearchQuery;

  // filter names
  String? propertyOptionName;
  String? propertyTypeName;
  String? propertyLocationName;
  String? propertyBedsBathName;

  // Fetch Property Search Results
  final Rxn<SearchPropertyResponse> searchResults = Rxn<SearchPropertyResponse>();
  final RxString searchResultErrorMessage = ''.obs;
  final RxBool isLoadingSearchResults = false.obs;
  
  // ADD: Store original unfiltered results for debugging
  List<Property>? originalResults;

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

    // ADD: Get commercial filtering parameters
    isCommercialSearch = params['is_commercial'] as bool?;
    shouldFilterCommercial = params['filter_commercial'] as bool? ?? true; // Default to true

    debugPrint('🎯 Parsed search parameters:');
    debugPrint('Property Option: $propertyOption');
    debugPrint('Property Type: $propertyType');
    debugPrint('Property Location: $propertyLocation');
    debugPrint('Property Beds/Bath: $propertyBedsBath');
    debugPrint('🏢 Is Commercial Search: $isCommercialSearch');
    debugPrint('🔍 Should Filter Commercial: $shouldFilterCommercial');

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

 


List<Property> _filterPropertiesByType(List<Property> properties, {String? searchQuery}) {
  if (shouldFilterCommercial != true) {
    debugPrint('🚫 Filtering disabled, returning all properties');
    return properties;
  }

  final filtered = properties.where((property) {
    // === LOCATION FILTERING (NEW) ===
    bool passesLocationFilter = true;
    
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final propertyLocationEn = property.location?.en?.toLowerCase() ?? '';
      final propertyLocationAr = property.location?.ar?.toLowerCase() ?? '';
      final query = searchQuery.toLowerCase().trim();
      
      // Check if location contains the search query
      passesLocationFilter = propertyLocationEn.contains(query) || 
                           propertyLocationAr.contains(query);
      
      debugPrint('🌍 Location Filter Check:');
      debugPrint('   Search Query: "$query"');
      debugPrint('   Property Location EN: "$propertyLocationEn"');
      debugPrint('   Property Location AR: "$propertyLocationAr"');
      debugPrint('   Passes Location Filter: $passesLocationFilter');
    }
    
    // === EXISTING TYPE FILTERING ===
    final typeEn = property.type?.en?.toLowerCase() ?? '';
    final typeAr = property.type?.ar?.toLowerCase() ?? '';
    final titleEn = property.title?.en?.toLowerCase() ?? '';
    final titleAr = property.title?.ar?.toLowerCase() ?? '';
    
    // Define commercial indicators
    final commercialKeywords = [
      'commercial', 'office', 'shop', 'retail', 'warehouse', 'industrial',
      'store', 'building', 'tower', 'center', 'mall', 'cbd',
      'business', 'corporate', 'plaza', 'showroom',
      'تجاري', 'مكتب', 'متجر', 'مستودع', 'صناعي', 'برج',
      'أعمال', 'تجارة', 'معرض'
    ];
    
    // Define residential indicators
    final residentialKeywords = [
      'residential', 'apartment', 'flat', 'house', 'villa', 'home',
      'duplex', 'penthouse', 'studio',
      'سكني', 'شقة', 'منزل', 'فيلا', 'بيت', 'سكن', 'استوديو'
    ];
    
    // Check for explicit residential first
    bool hasResidentialIndicator = residentialKeywords.any((keyword) => 
      typeEn.contains(keyword) || 
      typeAr.contains(keyword)
    );
    
    // Check for commercial indicators
    bool hasCommercialIndicator = commercialKeywords.any((keyword) => 
      typeEn.contains(keyword) || 
      typeAr.contains(keyword) ||
      titleEn.contains(keyword) ||
      titleAr.contains(keyword)
    );
    
    // Classification logic
    bool isCommercialProperty;
    bool isResidentialProperty;
    
    if (hasResidentialIndicator && !hasCommercialIndicator) {
      isCommercialProperty = false;
      isResidentialProperty = true;
    } else if (hasCommercialIndicator && !hasResidentialIndicator) {
      isCommercialProperty = true;
      isResidentialProperty = false;
    } else if (hasResidentialIndicator && hasCommercialIndicator) {
      if (typeEn.contains('residential') || typeAr.contains('سكني')) {
        isCommercialProperty = false;
        isResidentialProperty = true;
      } else {
        isCommercialProperty = true;
        isResidentialProperty = false;
      }
    } else {
      if (typeEn.contains('apartment') || typeEn.contains('flat') || 
          typeAr.contains('شقة')) {
        isCommercialProperty = false;
        isResidentialProperty = true;
      } else {
        isCommercialProperty = true;
        isResidentialProperty = false;
      }
    }
    
    // Check if property passes TYPE filtering
    bool passesTypeFilter;
    if (isCommercialSearch == true) {
      passesTypeFilter = isCommercialProperty;
    } else {
      passesTypeFilter = isResidentialProperty;
    }
    
    // === BEDS AND BATHS FILTERING ===
    bool passesBedsBathsFilter = true;
    
    bool shouldApplyBedsBathFilter = propertyBedsBath != null && 
                                   propertyBedsBath != 0 && 
                                   isResidentialProperty &&
                                   propertyBedsBathName != null &&
                                   propertyBedsBathName != '--Select--' &&
                                   propertyBedsBathName!.trim().isNotEmpty;
    
    if (shouldApplyBedsBathFilter) {
      final propertyBeds = property.specs?.beds ?? 0;
      final propertyBaths = property.specs?.baths ?? 0;
      
      passesBedsBathsFilter = _matchesBedsBathsCriteria(propertyBeds, propertyBaths, propertyBedsBath!);
    }
    
    debugPrint('🏠 Property: ${property.title?.en}');
    debugPrint('   Location: ${property.location?.en} | ${property.location?.ar}');
    debugPrint('   Type: $typeEn | $typeAr');
    debugPrint('   Passes Location Filter: $passesLocationFilter');
    debugPrint('   Passes Type Filter: $passesTypeFilter');
    debugPrint('   Passes Beds/Baths Filter: $passesBedsBathsFilter');
    debugPrint('   Final Result: ${passesLocationFilter && passesTypeFilter && passesBedsBathsFilter}');
    
    // Return true only if property passes ALL filters
    return passesLocationFilter && passesTypeFilter && passesBedsBathsFilter;
    
  }).toList();

  debugPrint('📊 Original properties: ${properties.length}');
  debugPrint('📊 Filtered properties: ${filtered.length}');
  debugPrint('🌍 Search Query: "$searchQuery"');
  debugPrint('🎯 Showing commercial: ${isCommercialSearch == true}');

  return filtered;
}
// NEW: Helper method to match beds/baths criteria
// FIXED: Helper method to match beds/baths criteria
bool _matchesBedsBathsCriteria(int propertyBeds, int propertyBaths, int selectedBedsBathId) {
  debugPrint('🔍 Matching beds/baths: Property($propertyBeds bed, $propertyBaths bath) vs Selected ID($selectedBedsBathId)');
  
  // Based on your debug logs showing ID: 1 is being used, let me map it correctly
  switch (selectedBedsBathId) {
    case 1: // 1 bed, 1 bath (this is what your properties have)
      bool matches = propertyBeds == 1 && propertyBaths >= 1;
      debugPrint('   Case 1 (1 bed, 1+ bath): $matches');
      return matches;
      
    case 2: // 2 beds, 1+ baths
      bool matches2 = propertyBeds == 2 && propertyBaths >= 1;
      debugPrint('   Case 2 (2 beds, 1+ bath): $matches2');
      return matches2;
      
    case 3: // 2 beds, 2 baths
      bool matches3 = propertyBeds == 2 && propertyBaths >= 2;
      debugPrint('   Case 3 (2 beds, 2+ bath): $matches3');
      return matches3;
      
    case 4: // 3 beds, 2+ baths
      bool matches4 = propertyBeds == 3 && propertyBaths >= 2;
      debugPrint('   Case 4 (3 beds, 2+ bath): $matches4');
      return matches4;
      
    case 5: // 3 beds, 3+ baths
      bool matches5 = propertyBeds == 3 && propertyBaths >= 3;
      debugPrint('   Case 5 (3 beds, 3+ bath): $matches5');
      return matches5;
      
    case 6: // 4+ beds, 3+ baths
      bool matches6 = propertyBeds >= 4 && propertyBaths >= 3;
      debugPrint('   Case 6 (4+ beds, 3+ bath): $matches6');
      return matches6;
      
    case 7: // 5+ beds, 4+ baths
      bool matches7 = propertyBeds >= 5 && propertyBaths >= 4;
      debugPrint('   Case 7 (5+ beds, 4+ bath): $matches7');
      return matches7;
      
    case 8: // Studio (0 bed, 1 bath)
      bool matches8 = propertyBeds == 0 && propertyBaths >= 1;
      debugPrint('   Case 8 (Studio - 0 bed, 1+ bath): $matches8');
      return matches8;
      
    // Add more cases based on your actual dropdown options
    default:
      debugPrint('⚠️ Unknown beds/baths selection ID: $selectedBedsBathId - allowing all');
      return true; // If unknown, don't filter out
  }
}

// ALTERNATIVE: Dynamic beds/baths matching (if you have the actual bed/bath names)
bool _matchesBedsBathsCriteriaByName(int propertyBeds, int propertyBaths, String? bedsBathName) {
  if (bedsBathName == null || bedsBathName.isEmpty || bedsBathName == '--Select--') {
    return true; // No filtering if not selected
  }
  
  final name = bedsBathName.toLowerCase();
  
  // Match patterns like "1 bed 1 bath", "2 beds 2 baths", "studio", etc.
  if (name.contains('studio')) {
    return propertyBeds == 0; // Studios typically have 0 bedrooms
  }
  
  // Extract numbers from the name
  final bedMatch = RegExp(r'(\d+)\s*bed').firstMatch(name);
  final bathMatch = RegExp(r'(\d+)\s*bath').firstMatch(name);
  
  if (bedMatch != null) {
    final requiredBeds = int.parse(bedMatch.group(1)!);
    if (propertyBeds != requiredBeds) return false;
  }
  
  if (bathMatch != null) {
    final requiredBaths = int.parse(bathMatch.group(1)!);
    if (propertyBaths < requiredBaths) return false; // Use >= for baths
  }
  
  return true;
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
          final rawResponse = SearchPropertyResponse.fromJson(response.data);
          debugPrint('✅ Successfully parsed response');
          
          // Store original results for debugging
          originalResults = rawResponse.data;
          
          // Log the parsed data structure
          debugPrint('📊 Parsed Response Details:');
          debugPrint('Success: ${rawResponse.success}');
          debugPrint('Data is null: ${rawResponse.data == null}');
          debugPrint('Data length: ${rawResponse.data?.length ?? 0}');
          
          // If data exists, log first property details
          if (rawResponse.data != null && rawResponse.data!.isNotEmpty) {
            debugPrint('🏠 First Property Details:');
            final firstProperty = rawResponse.data!.first;
            debugPrint('Property ID: ${firstProperty.id}');
            debugPrint('Property Title EN: ${firstProperty.title?.en}');
            debugPrint('Property Title AR: ${firstProperty.title?.ar}');
            debugPrint('Property Type EN: ${firstProperty.type?.en}');
            debugPrint('Property Type AR: ${firstProperty.type?.ar}');
            debugPrint('Property Location EN: ${firstProperty.location?.en}');
            debugPrint('Property Location AR: ${firstProperty.location?.ar}');
            debugPrint('Property Price Raw: ${firstProperty.price?.raw}');
            debugPrint('Property Deal Type EN: ${firstProperty.dealType?.en}');
            debugPrint('Property Deal Type AR: ${firstProperty.dealType?.ar}');
            debugPrint('Property Beds: ${firstProperty.specs?.beds}');
            debugPrint('Property Baths: ${firstProperty.specs?.baths}');
            debugPrint('Property Area EN: ${firstProperty.specs?.area?.en}');
            debugPrint('Property Image: ${firstProperty.image}');

            // Log all property titles and types for debugging
            debugPrint('🎯 All returned properties before filtering:');
            for (int i = 0; i < rawResponse.data!.length; i++) {
              final property = rawResponse.data![i];
              debugPrint('  [$i] ID: ${property.id}, Title: ${property.title?.en}, Type: ${property.type?.en}');
            }
          }

          // APPLY FILTERING HERE
          if (rawResponse.data != null && rawResponse.data!.isNotEmpty) {
            final filteredProperties = _filterPropertiesByType(rawResponse.data!);
            
            // Create new response with filtered data
            searchResults.value = SearchPropertyResponse(
              success: rawResponse.success,
              data: filteredProperties,
            );
            
            debugPrint('🎯 Final filtered properties:');
            for (int i = 0; i < filteredProperties.length; i++) {
              final property = filteredProperties[i];
              debugPrint('  [$i] ID: ${property.id}, Title: ${property.title?.en}, Type: ${property.type?.en}');
            }
            
          } else {
            searchResults.value = rawResponse;
          }

        } catch (parseError) {
          debugPrint('❌ Error parsing response: $parseError');
          debugPrint('📄 Response that failed to parse: ${response.data}');
          searchResultErrorMessage('Error parsing server response');
          return;
        }

        // Check if we have results after filtering
        if (searchResults.value?.data == null || searchResults.value!.data!.isEmpty) {
          debugPrint('📭 No properties found after filtering');
          searchResultErrorMessage(Get.locale?.languageCode == 'ar'
              ? 'لا توجد عقارات تطابق معايير البحث'
              : 'No properties found matching your criteria');
          return;
        }

        debugPrint('✅ Final result: ${searchResults.value!.data!.length} properties after filtering');
        
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

  // ADD: Debug method to show original vs filtered results
  void debugResults() {
    debugPrint('🔍 DEBUG RESULTS:');
    debugPrint('Original results count: ${originalResults?.length ?? 0}');
    debugPrint('Filtered results count: ${searchResults.value?.data?.length ?? 0}');
    debugPrint('Is commercial search: $isCommercialSearch');
    debugPrint('Should filter: $shouldFilterCommercial');
    
    if (originalResults != null) {
      debugPrint('Original properties:');
      for (var prop in originalResults!) {
        debugPrint('  - ${prop.title?.en} (${prop.type?.en})');
      }
    }
    
    if (searchResults.value?.data != null) {
      debugPrint('Filtered properties:');
      for (var prop in searchResults.value!.data!) {
        debugPrint('  - ${prop.title?.en} (${prop.type?.en})');
      }
    }
  }
}