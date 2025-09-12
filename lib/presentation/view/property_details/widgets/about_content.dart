import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/routes/app_route.dart';
import 'package:majan/presentation/view/property_details/controller/property_details_controller.dart';
import 'package:majan/presentation/view_model/video_controller.dart';
import 'package:majan/presentation/widgets/custom_snackbar.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/presentation/widgets/loader_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../../../data/model/property_details_model.dart';
import '../../../view_model/localization_controller.dart';
import '../../../widgets/maps_widget.dart';
import 'price_bottom_sheet.dart';
import 'you_tube_viewer_widget.dart';

class AboutContent extends StatelessWidget {
  AboutContent({super.key});

  final PropertyDetailsController propertyDetailsController = Get.find();
  final LocalizationController localizationController = Get.find();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final VideoController videoController = Get.put(VideoController());
  final isArabic = Get.locale?.languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final property = propertyDetailsController.property.value;
    if (property == null) {
      return const Center(child: CustomLoaderWidget());
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: Get.height * 0.02,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(
                    'Description',
                    _buildDescriptionSection(isArabic
                        ? property.description?.ar ?? ""
                        : property.description?.en ?? ""),
                  ),

                  SizedBox(height: Get.height * 0.020),

                  _buildSection(
                    title: "Directions",
                    child: LocationPreview(
                      initialLocation: LatLng(
                        property.location?.address?.coordinates?.latitude ??
                            0.0,
                        property.location?.address?.coordinates?.longitude ??
                            0.0,
                      ),
                      previewHeight: 200,
                    ),
                  ),

                  SizedBox(height: Get.height * 0.020),

                  _buildSection(
                    title: 'Overview',
                    child: _buildOverview(property.overview),
                  ),

                  SizedBox(height: Get.height * 0.020),

                  // Agent details
                  _buildAgentDetails(propertyDetailsController),

                  SizedBox(height: Get.height * 0.020),

                  // Take a video tour
                  _buildTitle(
                      'Take a video tour',
                      OptimizedYoutubePlayer(
                          thumbnailUrl: "${property.youtubeVideo?.thumbnail}",
                          videoUrl: "${property.youtubeVideo?.url}")),
                  // RepaintBoundary(
                  //   child: _buildYoutubeViewerSection(
                  //       property.youtubeVideo?.url ?? ''),
                  // )),

                  SizedBox(height: Get.height * 0.020),

                  _buildSection(
                    title: 'Features & Amenities',
                    child: _buildFeatures(property.propertyFeatures),
                  ),

                  SizedBox(height: Get.height * 0.020),

                  _buildSection(
                    title: 'Regulatory Information',
                    child: _buildRegulations(property.regulations),
                  ),

                  SizedBox(height: Get.height * 0.020),

                  _buildSection(
                    title: 'Nearby Locations',
                    child: _buildNearbyLocations(property.nearbyTypes),
                  ),

                  // Extra space to prevent content from being hidden behind bottom sheet
                  const SizedBox(height: 20),

                  SafeArea(
                    child: CustomBottomSheet(
                      onCallPressed: () {
                        propertyDetailsController.handleCallOrChat(
                          isCall: true,
                          phone: property?.agent?.phone ?? "9544418765",
                          propertyId: property?.id.toString() ?? "0",
                          propertyName: property?.title?.en ?? "",
                          agentEmail: property?.agent?.email ?? "test@gmail.com",
                        );
                      },
                      onWhatsAppPressed: () {
                        propertyDetailsController.handleCallOrChat(
                          isCall: false,
                          phone: property?.agent?.phone ?? "9544418765",
                          propertyId: property?.id.toString() ?? "0",
                          propertyName: property?.title?.en ?? "",
                          agentEmail: property?.agent?.email ?? "test@gmail.com",
                        );
                      },
                      height: 80,
                    ),
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.01),
      child: Column(
        spacing: screenHeight1,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextWidget(
            title: title,
            fontSize: popularPlaceTitle,
            color: AppColors.black,
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildOverview(Overview? overview) {
    if (overview == null || overview.items == null || overview.items!.isEmpty) {
      return const Text('No overview information available');
    }
     overview.items?.forEach((item) {
    print('DEBUG Item: ${item.title?.en} - Value type: ${item.value.runtimeType} - Value: ${item.value}');
  });
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: screenWidth * 0.03,
        mainAxisSpacing: screenHeight * 0.010,
        childAspectRatio: 1.5,
      ),
      itemCount: overview.items?.length ?? 0,
      itemBuilder: (context, index) {
        final item = overview.items?[index];
        return item != null ? _buildOverviewItem(item) : const SizedBox();
      },
    );
  }

  Widget _buildOverviewItem(OverviewItem item) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _getIconForOverviewItem(item.icon),
          size: screenHeight * 0.025,
          color: AppColors.primaryColor,
        ),
        SizedBox(height: screenHeight * 0.005),
        CustomTextWidget(
          title: isArabic ? item.title?.ar ?? '' : item.title?.en ?? '',
          fontSize: tagTitle,
        ),
        Text(
          _formatOverviewValue(item.value),
          style: TextStyle(
            fontSize: screenHeight * 0.015,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

String _formatOverviewValue(dynamic value) {
  if (value == null) return 'N/A';
  
  // Debug: Print the value and its type
  print('Overview value: $value');
  print('Overview value type: ${value.runtimeType}');
  
  // Handle simple types
  if (value is int || value is String) {
    print('Returning simple value: ${value.toString()}');
    return value.toString();
  }
  
  // Handle OverviewValue object
  if (value is OverviewValue) {
    print('Handling OverviewValue object');
    // First try to use the formatted value
    if (value.formatted != null) {
      String formattedText = isArabic 
          ? (value.formatted?.ar ?? '') 
          : (value.formatted?.en ?? '');
      if (formattedText.isNotEmpty) {
        print('Returning formatted text: $formattedText');
        return formattedText;
      }
    }
    
    // If no formatted value, try to construct from number and unit
    if (value.number != null) {
      String numberText = value.number.toString();
      if (value.unit != null) {
        String unitText = isArabic 
            ? (value.unit?.ar ?? '') 
            : (value.unit?.en ?? '');
        String result = unitText.isNotEmpty ? '$numberText $unitText' : numberText;
        print('Returning number + unit: $result');
        return result;
      }
      print('Returning number only: $numberText');
      return numberText;
    }
  }
  
  // Handle Map (in case the JSON wasn't properly converted)
  if (value is Map<String, dynamic>) {
    print('Handling Map value: $value');
    try {
      OverviewValue overviewValue = OverviewValue.fromJson(value);
      return _formatOverviewValue(overviewValue); // Recursive call
    } catch (e) {
      print('Error parsing OverviewValue from Map: $e');
      
      // Try to extract direct values from the map
      if (value.containsKey('en') || value.containsKey('ar')) {
        String result = isArabic ? (value['ar'] ?? '') : (value['en'] ?? '');
        if (result.isNotEmpty) {
          print('Returning localized value from map: $result');
          return result;
        }
      }
    }
  }
  
  // Handle Message object (similar to what you have in other parts of your code)
  if (value is Message) {
    String result = isArabic ? (value.ar ?? '') : (value.en ?? '');
    if (result.isNotEmpty) {
      print('Returning Message value: $result');
      return result;
    }
  }
  
  print('Falling back to N/A for value: $value');
  return 'N/A';
}
  IconData _getIconForOverviewItem(String? iconName) {
    switch (iconName ?? '') {
      case 'bed':
        return Icons.bed;
      case 'bathtub':
        return Icons.bathtub;
      case 'apartment':
        return Icons.apartment;
      case 'straighten':
        return Icons.straighten;
      case 'construction':
        return Icons.construction;
      case 'event_available':
        return Icons.event_available;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildTitle(String title, Widget content) {
    return Column(
      spacing: Get.height * 0.005,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: title,
          color: AppColors.black,
          fontSize: Get.height * 0.02,
          fontWeight: FontWeight.w500,
        ),
        content,
      ],
    );
  }

  Widget _buildDescriptionSection(String? description) {
    return CustomTextWidget(
      title: description ?? "No description available.",
      fontSize: screenHeight * 0.015,
      fontWeight: FontWeight.w500,
      color: AppColors.black800,
      maxLines: 3,
    );
  }

  Widget _buildAgentDetails(PropertyDetailsController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildAgentInfo(),
        _buildAgentActions(controller),
      ],
    );
  }

  Widget _buildAgentInfo() {
    return Row(
      children: [
        CircleAvatar(
            radius: Get.height * 0.035,
            backgroundImage: NetworkImage(
                "${propertyDetailsController.property?.value?.agent?.image}"),
            backgroundColor: AppColors.whiteLight,
            child: Icon(
              Icons.person,
              color: AppColors.secondaryColor,
              size: Get.height * 0.03,
            )),
        SizedBox(width: Get.width * 0.02),
        Column(
          spacing: Get.height * 0.005,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextWidget(
              title:
                  "${propertyDetailsController.property?.value?.agent?.name?.en}" ??
                      'Agent Name',
              fontSize: Get.height * 0.02,
              color: AppColors.black,
              fontWeight: FontWeight.w500,
            ),
            CustomTextWidget(
              title: 'Real Estate Agent',
              fontSize: Get.height * 0.015,
              color: AppColors.darkGrey,
              fontWeight: FontWeight.w400,
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildAgentActions(PropertyDetailsController controller) {
    final property = controller.property.value;
    final gmail = property?.agent?.email ?? "test@gmail.com";
    final phone = property?.agent?.phone ?? "9544418765";
    final propertyId = property?.id.toString() ?? "";
    final propertyName = property?.title?.en ?? "0";

    return Row(
      spacing: Get.width * 0.02,
      children: [
        InkWell(
          onTap: () {
            // For chat
            auth.currentUser == null
                ? Get.toNamed(AppRoute.signupWarning)
                : auth.currentUser != null &&
                        auth.currentUser?.displayName != null
                    ? controller.showUnitTypeBottomSheetForChat(
                        gmail, propertyId, propertyName)
                    : auth.currentUser?.email == null
                        ? controller.showUnitTypeBottomSheetForChat(
                            gmail, propertyId, propertyName)
                        : CustomSnackbar.show(
                            title: "Failed",
                            message:
                                "Currently, the agent is unable to connect.");
          },
          child: CircleAvatar(
            backgroundColor: AppColors.whiteLight,
            radius: Get.height * 0.026,
            child: Icon(Icons.message, color: AppColors.secondaryColor),
          ),
        ),
        InkWell(
          onTap: () {
            // For call
            controller.showUnitTypeBottomSheetForCall(phone, propertyId,);
          },
          child: CircleAvatar(
            backgroundColor: AppColors.whiteLight,
            radius: Get.height * 0.026,
            child: Icon(Icons.call, color: AppColors.secondaryColor),
          ),
        ),
      ],
    );
  }

  

  Widget _buildFeatures(PropertyFeatures? features) {
    if (features == null || features.items == null || features.items!.isEmpty) {
      return const Text('No features information available');
    }

    return Wrap(
      spacing: screenWidth * 0.03,
      runSpacing: screenHeight * 0.015,
      children: features.items!.map((feature) {
        return Chip(
          label: Text(isArabic ? (feature.ar ?? '') : (feature.en ?? '')),
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppColors.lightGrey),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRegulations(Regulations? regulations) {
    if (regulations == null ||
        regulations.data == null ||
        regulations.data!.isEmpty) {
      return const Text('No regulatory information available');
    }

    return Column(
      children: regulations.data!.map((regulation) {
        return Padding(
          padding: EdgeInsets.only(bottom: screenHeight * 0.01),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic
                    ? (regulation.title?.ar ?? '')
                    : (regulation.title?.en ?? ''),
                style: TextStyle(
                  fontSize: screenHeight * 0.015,
                  color: AppColors.black800,
                ),
              ),
              Text(
                regulation.value ?? '',
                style: TextStyle(
                  fontSize: screenHeight * 0.015,
                  color: AppColors.black600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNearbyLocations(List<NearbyType>? nearby) {
    if (nearby == null || nearby.isEmpty) {
      return const Text('No nearby locations information available');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: screenWidth * 0.03,
        mainAxisSpacing: screenHeight * 0.015,
        childAspectRatio: 1,
      ),
      itemCount: nearby.length,
      itemBuilder: (context, index) {
        final location = nearby[index];
        return _buildNearbyLocationItem(location);
      },
    );
  }

  Widget _buildNearbyLocationItem(NearbyType location) {
    return Column(
      children: [
        Icon(
          _getIconForNearbyLocation(location.type?.en),
          size: screenHeight * 0.03,
          color: AppColors.secondaryColor,
        ),
        SizedBox(height: screenHeight * 0.005),
        Text(
          (isArabic ? location.name?.ar : location.name?.en) ?? '',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: screenHeight * 0.012,
          ),
        ),
        Text(
          location.distance ?? '',
          style: TextStyle(
            fontSize: screenHeight * 0.012,
            color: AppColors.black600,
          ),
        ),
      ],
    );
  }

  IconData _getIconForNearbyLocation(String? icon) {
    switch (icon ?? '') {
      case 'local_mall':
        return Icons.local_mall;
      case 'school':
        return Icons.school;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'restaurant':
        return Icons.restaurant;
      case 'park':
        return Icons.park;
      default:
        return Icons.location_on;
    }
  }
}
