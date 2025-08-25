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

      if (response.statusCode == 200) {
        debugPrint('📥 [fetchSearchDropdown] Parsing response data...');
        final dropdownData = SearchDropdownResponse.fromJson(response.data);
        searchDropdownResponse.value = dropdownData;
        debugPrint('📍 [fetchSearchDropdown] Received dropdown data');

        // Set initial selections
        setInitialSelections();
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
      );

      debugPrint('📤 [searchProperties] Search request: ${searchRequest.toJson()}');

      final response = await apiService.getPropertySearchResult(searchRequest);

      debugPrint(
          '✅ [searchProperties] API call completed. Status: ${response.statusCode}');
      debugPrint('📦 [searchProperties] Response data: ${response.data}');

      if (response.statusCode == 200) {
        debugPrint('📥 [searchProperties] Parsing search results...');
        
        // Parse the response using your SearchPropertyResponse model
        final searchResultsData = SearchPropertyResponse.fromJson(response.data);
        searchResponse.value = searchResultsData;
        
        // Update the search results list
        if (searchResultsData.data != null) {
          searchResults.value = searchResultsData.data!;
          debugPrint('🏠 [searchProperties] Found ${searchResults.length} properties');
          
          // Show success message
          if (searchResults.isNotEmpty) {
            Get.snackbar(
              'Search Complete',
              'Found ${searchResults.length} properties',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          } else {
            Get.snackbar(
              'No Results',
              'No properties found matching your criteria',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.blue,
              colorText: Colors.white,
            );
          }
        } else {
          searchResults.clear();
          Get.snackbar(
            'No Results',
            'No properties found matching your criteria',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blue,
            colorText: Colors.white,
          );
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
    );
  }

  void setInitialSelections() {
    final data = searchDropdownResponse.value?.data;
    if (data == null) return;

    // Only set initial values if they haven't been set before
    if (selectedPropertyOption.value == null &&
        data.propertyOptions.isNotEmpty) {
      selectedPropertyOption.value = data.propertyOptions.first;
    }
    if (selectedPropertyType.value == null && data.propertyTypes.isNotEmpty) {
      selectedPropertyType.value = data.propertyTypes.first;
    }
    if (selectedPropertyLocation.value == null &&
        data.propertyLocations.isNotEmpty) {
      selectedPropertyLocation.value = data.propertyLocations.first;
    }
    if (selectedBedsBath.value == null && data.propertyBedsBaths.isNotEmpty) {
      selectedBedsBath.value = data.propertyBedsBaths.first;
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
    // Also clear search results when clearing selections
    searchResults.clear();
    searchResponse.value = null;
    searchResultsErrorMessage('');
  }

  // Selection methods
  void selectPropertyOption(PropertyOption? option) {
    debugPrint(
        'Selected property option: ${option?.name.en} (ID: ${option?.id})');
    selectedPropertyOption.value = option;
  }

  void selectPropertyType(PropertyType? type) {
    debugPrint('Selected property type: ${type?.name.en} (ID: ${type?.id})');
    selectedPropertyType.value = type;
  }

  void selectPropertyLocation(PropertyLocation? location) {
    debugPrint(
        'Selected property location: ${location?.name.en} (ID: ${location?.id})');
    selectedPropertyLocation.value = location;
  }

  void selectBedsBath(PropertyBedsBath? bedsBath) {
    debugPrint(
        'Selected property bed & bath: ${bedsBath?.name.en} (ID: ${bedsBath?.id})');
    selectedBedsBath.value = bedsBath;
  }

  // Check if all required fields are selected
  bool get isFormComplete {
    return selectedPropertyOption.value != null &&
        selectedPropertyType.value != null &&
        selectedPropertyLocation.value != null &&
        selectedBedsBath.value != null;
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
  }

  // Retry search
  Future<void> retrySearch() async {
    await searchProperties();
  }
}