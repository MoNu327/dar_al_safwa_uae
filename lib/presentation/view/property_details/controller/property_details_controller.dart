import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:dar_al_safwa/data/repositories/api_services.dart';
import 'package:dar_al_safwa/presentation/view/home/screens/home_screen.dart';
import 'package:dar_al_safwa/presentation/widgets/bottom_navbar_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/model/property_details_model.dart';
import '../../addmobilenumber/addmobilenumber.dart';

class PropertyDetailsController extends GetxController {
  var propertyOverView = <Map<String, dynamic>>[].obs;
  var featuresAndAmenities = <Map<String, dynamic>>[].obs;
  var regulatoryInfo = <Map<String, String>>[].obs;
  var nearbyLocations = <Map<String, dynamic>>[].obs;
  var idParams = 0.obs;
  final ApiService apiService = ApiService();
  final isLoading = false.obs;
  final property = Rx<Property?>(null);
  final errorMessage = Rx<String?>(null);

  // Bottom sheet state variables
  final RxInt selectedUnitTypeIndex = (-1).obs;
  final RxInt selectedCount = 1.obs;
  final RxBool isBottomSheetForCall = false.obs;

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
      debugPrint("Id from Params ${arguments['propertyId'].toString()}");
      idParams.value = arguments['propertyId'];
      debugPrint("Id from Params ${idParams.value.toString()}");
      fetchPropertyDetails(idParams.value);
    } else {
      debugPrint("Else Id from Params ${idParams.value.toString()}");
      fetchPropertyDetails(idParams.value);
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
            '👌 Property loaded successfully: ${propertyResponse.data?.property
                ?.description?.en}');
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

  Future postPropertyInterest(
      String propertyId,
      int unitType,
      int count,
      String comments,
      int enqtype,
      String mobileNumber, {
        String? unitId,
        String? propertyName,
        String? agentEmail,
      }) async {
    try {
      isLoading(true);
      errorMessage(null);

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final propertyIdParsed = int.tryParse(propertyId) ?? 0;

      final isFirstTime = await isFirstTimeUser(uid);
      if ((mobileNumber.isEmpty || mobileNumber.trim() == "") && isFirstTime) {
        debugPrint('⚠️ Mobile number missing for first-time user. Redirecting...');

        Get.snackbar(
          "Mobile Number Required",
          "Please update your mobile number to continue.",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );

        final result = await Get.to(() => MobileNumberUpdatePage(
          phone: mobileNumber,
          propertyId: propertyId,
          navigateToChat: true,
          navigateToCall: false,
          unitId: unitId,
          propertyName: propertyName,
          agentEmail: agentEmail,
        ));

        if (result != null) {
          if (result['navigateToChat'] == true) {
            navigateToAgentChat(
              result['agentEmail'] ?? "",
              result['propertyId'],
              result['propertyName'],
              result['unitId'],
            );
          } else if (result['navigateToCall'] == true) {
            await callToAgent(result['phone']);
          }
        }

        // ✅ Prevent proceeding with interest post after redirect
        return;
      }

      // 🔍 Log
      debugPrint('✅ Submitting property interest...');
      debugPrint('📞 Mobile: $mobileNumber');

      final response = await apiService.postPropertyInterest(
        uid,
        propertyIdParsed,
        unitType,
        count,
        comments,
        enqtype,
        mobileNumber,
      );

      debugPrint('🎉 API response status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Interest Posted");
      } else {
        throw Exception("Failed to post interest");
      }
    } catch (e) {
      debugPrint('❌ Error in Post Interest Details: $e');
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }


  Future<void> saveMobileNumber({
    required String mobile,
    required String phone,
    required String propertyId,
    String? unitId,
    String? propertyName,
    String? agentEmail,
    bool navigateToChat = false,
    bool navigateToCall = false,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (mobile.isEmpty || mobile.length < 10) {
      Get.snackbar("Invalid", "Please enter a valid mobile number");
      return;
    }

    try {
      isLoading.value = true;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'mobile': mobile,
      }, SetOptions(merge: true));

      Get.snackbar("Success", "Mobile number updated successfully");

      // ✅ Return all navigation context
      Get.back(result: {
        'mobile': mobile,
        'phone': phone,
        'propertyId': propertyId,
        'unitId': unitId,
        'propertyName': propertyName,
        'agentEmail': agentEmail,
        'navigateToChat': navigateToChat,
        'navigateToCall': navigateToCall,
      });

      await Future.delayed(const Duration(milliseconds: 300));

      // ☎️ Only call if navigateToCall is true
      if (navigateToCall) {
        await callToAgent(phone);
      }

    } catch (e) {
      Get.snackbar("Error", "Failed to update mobile number");
    } finally {
      isLoading.value = false;
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

  Future<bool> isFirstTimeUser(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) return true;

    final mobile = doc.data()?['mobile'] ?? '';
    return mobile
        .trim()
        .isEmpty;
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
    Get.to(BottomNavbarWidget());
  }

// In your PropertyDetailsController
  void navigateToAgentChat(String agentEmail, String? propertyId,
      String? propertyName, String? unitId) {
    Get.toNamed(
      AppRoute.agent,
      arguments: {
        'email': agentEmail,
        'propertyId': propertyId ?? "0",
        'propertyName': propertyName ?? "",
        'unitId': unitId ?? "0",
      }, // Pass the agent's email as argument
    );
  }

  // Bottom sheet methods
  void showUnitTypeBottomSheetForChat(String gmail, String propertyId,
      String propertyName) {
    final unitTypes = property.value?.unitTypes?.data ?? [];

    if (unitTypes.isEmpty) {
      Get.snackbar(
        "No Unit Types",
        "No unit types available for this property.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isBottomSheetForCall.value = false;
    selectedUnitTypeIndex.value = -1;
    selectedCount.value = 1;

    Get.bottomSheet(
      _buildUnitTypeBottomSheet(unitTypes, () {
        _handleUnitTypeSelectionForChat(gmail, propertyId, propertyName);
      }),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void showUnitTypeBottomSheetForCall(String phone, String propertyId) {
    final unitTypes = property.value?.unitTypes?.data ?? [];

    if (unitTypes.isEmpty) {
      Get.snackbar(
        "No Unit Types",
        "No unit types available for this property.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isBottomSheetForCall.value = true;
    selectedUnitTypeIndex.value = -1;
    selectedCount.value = 1;

    Get.bottomSheet(
      _buildUnitTypeBottomSheet(unitTypes, () {
        _handleUnitTypeSelectionForCall(phone, propertyId);
      }),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildUnitTypeBottomSheet(List<dynamic> unitTypes,
      VoidCallback onContinue) {
    return Container(
      height: Get.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() =>
                    Text(
                      isBottomSheetForCall.value
                          ? "Select Unit Type for Call"
                          : "Select Unit Type",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondaryColor,
                      ),
                    )),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Unit Type Selection
                  const Text(
                    "Choose Unit Type:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...unitTypes
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    final unitType = entry.value;
                    final title = unitType.unitType?.name?.en ?? "Unknown";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Obx(() =>
                          InkWell(
                            onTap: () {
                              selectedUnitTypeIndex.value = index;
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedUnitTypeIndex.value == index
                                      ? Colors.blue
                                      : Colors.grey[300]!,
                                  width: selectedUnitTypeIndex.value == index
                                      ? 2
                                      : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: selectedUnitTypeIndex.value == index
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selectedUnitTypeIndex.value == index
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: selectedUnitTypeIndex.value == index
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                        selectedUnitTypeIndex.value == index
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color:
                                        selectedUnitTypeIndex.value == index
                                            ? Colors.blue
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    );
                  }).toList(),

                  Obx(() =>
                  selectedUnitTypeIndex.value != -1
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const Text(
                        "Select Quantity:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(10, (index) {
                          final count = index + 1;
                          return Obx(() =>
                              InkWell(
                                onTap: () {
                                  selectedCount.value = count;
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: selectedCount.value == count
                                          ? Colors.blue
                                          : Colors.grey[300]!,
                                    ),
                                    borderRadius:
                                    BorderRadius.circular(20),
                                    color: selectedCount.value == count
                                        ? Colors.blue
                                        : Colors.white,
                                  ),
                                  child: Text(
                                    count.toString(),
                                    style: TextStyle(
                                      color: selectedCount.value == count
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight:
                                      selectedCount.value == count
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ));
                        }),
                      ),
                    ],
                  )
                      : const SizedBox()),
                ],
              ),
            ),
          ),

          // Bottom action button
          Obx(() =>
          selectedUnitTypeIndex.value != -1
              ? Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  onContinue();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth4),
                  ),
                ),
                child: Obx(() {
                  final selectedUnitType =
                  unitTypes[selectedUnitTypeIndex.value];
                  final unitTypeName =
                      selectedUnitType.unitType?.name?.en ?? 'Selection';
                  return Text(
                    isBottomSheetForCall.value
                        ? "Call Agent for $unitTypeName (${selectedCount
                        .value})"
                        : "Continue with $unitTypeName (${selectedCount
                        .value})",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          )
              : const SizedBox()),
        ],
      ),
    );
  }

  void _handleUnitTypeSelectionForChat(String gmail, String propertyId,
      String propertyName) async {
    try {
      final unitTypes = property.value?.unitTypes?.data ?? [];
      final selectedUnitType = unitTypes[selectedUnitTypeIndex.value];
      final unitTypeId = selectedUnitType.unitType?.id ?? 0;
      final unitTypeName = selectedUnitType.unitType?.name?.en ?? "";

      // Post property interest with enquiry type as 1 for chat
      await postPropertyInterest(
        propertyId,
        unitTypeId,
        selectedCount.value,
        "Interested in $unitTypeName", // Comments
        1, // Enquiry type set to 1 for chat
        "", // Mobile number - you can get from auth if needed
      );

      // Navigate to agent chat after successful API call

      navigateToAgentChat(gmail, propertyId, propertyName, unitTypeName);
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to submit interest: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _handleUnitTypeSelectionForCall(String phone, String propertyId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isFirstTime = await isFirstTimeUser(uid);

    final unitTypes = property.value?.unitTypes?.data ?? [];
    final selectedUnitType = unitTypes[selectedUnitTypeIndex.value];
    final unitTypeId = selectedUnitType.unitType?.id ?? 0;
    final unitTypeName = selectedUnitType.unitType?.name?.en ?? "";

    if (isFirstTime) {
      final result = await Get.to(() =>
          MobileNumberUpdatePage(
            phone: phone,
            propertyId: propertyId,
          ));

      if (result != null && result['mobile'] != null) {
        final updatedMobile = result['mobile'];

        // ⏬ Post interest after mobile updated
        await postPropertyInterest(
          propertyId,
          unitTypeId,
          selectedCount.value,
          "Interested in $unitTypeName - Call request",
          0, // enqtype
          updatedMobile,
        );

        // ⏬ Trigger call
        await callToAgent(phone);

        Get.snackbar(
          "Success",
          "Mobile updated and call initiated!",
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar("Cancelled", "Mobile number update was cancelled.");
      }

      return; // ⛔ Skip rest
    }

    // ✅ Regular flow for non-first-time users
    try {
      // Fetch mobile from Firestore if needed
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final mobile = doc.data()?['mobile'] ?? "";

      await postPropertyInterest(
        propertyId,
        unitTypeId,
        selectedCount.value,
        "Interested in $unitTypeName - Call request",
        0,
        mobile,
      );

      await callToAgent(phone);

      Get.snackbar(
        "Success",
        "Interest logged and call initiated!",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}