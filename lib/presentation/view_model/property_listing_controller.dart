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
  int? propertyPriceForSearch;

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
  final RxBool isLoadingMoreResults = false.obs;
  
  // Pagination state
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalResults = 0.obs;
  final RxBool hasMorePages = false.obs;
  
  // Store all loaded properties
  final RxList<Property> allLoadedProperties = <Property>[].obs;

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
    
    params.forEach((key, value) {
      debugPrint('  $key: $value (${value.runtimeType})');
    });
    
    propertyOption = _safeIntCast(params['property_option']);
    propertyType = _safeIntCast(params['property_type']);
    propertyLocation = _safeIntCast(params['property_locations']);
    propertyBedsBath = _safeIntCast(params['beds_bath']);
    propertyPriceForSearch = _safeIntCast(params['property_price_range_id']);

    isCommercialSearch = params['is_commercial'] as bool?;
    shouldFilterCommercial = params['filter_commercial'] as bool? ?? false; // CHANGED: Default to false

    debugPrint('🎯 Parsed search parameters:');
    debugPrint('Property Option: $propertyOption');
    debugPrint('Property Type: $propertyType');
    debugPrint('Property Location: $propertyLocation');
    debugPrint('Property Beds/Bath: $propertyBedsBath');
    debugPrint('Property Price Range: $propertyPriceForSearch');
    debugPrint('🏢 Is Commercial Search: $isCommercialSearch');
    debugPrint('🔍 Should Filter Commercial: $shouldFilterCommercial');

    propertyOptionName = params['property_option_name']?.toString();
    propertyTypeName = params['property_type_name']?.toString();
    propertyLocationName = params['property_location_name']?.toString();
    propertyBedsBathName = params['property_beds_bath_name']?.toString();

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

  int? _safeIntCast(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  // UPDATED: Simplified filtering - only apply filters that are actually set
  List<Property> _filterProperties(List<Property> properties) {
    debugPrint('🔍 Starting filter with ${properties.length} properties');
    debugPrint('📋 Active filters:');
    debugPrint('   Location Query: $locationSearchQuery');
    debugPrint('   Beds/Bath: $propertyBedsBath');
    debugPrint('   Price Range: $propertyPriceForSearch');
    debugPrint('   Commercial Search: $isCommercialSearch');
    debugPrint('   Should Filter Commercial: $shouldFilterCommercial');
    
    final filtered = properties.where((property) {
      // === LOCATION FILTERING (if location is specified) ===
      if (locationSearchQuery != null && locationSearchQuery!.trim().isNotEmpty) {
        final propertyLocationEn = property.location?.en?.toLowerCase() ?? '';
        final propertyLocationAr = property.location?.ar?.toLowerCase() ?? '';
        final query = locationSearchQuery!.toLowerCase().trim();
        
        bool passesLocation = propertyLocationEn.contains(query) || 
                             propertyLocationAr.contains(query);
        
        if (!passesLocation) {
          debugPrint('❌ Property ${property.id} filtered out by location');
          return false;
        }
      }
      
      // === TYPE FILTERING (only if commercial filtering is enabled) ===
      if (shouldFilterCommercial == true && isCommercialSearch != null) {
        final typeEn = property.type?.en?.toLowerCase() ?? '';
        final typeAr = property.type?.ar?.toLowerCase() ?? '';
        
        final isCommercial = typeEn.contains('commercial') || typeAr.contains('تجاري');
        final isResidential = typeEn.contains('residential') || 
                             typeEn.contains('apartment') || 
                             typeAr.contains('سكني') || 
                             typeAr.contains('شقة');
        
        bool passesType = false;
        if (isCommercialSearch == true) {
          passesType = isCommercial;
        } else {
          passesType = isResidential || !isCommercial;
        }
        
        if (!passesType) {
          debugPrint('❌ Property ${property.id} filtered out by type (Commercial: $isCommercial, Residential: $isResidential)');
          return false;
        }
      }
      
      // === BEDS AND BATHS FILTERING (only for non-commercial properties) ===
      if (propertyBedsBath != null && propertyBedsBath != 0) {
        final typeEn = property.type?.en?.toLowerCase() ?? '';
        final isCommercial = typeEn.contains('commercial');
        
        if (!isCommercial) {
          final propertyBeds = property.specs?.beds ?? 0;
          final propertyBaths = property.specs?.baths ?? 0;
          
          bool passesBedsBaths = _matchesBedsBathsCriteria(propertyBeds, propertyBaths, propertyBedsBath!);
          
          if (!passesBedsBaths) {
            debugPrint('❌ Property ${property.id} filtered out by beds/baths (Beds: $propertyBeds, Baths: $propertyBaths)');
            return false;
          }
        }
      }
      
      // === PRICE RANGE FILTERING ===
      if (propertyPriceForSearch != null && propertyPriceForSearch != 0) {
        final propertyPrice = property.price?.raw ?? 0;
        bool passesPrice = _matchesPriceRangeCriteria(propertyPrice, propertyPriceForSearch!);
        
        if (!passesPrice) {
          debugPrint('❌ Property ${property.id} filtered out by price ($propertyPrice)');
          return false;
        }
      }
      
      debugPrint('✅ Property ${property.id} passed all filters');
      return true;
      
    }).toList();

    debugPrint('📊 FILTERING SUMMARY:');
    debugPrint('   Original properties: ${properties.length}');
    debugPrint('   Filtered properties: ${filtered.length}');
    debugPrint('   Filtered out: ${properties.length - filtered.length}');

    return filtered;
  }

  bool _matchesPriceRangeCriteria(int propertyPrice, int priceRangeId) {
    final priceRangeName = propertyPriceRangeName;
    
    if (priceRangeName == null || priceRangeName == '--select--') {
      return true;
    }
    
    final parts = priceRangeName.split('-');
    if (parts.length == 2) {
      final minPrice = int.tryParse(parts[0].trim()) ?? 0;
      final maxPrice = int.tryParse(parts[1].trim()) ?? double.infinity.toInt();
      
      return propertyPrice >= minPrice && propertyPrice <= maxPrice;
    }
    
    return true;
  }

  bool _matchesBedsBathsCriteria(int propertyBeds, int propertyBaths, int selectedBedsBathId) {
    switch (selectedBedsBathId) {
      case 1: return propertyBeds == 1 && propertyBaths >= 1;
      case 2: return propertyBeds == 2 && propertyBaths >= 1;
      case 3: return propertyBeds == 2 && propertyBaths >= 2;
      case 4: return propertyBeds >= 2 && propertyBaths >= 2;
      case 5: return propertyBeds >= 3 && propertyBaths >= 3;
      case 6: return propertyBeds >= 4 && propertyBaths >= 3;
      case 7: return propertyBeds >= 5 && propertyBaths >= 4;
      case 8: return propertyBeds == 0 && propertyBaths >= 1;
      default: return true;
    }
  }

  Future<void> fetchSearchResult() async {
    currentPage.value = 1;
    allLoadedProperties.clear();
    await _fetchPropertiesForPage(1, isInitialLoad: true);
  }

  Future<void> loadMoreProperties() async {
    if (isLoadingMoreResults.value || !hasMorePages.value) {
      debugPrint('⚠️ Already loading or no more pages available');
      return;
    }

    final nextPage = currentPage.value + 1;
    await _fetchPropertiesForPage(nextPage, isInitialLoad: false);
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page > totalPages.value) {
      debugPrint('⚠️ Invalid page number: $page');
      return;
    }

    if (isLoadingMoreResults.value) {
      debugPrint('⚠️ Already loading');
      return;
    }

    debugPrint('📄 Navigating to page $page');
    await _fetchPropertiesForPage(page, isInitialLoad: false);
  }

  Future<void> _fetchPropertiesForPage(int page, {required bool isInitialLoad}) async {
    try {
      if (isInitialLoad) {
        isLoadingSearchResults(true);
      } else {
        isLoadingMoreResults(true);
      }
      
      debugPrint('🔄 [_fetchPropertiesForPage] Fetching page $page...');
      searchResultErrorMessage('');

      final request = PropertySearchResultRequest(
        propertyOptions: propertyOption ?? 0,
        propertyTypes: propertyType ?? 0,
        propertyLocations: propertyLocation ?? 0,
        propertyBedsBath: propertyBedsBath ?? 0,
        propertyPriceForSearch: propertyPriceForSearch ?? 0,
        page: page,
      );

      debugPrint('📤 [_fetchPropertiesForPage] Request Payload: ${request.toJson()}');

      final response = await apiService.getPropertySearchResult(request);

      if (response.statusCode == 200) {
        if (response.data == null) {
          searchResultErrorMessage('No data received from server');
          return;
        }

        final rawResponse = SearchPropertyResponse.fromJson(response.data);
        
        // Update pagination info
        if (rawResponse.pagination != null) {
          currentPage.value = rawResponse.pagination!.currentPage ?? page;
          totalPages.value = rawResponse.pagination!.lastPage ?? 1;
          totalResults.value = rawResponse.pagination!.total ?? 0;
          hasMorePages.value = currentPage.value < totalPages.value;
          
          debugPrint('📊 Pagination Info:');
          debugPrint('   Current Page: ${currentPage.value}');
          debugPrint('   Total Pages: ${totalPages.value}');
          debugPrint('   Total Results: ${totalResults.value}');
          debugPrint('   Has More Pages: ${hasMorePages.value}');
        }
        
        if (rawResponse.data != null && rawResponse.data!.isNotEmpty) {
          debugPrint('📦 Raw API Response: ${rawResponse.data!.length} properties');
          
          // Apply filters
          final filteredProperties = _filterProperties(rawResponse.data!);
          
          debugPrint('✅ After filtering: ${filteredProperties.length} properties');
          
          // Replace properties for the current page
          allLoadedProperties.value = filteredProperties;
          
          // Update the main searchResults with filtered data
          searchResults.value = SearchPropertyResponse(
            success: rawResponse.success,
            data: allLoadedProperties,
            pagination: rawResponse.pagination,
          );
          
          debugPrint('🏠 Properties displayed:');
          debugPrint('   Page $page: ${filteredProperties.length} properties');
        } else {
          if (isInitialLoad) {
            searchResults.value = rawResponse;
          }
        }

        if (isInitialLoad && (searchResults.value?.data == null || searchResults.value!.data!.isEmpty)) {
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
        if (isInitialLoad) {
          searchResults.value = null;
        }
      }
    } on DioException catch (e) {
      debugPrint('🚨 [_fetchPropertiesForPage] DioException: ${e.type}');
      
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
      if (isInitialLoad) {
        searchResults.value = null;
      }
    } catch (e) {
      debugPrint('‼️ [_fetchPropertiesForPage] Unexpected error: $e');
      searchResultErrorMessage(Get.locale?.languageCode == 'ar'
          ? 'حدث خطأ غير متوقع'
          : 'An unexpected error occurred');
      if (isInitialLoad) {
        searchResults.value = null;
      }
    } finally {
      if (isInitialLoad) {
        isLoadingSearchResults(false);
      } else {
        isLoadingMoreResults(false);
      }
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
    debugPrint('Filtered results count: ${searchResults.value?.data?.length ?? 0}');
    debugPrint('Current page: ${currentPage.value}');
    debugPrint('Total pages: ${totalPages.value}');
    debugPrint('Has more pages: ${hasMorePages.value}');
    debugPrint('Is commercial search: $isCommercialSearch');
    debugPrint('Should filter: $shouldFilterCommercial');
  }
}