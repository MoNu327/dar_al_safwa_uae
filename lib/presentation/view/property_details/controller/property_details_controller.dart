import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:dar_al_safwa/data/repositories/api_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/model/property_details_model.dart';

class PropertyDetailsController extends GetxController {
  var propertyOverView = <Map<String, dynamic>>[].obs;
  var featuresAndAmenities = <Map<String, dynamic>>[].obs;
  var regulatoryInfo = <Map<String, String>>[].obs;
  var nearbyLocations = <Map<String, dynamic>>[].obs;
  var idParams = 1.obs;
  final ApiService apiService = ApiService();
  final isLoading = false.obs;
  final property = Rx<Property?>(null);
  final errorMessage = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    loadPropertyOverView();
    loadFeaturesAndAmenities();
    loadRegulatoryInfo();
    loadNearbyLocations();
    // Get the property ID from arguments when controller initializes

    final arguments = Get.arguments;
    if (arguments != null && arguments['propertyId'] != null) {
      idParams.value = arguments['propertyId'];
      debugPrint(idParams.value.toString());
      fetchPropertyDetails(idParams.value);
    } else {
      fetchPropertyDetails(1);
    }
  }

  Future<void> fetchPropertyDetails(int propertyId) async {
    try {
      isLoading(true);
      errorMessage(null);

      debugPrint('Fetching property details for ID: $propertyId');
      final response = await apiService.getPropertyDetails(propertyId);
      debugPrint('🎉 API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final propertyResponse = PropertyResponse.fromJson(response.data);
        debugPrint("🔔 property response: ${propertyResponse.data?.property}");
        property(propertyResponse.data?.property);
        debugPrint(
            '👌 Property loaded successfully: ${propertyResponse.data?.property?.description?.en}');
      } else {
        debugPrint(
            '😔 Failed to load property details: ${response.statusMessage}');
        throw Exception("Failed to load property details");
      }
    } catch (e) {
      debugPrint('😔 Error in fetchPropertyDetails: $e');
      errorMessage(e.toString());
      // Get.snackbar(
      //   "Error",
      //   "Failed to fetch property details: ${e.toString()}",
      //   snackPosition: SnackPosition.BOTTOM,
      // );
    } finally {
      isLoading(false);
      debugPrint('fetchPropertyDetails completed');
    }
  }

  // Helper method to get localized property title
  String getPropertyTitle() {
    return property.value?.title?.en ?? property.value?.title?.ar ?? 'No Title';
  }

  // Helper method to get localized property description
  String getPropertyDescription() {
    return property.value?.description?.en ??
        property.value?.description?.ar ??
        'No Description Available';
  }

  final RxList<String> imageUrls = [
    "https://i.postimg.cc/5tSKgkpL/CAB-BUILDING.jpg",
    "https://i.postimg.cc/VLsMps1J/apartment1.jpg",
    "https://i.postimg.cc/mgJHPQ99/villa8.jpg",
    "https://i.postimg.cc/xTq8LXn3/Frame2.png",
    "https://i.postimg.cc/Px2fwj77/apartment6.jpg",
    "https://i.postimg.cc/TPcfzxTP/Frame.png",
    "https://i.postimg.cc/gjxpL68w/Jaffnain-Villa.jpg",
    "https://i.postimg.cc/QdGDVCtt/apartment8.jpg",
    "https://i.postimg.cc/QMjrkzcZ/Ghala-Tower.jpg"
  ].obs;

  final RxInt currentIndex = 0.obs;

  void changeImage(int index) {
    currentIndex.value = index;
  }

  // Load the property overview data
  void loadPropertyOverView() {
    List<Map<String, dynamic>> dummyJosn = [
      {
        'id': '1111',
        'type': 'Apartment',
        'garages': 1,
        'bedrooms': 2,
        'bathrooms': 1,
        'size': 1200,
        'builtYear': 2015,
        'hasBalcony': true,
      }
    ];

    propertyOverView.value = dummyJosn;
  }

  // Load the features and amenities data
  void loadFeaturesAndAmenities() {
    List<Map<String, dynamic>> dummyFeaturesJson = [
      {"name": "Jacuzzi", "icon": "bathtub"},
      {"name": "Sauna", "icon": "spa"},
      {"name": "AC", "icon": "ac_unit"},
      {"name": "Storage Area", "icon": "storage"},
      {"name": "Lobby ", "icon": "business_center"},
    ];

    featuresAndAmenities.value = dummyFeaturesJson;
  }

  // Load the regulatory information data
  void loadRegulatoryInfo() {
    List<Map<String, String>> dummyRegulatoryJson = [
      {
        "title": "Permit Number",
        "value": "71511701852",
      },
      {
        "title": "DED",
        "value": "123456789",
      },
      {
        "title": "RERA",
        "value": "RERA-001234",
      },
      {
        "title": "BRN",
        "value": "BRN-09876",
      },
    ];

    regulatoryInfo.value = dummyRegulatoryJson;
  }

  // Load the nearby locations data
  void loadNearbyLocations() {
    List<Map<String, dynamic>> dummyNearbyLocationsJson = [
      {"name": "School", "icon": "school", "distance": 2.5},
      {"name": "Hospital", "icon": "local_hospital", "distance": 3.8},
      {"name": "Park", "icon": "park", "distance": 1.2},
      {"name": "Restaurant", "icon": "restaurant", "distance": 0.8},
      {"name": "Airport", "icon": "airplanemode_active", "distance": 15.4},
    ];

    nearbyLocations.value = dummyNearbyLocationsJson;
  }

  Future<void> callToAgent(String phoneNumber) async {
    try {
      // Validate and clean the phone number
      final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

      if (cleanedNumber.isEmpty) {
        throw Exception('Invalid phone number');
      }

      final Uri phoneUri = Uri.parse('tel:$cleanedNumber');

      if (!await canLaunchUrl(phoneUri)) {
        throw Exception('Could not launch phone dialer');
      }

      await launchUrl(phoneUri);
    } catch (e) {
      debugPrint('Error launching phone call: $e');
      // Consider showing a user-friendly error message
      Get.snackbar(
        'Call Failed',
        'Could not initiate the phone call. Please check the phone number.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // methods for navigate
  void navigateToBack() {
    Get.back();
  }

// In your PropertyDetailsController
  void navigateToAgentChat(String agentEmail, String? propertyId) {
    Get.toNamed(
      AppRoute.agent,
      arguments: {
        'email': agentEmail,
        'propertyId': propertyId ?? "Riverview Retreat",
      }, // Pass the agent's email as argument
    );
  }
}
