import 'package:majan/core/routes/app_route.dart';
import 'package:majan/core/utils/data_utlis.dart';
import 'package:majan/data/model/search_property_model.dart';
import 'package:majan/data/repositories/api_services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PropertyListingController extends GetxController {
  final ApiService apiService = ApiService();

  // Search parameters
  int? propertyOption;
  int? propertyType;
  int? propertyLocation;
  int? propertyBedsBath;
  int? propertyPriceForSearch; // ADDED: Price range parameter

  // Commercial filtering flag
  bool? isCommercialSearch;
  bool? shouldFilterCommercial;
  String? locationSearchQuery;
  String? propertyPriceRangeName;

  // Filter names
  String? propertyOptionName;
  String? propertyTypeName;
  String? propertyLocationName;
  String? propertyBedsBathName;

  // Fetch Property Search Results
  final Rxn<SearchPropertyResponse> searchResults = Rxn<SearchPropertyResponse>();
  final RxString searchResultErrorMessage = ''.obs;
  final RxBool isLoadingSearchResults = false.obs;
  
  // Store original unfiltered results for debugging
  List<Property>? originalResults;

  @override
  void onInit() {
    super.onInit();
    final params = Get.arguments as Map<String, dynamic>?;
    propertyPriceRangeName = params?['property_price_range_name']?.toString();
    
    debugPrint('🔍 Received parameters: $params');
    
    if (params == null) {
      debugPrint('❌ No parameters received!');
      return;
    }
    
    // Debug each parameter
    params.forEach((key, value) {
      debugPrint('  $key: $value (${value.runtimeType})');
    });
    
    // Map the correct parameter names and handle null values safely
    propertyOption = _safeIntCast(params['property_option']);
    propertyType = _safeIntCast(params['property_type']);
    propertyLocation = _safeIntCast(params['property_locations']);
    propertyBedsBath = _safeIntCast(params['beds_bath']);
    propertyPriceForSearch = _safeIntCast(params['property_price_range_id']); // ADDED: Get price range

    // Get commercial filtering parameters
    isCommercialSearch = params['is_commercial'] as bool?;
    shouldFilterCommercial = params['filter_commercial'] as bool? ?? true;

    debugPrint('🎯 Parsed search parameters:');
    debugPrint('Property Option: $propertyOption');
    debugPrint('Property Type: $propertyType');
    debugPrint('Property Location: $propertyLocation');
    debugPrint('Property Beds/Bath: $propertyBedsBath');
    debugPrint('Property Price Range: $propertyPriceForSearch'); // ADDED
    debugPrint('🏢 Is Commercial Search: $isCommercialSearch');
    debugPrint('🔍 Should Filter Commercial: $shouldFilterCommercial');

    // Store the names
    propertyOptionName = params['property_option_name']?.toString();
    propertyTypeName = params['property_type_name']?.toString();
    propertyLocationName = params['property_location_name']?.toString();
    propertyBedsBathName = params['property_beds_bath_name']?.toString();

    // Set location search query ONLY if we have a valid location name
    if (propertyLocationName != null && 
        propertyLocationName != '--Select--' && 
        propertyLocationName!.trim().isNotEmpty) {
      locationSearchQuery = propertyLocationName;
    } else {
      locationSearchQuery = null;
    }

    debugPrint('🏷️ Filter names:');
    debugPrint('Option Name: $propertyOptionName');
    debugPrint('Type Name: $propertyTypeName');
    debugPrint('Location Name: $propertyLocationName → Search Query: $locationSearchQuery');
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
      debugPrint('🚫 Commercial filtering disabled, returning all properties');
      return properties;
    }

    final filtered = properties.where((property) {
      // === LOCATION FILTERING ===
      bool passesLocationFilter = true;
      
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final propertyLocationEn = property.location?.en?.toLowerCase() ?? '';
        final propertyLocationAr = property.location?.ar?.toLowerCase() ?? '';
        final query = searchQuery.toLowerCase().trim();
        
        passesLocationFilter = propertyLocationEn.contains(query) || 
                             propertyLocationAr.contains(query);
        
        debugPrint('🌍 Location Filter Check:');
        debugPrint('   Search Query: "$query"');
        debugPrint('   Property Location EN: "$propertyLocationEn"');
        debugPrint('   Property Location AR: "$propertyLocationAr"');
        debugPrint('   Passes Location Filter: $passesLocationFilter');
      } else {
        passesLocationFilter = true;
        debugPrint('🌍 No location search query - location filter passes automatically');
      }
      
      // === TYPE FILTERING ===
      final typeEn = property.type?.en?.toLowerCase() ?? '';
      final typeAr = property.type?.ar?.toLowerCase() ?? '';
      final titleEn = property.title?.en?.toLowerCase() ?? '';
      final titleAr = property.title?.ar?.toLowerCase() ?? '';
      
      final commercialKeywords = [
        'commercial', 'office', 'shop', 'retail', 'warehouse', 'industrial',
        'store', 'building', 'tower', 'center', 'mall', 'cbd',
        'business', 'corporate', 'plaza', 'showroom',
        'تجاري', 'مكتب', 'متجر', 'مستودع', 'صناعي', 'برج',
        'أعمال', 'تجارة', 'معرض'
      ];
      
      final residentialKeywords = [
        'residential', 'apartment', 'flat', 'house', 'villa', 'home',
        'duplex', 'penthouse', 'studio',
        'سكني', 'شقة', 'منزل', 'فيلا', 'بيت', 'سكن', 'استوديو'
      ];
      
      bool hasResidentialIndicator = residentialKeywords.any((keyword) => 
        typeEn.contains(keyword) || typeAr.contains(keyword)
      );
      
      bool hasCommercialIndicator = commercialKeywords.any((keyword) => 
        typeEn.contains(keyword) || 
        typeAr.contains(keyword) ||
        titleEn.contains(keyword) ||
        titleAr.contains(keyword)
      );
      
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
                                     !isCommercialProperty &&
                                     propertyBedsBathName != null &&
                                     propertyBedsBathName != '--Select--' &&
                                     propertyBedsBathName!.trim().isNotEmpty;

      if (shouldApplyBedsBathFilter) {
        final propertyBeds = property.specs?.beds ?? 0;
        final propertyBaths = property.specs?.baths ?? 0;
        
        passesBedsBathsFilter = _matchesBedsBathsCriteria(propertyBeds, propertyBaths, propertyBedsBath!);
        
        debugPrint('🛏️ Beds/Baths Filter:');
        debugPrint('   Property Beds: $propertyBeds, Baths: $propertyBaths');
        debugPrint('   Selected BedsBath ID: $propertyBedsBath');
        debugPrint('   Passes Beds/Baths Filter: $passesBedsBathsFilter');
      }
      
      // === PRICE RANGE FILTERING === ✅ ADD THIS SECTION
      bool passesPriceFilter = true;
      
      bool shouldApplyPriceFilter = propertyPriceForSearch != null && 
                                   propertyPriceForSearch != 0;
      
      if (shouldApplyPriceFilter) {
        final propertyPrice = property.price?.raw ?? 0;
        passesPriceFilter = _matchesPriceRangeCriteria(propertyPrice, propertyPriceForSearch!);
        
        debugPrint('💰 Price Filter:');
        debugPrint('   Property Price: $propertyPrice');
        debugPrint('   Selected Price Range ID: $propertyPriceForSearch');
        debugPrint('   Passes Price Filter: $passesPriceFilter');
      }
      
      final bool finalResult = passesLocationFilter && passesTypeFilter && passesBedsBathsFilter && passesPriceFilter;
      
      debugPrint('🏠 Property: ${property.title?.en}');
      debugPrint('   Final Result: $finalResult');
      debugPrint('---');
      
      return finalResult;
      
    }).toList();

    debugPrint('📊 FILTERING SUMMARY:');
    debugPrint('   Original properties: ${properties.length}');
    debugPrint('   Filtered properties: ${filtered.length}');

    return filtered;
  }

 bool _matchesPriceRangeCriteria(int propertyPrice, int priceRangeId) {
  // Get the price range name like "130-200"
  final priceRangeName = propertyPriceRangeName;
  
  if (priceRangeName == null || priceRangeName == '--select--') {
    return true;
  }
  
  // Parse the range from the name (e.g., "130-200")
  final parts = priceRangeName.split('-');
  if (parts.length == 2) {
    final minPrice = int.tryParse(parts[0].trim()) ?? 0;
    final maxPrice = int.tryParse(parts[1].trim()) ?? double.infinity.toInt();
    
    debugPrint('   Price Range: $minPrice - $maxPrice');
    return propertyPrice >= minPrice && propertyPrice <= maxPrice;
  }
  
  return true;
}

  bool _matchesBedsBathsCriteria(int propertyBeds, int propertyBaths, int selectedBedsBathId) {
    switch (selectedBedsBathId) {
      case 1: // 1 bed, 1+ bath
        return propertyBeds == 1 && propertyBaths >= 1;
      case 2: // 2 beds, 1+ baths
        return propertyBeds == 2 && propertyBaths >= 1;
      case 3: // 2 beds, 2+ baths
        return propertyBeds == 2 && propertyBaths >= 2;
      case 4: // 2+ beds, 2+ baths
        return propertyBeds >= 2 && propertyBaths >= 2;
      case 5: // 3+ beds, 3+ baths
        return propertyBeds >= 3 && propertyBaths >= 3;
      case 6: // 4+ beds, 3+ baths
        return propertyBeds >= 4 && propertyBaths >= 3;
      case 7: // 5+ beds, 4+ baths
        return propertyBeds >= 5 && propertyBaths >= 4;
      case 8: // Studio (0 bed, 1 bath)
        return propertyBeds == 0 && propertyBaths >= 1;
      default:
        return true;
    }
  }

  Future<void> fetchSearchResult() async {
    try {
      isLoadingSearchResults(true);
      debugPrint('🔄 [fetchSearchResult] Initiating property search...');
      searchResultErrorMessage('');

      // FIXED: Use proper field name from model
      final request = PropertySearchResultRequest(
        propertyOptions: propertyOption ?? 0,
        propertyTypes: propertyType ?? 0,
        propertyLocations: propertyLocation ?? 0,
        propertyBedsBath: propertyBedsBath ?? 0,
        propertyPriceForSearch: propertyPriceForSearch ?? 0, // CORRECTED: Matches model
      );

      debugPrint('📤 [fetchSearchResult] Request Payload: ${request.toJson()}');

      final response = await apiService.getPropertySearchResult(request);

      if (response.statusCode == 200) {
        if (response.data == null) {
          searchResultErrorMessage('No data received from server');
          return;
        }

        final rawResponse = SearchPropertyResponse.fromJson(response.data);
        originalResults = rawResponse.data;
        
        if (rawResponse.data != null && rawResponse.data!.isNotEmpty) {
          final filteredProperties = _filterPropertiesByType(
            rawResponse.data!, 
            searchQuery: locationSearchQuery
          );
          
          searchResults.value = SearchPropertyResponse(
            success: rawResponse.success,
            data: filteredProperties,
          );
        } else {
          searchResults.value = rawResponse;
        }

        if (searchResults.value?.data == null || searchResults.value!.data!.isEmpty) {
          searchResultErrorMessage(Get.locale?.languageCode == 'ar'
              ? 'لا توجد عقارات تطابق معايير البحث'
              : 'No properties found matching your criteria');
        }
        
      } else {
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
    } catch (e) {
      debugPrint('‼️ [fetchSearchResult] Unexpected error: $e');
      searchResultErrorMessage(Get.locale?.languageCode == 'ar'
          ? 'حدث خطأ غير متوقع'
          : 'An unexpected error occurred');
      searchResults.value = null;
    } finally {
      isLoadingSearchResults(false);
    }
  }

  void navigateToPropertyDetails(Property property) {
    Get.toNamed(
      AppRoute.propertyDetails,
      arguments: {
        'propertyId': property.id,
        'propertyData': property.toJson(),
      },
    );
  }

  bool get hasFilters => 
    propertyOption != null || 
    propertyType != null || 
    propertyLocation != null || 
    propertyBedsBath != null ||
    propertyPriceForSearch != null;
    
  String get appliedFiltersText {
    final filters = <String>[];
    
    if (propertyOptionName != null) filters.add(propertyOptionName!);
    if (propertyTypeName != null) filters.add(propertyTypeName!);
    if (propertyLocationName != null) filters.add(propertyLocationName!);
    if (propertyBedsBathName != null) filters.add(propertyBedsBathName!);
    
    return filters.join(' • ');
  }

  Future<void> retrySearch() async {
    await fetchSearchResult();
  }

  void goBackToSearch() {
    Get.back();
  }

  void debugResults() {
    debugPrint('🔍 DEBUG RESULTS:');
    debugPrint('Original results count: ${originalResults?.length ?? 0}');
    debugPrint('Filtered results count: ${searchResults.value?.data?.length ?? 0}');
    debugPrint('Is commercial search: $isCommercialSearch');
    debugPrint('Should filter: $shouldFilterCommercial');
  }
}