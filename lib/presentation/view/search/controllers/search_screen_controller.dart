import 'package:dar_al_safwa/core/utils/data_utlis.dart';
import 'package:dar_al_safwa/data/model/search_dropdown_model.dart';
import 'package:dar_al_safwa/data/repositories/api_services.dart';
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

  // refresh data
  Future<void> refreshSearchDropdown() async {
    await fetchSearchDropdown();
  }
}
