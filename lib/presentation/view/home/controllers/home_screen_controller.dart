import 'package:majan/data/model/featured_properties_model.dart';
import 'package:majan/data/model/location_dropdown_model.dart';
import 'package:majan/data/model/popular_properties_model.dart';
import 'package:majan/data/repositories/api_services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../core/routes/app_route.dart';
import '../../../../core/utils/data_utlis.dart';
import '../../../../data/model/property_banner_model.dart';

class HomeScreenController extends GetxController {
  final ApiService apiService = ApiService();
  final GetStorage storage = GetStorage();

  // location drop down widget
  final Rxn<LocationDropdownResponse> locationResponse =
      Rxn<LocationDropdownResponse>();
  final RxList<LocationDropdownModel> locations = <LocationDropdownModel>[].obs;
  final Rx<LocationItem?> selectedLocation = Rx<LocationItem?>(null);
  final RxBool isLoadingLocations = false.obs;
  final RxString locationErrorMessage = ''.obs;

  // property banners
  final Rxn<PropertyBannerResponse> banners = Rxn<PropertyBannerResponse>();
  // final RxBool isLoadingBanners = false.obs;
  final RxString errorMessage = ''.obs;

  // featured property
  final Rxn<FeaturedPropertiesResponse> featuredProperties =
      Rxn<FeaturedPropertiesResponse>();
  // final RxBool isLoadingFeatured = false.obs;
  final RxString featuredErrorMessage = ''.obs;

  // popular properties
  final Rxn<PopularPropertiesResponse> popularProperties =
      Rxn<PopularPropertiesResponse>();
  // final RxBool isLoadingPopular = false.obs;
  final RxString popularErrorMessage = ''.obs;

  // common loader
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    initializeData();
  }

  Future<void> initializeData() async {
    try {
      isLoading(true);

      await Future.wait([
        fetchLocations(),
        fetchPropertyBanners(),
        fetchFeaturedProperties(),
        fetchPopularProperties(),
      ]);
    } catch (e) {
      Get.offAllNamed(AppRoute.error);
      debugPrint("Failed: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> refreshAll() async {
    try {
      isLoading(true);

      await Future.wait([
        fetchLocations(),
        fetchPropertyBanners(),
        fetchFeaturedProperties(),
        fetchPopularProperties()
      ]);

      // Get.snackbar('Success', 'Data refreshed successfully',
      //     snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.offAllNamed(AppRoute.error);
      debugPrint("Refresh failed: $e");
      Get.snackbar('Error', 'Failed to refresh data',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading(false);
    }
  }

  // fetch locations
  Future<void> fetchLocations() async {
    try {
      debugPrint('🔄 [fetchLocations] Initiating locations fetch...');
      isLoadingLocations(true);
      locationErrorMessage('');

      final response = await apiService.getLocations();
      debugPrint(
          '✅ [fetchLocations] API call completed. Status: ${response.statusCode}');
      debugPrint('📦 [fetchLocations] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final locationData = LocationDropdownResponse.fromJson(response.data);
        locationResponse.value = locationData;
        locations.assignAll(locationData.data ?? []);
        debugPrint('📍 [fetchLocations] Locations list: $locations');

        // Set initial selected location
        _setInitialSelectedLocation();

        debugPrint(
            '📊 [fetchLocations] Received ${locations.length} locations');
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to load locations: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ [fetchLocations] Error: $e');
      locationErrorMessage('Unexpected error: ${e.toString()}');
      _handleLocationError();
    } finally {
      isLoadingLocations(false);
    }
  }

  void _setInitialSelectedLocation() {
    if (locations.isEmpty) return;

    final savedLocationId = storage.read<int>('currentSelectedLocId');
    final currentLanguage = Get.locale?.languageCode ?? 'en';

    selectedLocation.value = savedLocationId != null
        ? LocationItem.fromLocationModel(
            locations.firstWhereOrNull((loc) => loc.id == savedLocationId) ??
                locations.first,
            currentLanguage,
          )
        : LocationItem.fromLocationModel(locations.first, currentLanguage);
  }

  void _handleLocationError() {
    locations.clear();
    selectedLocation.value = null;
  }

  void changeLocation(LocationDropdownModel? newLocation) {
    if (newLocation != null) {
      final currentLanguage = Get.locale?.languageCode ?? 'en';
      selectedLocation.value =
          LocationItem.fromLocationModel(newLocation, currentLanguage);
      storage.write('currentSelectedLocId', newLocation.id);
    }
  }

  // Fetch Property Banners
  // Future<void> fetchPropertyBanners() async {
  //   try {
  //     debugPrint('🔄 [fetchPropertyBanners] Initiating banner fetch...');
  //     // isLoadingBanners(true);
  //     errorMessage('');

  //     final response = await apiService.getPropertyBanner();
  //     debugPrint(
  //         '✅ [fetchPropertyBanners] API call completed. Status: ${response.statusCode}');

  //     if (response.statusCode == 200) {
  //       debugPrint('📦 [fetchPropertyBanners] Parsing response data...');
  //       banners.value = PropertyBannerResponse.fromJson(response.data);
  //       debugPrint(
  //           '📊 [fetchPropertyBanners] Received banners: ${(banners.value)?.toJson()}');
  //     } else {
  //       debugPrint('📄 Full banner response: ${response.data}');
  //       debugPrint(
  //           '❌ [fetchPropertyBanners] API error: Status ${response.statusCode}');
  //       debugPrint('📄 Response body: ${response.data}');
  //       throw DioException(
  //         requestOptions: response.requestOptions,
  //         response: response,
  //         error: 'Failed to load banners: ${response.statusCode}',
  //       );
  //     }
  //   } on DioException catch (e) {
  //     debugPrint('🚨 [fetchPropertyBanners] DioException caught: ${e.type}');
  //     debugPrint('📌 Error details: ${e.message}');
  //     if (e.response != null) {
  //       debugPrint('⚡ Response status: ${e.response?.statusCode}');
  //       debugPrint('📄 Response data: ${e.response?.data}');
  //     }
  //     errorMessage(parseDioError(e));
  //     banners.value = null;
  //     rethrow;
  //   } catch (e, stackTrace) {
  //     debugPrint('‼️ [fetchPropertyBanners] Unexpected error: ${e.toString()}');
  //     debugPrint('📝 Stack trace: $stackTrace');
  //     errorMessage('Unexpected error: ${e.toString()}');
  //     banners.value = null;
  //     rethrow;
  //   } finally {
  //     debugPrint(
  //         '🏁 [fetchPropertyBanners] Fetch completed. Loading state: false');
  //     // isLoadingBanners(false);
  //   }
  // }

  Future<void> fetchPropertyBanners() async {
  try {
    debugPrint('🔄 [fetchPropertyBanners] Initiating banner fetch...');
    errorMessage('');

    final response = await apiService.getPropertyBanner();
    debugPrint(
        '✅ [fetchPropertyBanners] API call completed. Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      banners.value = PropertyBannerResponse.fromJson(response.data);
      debugPrint('📊 [fetchPropertyBanners] Received banners: ${(banners.value)?.toJson()}');
    } else if (response.statusCode == 404) {
      // No banners found - handle gracefully
      banners.value = PropertyBannerResponse(data: []);
      debugPrint('⚡ No banners found. Showing empty state.');
    } else {
      debugPrint('📄 Full banner response: ${response.data}');
      debugPrint('❌ [fetchPropertyBanners] API error: Status ${response.statusCode}');
      errorMessage('Failed to load banners: ${response.statusCode}');
    }
  } on DioException catch (e) {
    debugPrint('🚨 [fetchPropertyBanners] DioException caught: ${e.type}');
    debugPrint('📌 Error details: ${e.message}');
    if (e.response != null) {
      debugPrint('⚡ Response status: ${e.response?.statusCode}');
      debugPrint('📄 Response data: ${e.response?.data}');
    }
    errorMessage(parseDioError(e));
    banners.value = null;
  } catch (e, stackTrace) {
    debugPrint('‼️ [fetchPropertyBanners] Unexpected error: ${e.toString()}');
    debugPrint('📝 Stack trace: $stackTrace');
    errorMessage('Unexpected error: ${e.toString()}');
    banners.value = null;
  } finally {
    debugPrint('🏁 [fetchPropertyBanners] Fetch completed. Loading state: false');
  }
}


  // fetch featured properties
  Future<void> fetchFeaturedProperties() async {
    try {
      debugPrint('🔄 [fetchFeaturedProperties] Initiating fetch...');
      // isLoadingFeatured(true);
      featuredErrorMessage('');

      final response = await apiService.getFeaturedProperties();
      debugPrint(
          '✅ [fetchFeaturedProperties] API call completed. Status: ${response.statusCode}');
      print(
          "✅ [fetchFeaturedProperties] API call completed. Status: ${response.statusCode}");
      debugPrint(
          '📦 [fetchFeaturedProperties] Raw response data: ${response.data}');

      if (response.statusCode == 200) {
        featuredProperties.value =
            FeaturedPropertiesResponse.fromJson(response.data);
        debugPrint('Featured properties : ${featuredProperties.value}');
        debugPrint(
            '🏠 [fetchFeaturedProperties] Received ${featuredProperties.value?.data?.length ?? 0} properties');
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to load featured properties: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ [fetchFeaturedProperties] DioException: ${e.message}');
      featuredErrorMessage(parseDioError(e));
      featuredProperties.value = null;
    } catch (e, stackTrace) {
      debugPrint('‼️ [fetchFeaturedProperties] Unexpected error: $e');
      debugPrint('📝 Stack trace: $stackTrace');
      featuredErrorMessage('Unexpected error: ${e.toString()}');
      featuredProperties.value = null;
    } finally {
      // isLoadingFeatured(false);
    }
  }



  // fetch popular properties
  Future<void> fetchPopularProperties() async {
    try {
      debugPrint('🔄 [fetchPopularProperties] Initiating fetch...');
      // isLoadingPopular(true);
      popularErrorMessage('');

      final response = await apiService.getPopularProperties();

      debugPrint(
          '✅ [fetchPopularProperties] API call completed. Status: ${response.statusCode}');

      debugPrint(
          '📦 [fetchPopularProperties] Raw response data: ${response.data}');

      if (response.statusCode == 200) {
        popularProperties.value =
            PopularPropertiesResponse.fromJson(response.data);
        debugPrint('Popular properties : ${popularProperties.value}');
        debugPrint(
            '🏠 [fetchPopularProperties] Received ${popularProperties.value?.data?.length ?? "0"} properties');
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to load popular properties: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ [fetchPopularProperties] DioException: ${e.message}');
      popularErrorMessage(parseDioError(e));
      popularProperties.value = null;
    } catch (e, stackTrace) {
      debugPrint('‼️ [fetchPopularProperties] Unexpected error: $e');
      debugPrint('📝 Stack trace: $stackTrace');
      popularErrorMessage('Unexpected error: ${e.toString()}');
      popularProperties.value = null;
    } finally {
      // isLoadingPopular(false);
    }
  }

  // Refresh data (pull-to-refresh)
  Future<void> refreshBanners() async {
    await fetchPropertyBanners();
  }
}

// Location model class
class LocationItem {
  final int id;
  final String name;

  LocationItem({
    required this.id,
    required this.name,
  });

  factory LocationItem.fromLocationModel(
      LocationDropdownModel model, String languageCode) {
    return LocationItem(
      id: model.id ?? 0,
      name: model.getName(languageCode),
    );
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
