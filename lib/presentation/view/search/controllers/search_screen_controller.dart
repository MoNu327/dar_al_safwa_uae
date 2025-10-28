import 'package:majan/core/utils/data_utlis.dart';
import 'package:majan/data/model/search_dropdown_model.dart';
import 'package:majan/data/model/search_property_model.dart';
import 'package:majan/data/repositories/api_services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SearchScreenController extends GetxController {
  final ApiService apiService = ApiService();
  final GetStorage storage = GetStorage();

  // search dropdown data
  final Rxn<SearchDropdownResponse> searchDropdownResponse =
      Rxn<SearchDropdownResponse>();
  final RxBool isLoadingSearchDropdown = false.obs;
  final RxString searchDropdownErrorMessage = ''.obs;

  // property search results
  final RxBool isLoadingSearchResults = false.obs;
  final RxString searchResultsErrorMessage = ''.obs;
  final Rxn<SearchPropertyResponse> searchResponse = Rxn<SearchPropertyResponse>();
  final RxList<Property> searchResults = <Property>[].obs;
  
  // selected options
  final Rx<PropertyOption?> selectedPropertyOption = Rx<PropertyOption?>(null);
  final Rx<PropertyType?> selectedPropertyType = Rx<PropertyType?>(null);
  final Rx<PropertyLocation?> selectedPropertyLocation =
      Rx<PropertyLocation?>(null);
  final Rx<PropertyBedsBath?> selectedBedsBath = Rx<PropertyBedsBath?>(null);
  final Rx<PropertyRangePrice?> selectedPriceRange = Rx<PropertyRangePrice?>(null);

  // Getters with null safety
  List<PropertyOption> get propertyOptions => 
      searchDropdownResponse.value?.data?.propertyOptions ?? [];
  
  List<PropertyType> get propertyTypes => 
      searchDropdownResponse.value?.data?.propertyTypes ?? [];
  
  List<PropertyLocation> get propertyLocations => 
      searchDropdownResponse.value?.data?.propertyLocations ?? [];
  
  List<PropertyBedsBath> get propertyBedsBaths => 
      searchDropdownResponse.value?.data?.propertyBedsBaths ?? [];
  
  List<PropertyRangePrice> get propertyPrices => 
      searchDropdownResponse.value?.data?.propertyPrices ?? [];

  @override
  void onInit() {
    super.onInit();
    fetchSearchDropdown();
  }

  // Fetch search dropdown data
  Future<void> fetchSearchDropdown() async {
    try {
      debugPrint(
          '🔄 [fetchSearchDropdown] Initiating search dropdown fetch...');
      isLoadingSearchDropdown(true);
      searchDropdownErrorMessage('');

      final response = await apiService.getSearchDropDown();

      debugPrint(
          '✅ [fetchSearchDropdown] API call completed. Status: ${response.statusCode}');
      debugPrint('📦 [fetchSearchDropdown] Response data: ${response.data}');
      if (response.data != null && response.data['data'] != null) {
  debugPrint('🔑 Available keys in data: ${response.data['data'].keys.toList()}');
}

      if (response.statusCode == 200) {
        if (response.data == null) {
          debugPrint('❌ Response data is null');
          searchDropdownErrorMessage('No data received from server');
          handleSearchDropdownError();
          return;
        }

        debugPrint('📥 [fetchSearchDropdown] Parsing response data...');
        
        try {
          final dropdownData = SearchDropdownResponse.fromJson(response.data);
          searchDropdownResponse.value = dropdownData;
          
          debugPrint('✅ Successfully parsed dropdown data');
          debugPrint('📊 Dropdown counts:');
          debugPrint('  Property Options: ${propertyOptions.length}');
          debugPrint('  Property Types: ${propertyTypes.length}');
          debugPrint('  Property Locations: ${propertyLocations.length}');
          debugPrint('  Beds/Bath: ${propertyBedsBaths.length}');
          debugPrint('  Price Range: ${propertyPrices.length}');

          // Set initial selections only if we have data
          if (dropdownData.data != null) {
            setInitialSelections();
          }
        } catch (parseError, stackTrace) {
          debugPrint('❌ Error parsing response: $parseError');
          debugPrint('📝 Stack trace: $stackTrace');
          searchDropdownErrorMessage('Error parsing server response');
          handleSearchDropdownError();
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to load search dropdown: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ [fetchSearchDropdown] DioException: ${e.message}');
      searchDropdownErrorMessage(parseDioError(e));
      handleSearchDropdownError();
    } catch (e, stackTrace) {
      debugPrint('‼️ [fetchSearchDropdown] Unexpected error: $e');
      debugPrint('📝 Stack trace: $stackTrace');
      searchDropdownErrorMessage('Unexpected error: ${e.toString()}');
      handleSearchDropdownError();
    } finally {
      isLoadingSearchDropdown(false);
    }
  }

  // Search for properties
  Future<void> searchProperties() async {
    if (!isFormComplete) {
      debugPrint('❌ [searchProperties] Form is not complete');
      Get.snackbar(
        'Incomplete Form',
        'Please select all required fields before searching',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      debugPrint('🔍 [searchProperties] Initiating property search...');
      isLoadingSearchResults(true);
      searchResultsErrorMessage('');
      
      // Create the search request using the correct field names
      final searchRequest = PropertySearchResultRequest(
        propertyOptions: selectedPropertyOption.value?.id ?? 0,
        propertyTypes: selectedPropertyType.value?.id ?? 0,
        propertyLocations: selectedPropertyLocation.value?.id ?? 0,
        propertyBedsBath: selectedBedsBath.value?.id ?? 0,
        propertyPriceForSearch: selectedPriceRange.value?.id ?? 0,
      );

      debugPrint('📤 [searchProperties] Search request: ${searchRequest.toJson()}');

      final response = await apiService.getPropertySearchResult(searchRequest);

      debugPrint(
          '✅ [searchProperties] API call completed. Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.data == null) {
          debugPrint('❌ Response data is null');
          searchResultsErrorMessage('No data received from server');
          handleSearchResultsError('No data received from server');
          return;
        }

        debugPrint('📥 [searchProperties] Parsing search results...');
        
        try {
          final searchResultsData = SearchPropertyResponse.fromJson(response.data);
          searchResponse.value = searchResultsData;
          
          // Update the search results list
          if (searchResultsData.data != null && searchResultsData.data!.isNotEmpty) {
            searchResults.value = searchResultsData.data!;
            debugPrint('🏠 [searchProperties] Found ${searchResults.length} properties');
            
            Get.snackbar(
              'Search Complete',
              'Found ${searchResults.length} properties',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );
          } else {
            searchResults.clear();
            debugPrint('📭 No properties found');
            Get.snackbar(
              'No Results',
              'No properties found matching your criteria',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.blue,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );
          }
        } catch (parseError, stackTrace) {
          debugPrint('❌ Error parsing search results: $parseError');
          debugPrint('📝 Stack trace: $stackTrace');
          searchResultsErrorMessage('Error parsing search results');
          handleSearchResultsError('Error parsing search results');
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to search properties: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ [searchProperties] DioException: ${e.message}');
      final errorMessage = parseDioError(e);
      searchResultsErrorMessage(errorMessage);
      handleSearchResultsError(errorMessage);
    } catch (e, stackTrace) {
      debugPrint('‼️ [searchProperties] Unexpected error: $e');
      debugPrint('📝 Stack trace: $stackTrace');
      final errorMessage = 'Unexpected error: ${e.toString()}';
      searchResultsErrorMessage(errorMessage);
      handleSearchResultsError(errorMessage);
    } finally {
      isLoadingSearchResults(false);
    }
  }

  void handleSearchResultsError(String errorMessage) {
    searchResults.clear();
    Get.snackbar(
      'Search Error',
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void setInitialSelections() {
    final data = searchDropdownResponse.value?.data;
    if (data == null) {
      debugPrint('⚠️ Cannot set initial selections - data is null');
      return;
    }

    // Only set initial values if they haven't been set before
    if (selectedPropertyOption.value == null && propertyOptions.isNotEmpty) {
      selectedPropertyOption.value = propertyOptions.first;
      debugPrint('📌 Set initial property option: ${propertyOptions.first.name.en}');
    }
    if (selectedPropertyType.value == null && propertyTypes.isNotEmpty) {
      selectedPropertyType.value = propertyTypes.first;
      debugPrint('📌 Set initial property type: ${propertyTypes.first.name.en}');
    }
    if (selectedPropertyLocation.value == null && propertyLocations.isNotEmpty) {
      selectedPropertyLocation.value = propertyLocations.first;
      debugPrint('📌 Set initial property location: ${propertyLocations.first.name.en}');
    }
    
    // Optional fields - only set if available
    if (selectedBedsBath.value == null && propertyBedsBaths.isNotEmpty) {
      selectedBedsBath.value = propertyBedsBaths.first;
      debugPrint('📌 Set initial beds/bath: ${propertyBedsBaths.first.name.en}');
    } else if (propertyBedsBaths.isEmpty) {
      debugPrint('ℹ️ Beds/Bath options not available - will be optional');
    }
    
    if (selectedPriceRange.value == null && propertyPrices.isNotEmpty) {
      selectedPriceRange.value = propertyPrices.first;
      debugPrint('📌 Set initial price range: ${propertyPrices.first.name.en}');
    } else if (propertyPrices.isEmpty) {
      debugPrint('ℹ️ Price range options not available - will be optional');
    }
  }

  void handleSearchDropdownError() {
    searchDropdownResponse.value = null;
    clearSelections();
  }

  void clearSelections() {
    selectedPropertyOption.value = null;
    selectedPropertyType.value = null;
    selectedPropertyLocation.value = null;
    selectedBedsBath.value = null;
    selectedPriceRange.value = null;
    searchResults.clear();
    searchResponse.value = null;
    searchResultsErrorMessage('');
    debugPrint('🧹 All selections and results cleared');
  }

  // Selection methods
  void selectPropertyOption(PropertyOption? option) {
    debugPrint(
        '✅ Selected property option: ${option?.name.en} (ID: ${option?.id})');
    selectedPropertyOption.value = option;
  }

  void selectPropertyType(PropertyType? type) {
    debugPrint('✅ Selected property type: ${type?.name.en} (ID: ${type?.id})');
    selectedPropertyType.value = type;
  }

  void selectPropertyLocation(PropertyLocation? location) {
    debugPrint(
        '✅ Selected property location: ${location?.name.en} (ID: ${location?.id})');
    selectedPropertyLocation.value = location;
  }

  void selectBedsBath(PropertyBedsBath? bedsBath) {
    debugPrint(
        '✅ Selected beds/bath: ${bedsBath?.name.en} (ID: ${bedsBath?.id})');
    selectedBedsBath.value = bedsBath;
  }

  void selectPriceRange(PropertyRangePrice? priceRange) {
    debugPrint(
        '✅ Selected price range: ${priceRange?.name.en} (ID: ${priceRange?.id})');
    selectedPriceRange.value = priceRange;
  }

  // Check if all required fields are selected
  // Only property option, type, and location are required
  // Beds/bath and price range are optional
  bool get isFormComplete {
    final complete = selectedPropertyOption.value != null &&
        selectedPropertyType.value != null &&
        selectedPropertyLocation.value != null;
    
    if (!complete) {
      debugPrint('⚠️ Form incomplete:');
      debugPrint('  Property Option: ${selectedPropertyOption.value != null}');
      debugPrint('  Property Type: ${selectedPropertyType.value != null}');
      debugPrint('  Property Location: ${selectedPropertyLocation.value != null}');
    } else {
      debugPrint('✅ Form is complete');
      debugPrint('  Beds/Bath (optional): ${selectedBedsBath.value != null}');
      debugPrint('  Price Range (optional): ${selectedPriceRange.value != null}');
    }
    
    return complete;
  }

  // Check if search results are available
  bool get hasSearchResults => searchResults.isNotEmpty;

  // Get search results count
  int get searchResultsCount => searchResults.length;

  // Get search success status
  bool get searchSuccess => searchResponse.value?.success ?? false;

  // Helper methods to get property details
  String getPropertyTitle(Property property, {bool useArabic = false}) {
    return useArabic 
        ? (property.title?.ar ?? property.title?.en ?? 'No Title')
        : (property.title?.en ?? property.title?.ar ?? 'No Title');
  }

  String getPropertyLocation(Property property, {bool useArabic = false}) {
    return useArabic
        ? (property.location?.ar ?? property.location?.en ?? 'No Location')
        : (property.location?.en ?? property.location?.ar ?? 'No Location');
  }

  String getPropertyType(Property property, {bool useArabic = false}) {
    return useArabic
        ? (property.type?.ar ?? property.type?.en ?? 'No Type')
        : (property.type?.en ?? property.type?.ar ?? 'No Type');
  }

  String getFormattedPrice(Property property, {bool useArabic = false}) {
    return useArabic
        ? (property.price?.formatted?.ar ?? property.price?.formatted?.en ?? 'Price not available')
        : (property.price?.formatted?.en ?? property.price?.formatted?.ar ?? 'Price not available');
  }

  String getPropertyArea(Property property, {bool useArabic = false}) {
    return useArabic
        ? (property.specs?.area?.ar ?? property.specs?.area?.en ?? 'Area not specified')
        : (property.specs?.area?.en ?? property.specs?.area?.ar ?? 'Area not specified');
  }

  // refresh data
  Future<void> refreshSearchDropdown() async {
    await fetchSearchDropdown();
  }

  // Clear search results
  void clearSearchResults() {
    searchResults.clear();
    searchResponse.value = null;
    searchResultsErrorMessage('');
    debugPrint('🧹 Search results cleared');
  }

  // Retry search
  Future<void> retrySearch() async {
    await searchProperties();
  }
}