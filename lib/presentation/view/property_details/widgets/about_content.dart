import 'dart:convert';

import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:dar_al_safwa/presentation/view/property_details/controller/property_details_controller.dart';
import 'package:dar_al_safwa/presentation/view_model/video_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_snackbar.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/widgets/loader_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../../../data/model/property_details_model.dart';
import '../../../view_model/localization_controller.dart';

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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            top: Get.height * 0.02,
            bottom: Get.height * 0.02,
          ),
          child: Column(
            spacing: Get.height * 0.025,
            children: [
              _buildTitle(
                'Description',
                _buildDescriptionSection(isArabic
                    ? property.description?.ar
                    : property.description?.en),
              ),

              // _buildTitle(
              //   (isArabic
              //           ? property.overview?.sectionTitle?.ar
              //           : property.overview?.sectionTitle?.en) ??
              //       'Overview',
              //   _buildOverviewSection(property.overview),
              // ),
              _buildSection(
                title: (isArabic
                        ? property.overview?.sectionTitle?.ar
                        : property.overview?.sectionTitle?.en) ??
                    'Overview',
                child: _buildOverview(property.overview),
              ),

              // Agent details
              _buildAgentDetails(),

              // Take a video tour
              _buildTitle('Take a video tour', _buildVideoTourSection()),

              _buildSection(
                title: 'Features & Amenities',
                child: _buildFeatures(property.propertyFeatures),
              ),
              _buildSection(
                title: 'Regulatory Information',
                child: _buildRegulations(property.regulations),
              ),
              _buildSection(
                title: 'Nearby Locations',
                child: _buildNearbyLocations(property.location?.nearby),
              ),

              // // Features & Amenities
              // _buildTitle(
              //     'Features & Amenities', _buildFeaturesAmenitiesSection()),

              // // Regulatory Information Section
              // _buildTitle(
              //     'Regulatory Information', _buildRegulatoryInfoSection()),

              // // Location Nearby
              // _buildTitle('Location Nearby', _buildLocationNearbySection())
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Column(
        spacing: screenHeight1,
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
    if (overview == null || overview.items!.isEmpty) {
      return const Text('No overview information available');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: screenWidth * 0.03,
        mainAxisSpacing: screenHeight * 0.015,
        childAspectRatio: 1.5,
      ),
      itemCount: overview.items?.length,
      itemBuilder: (context, index) {
        final item = overview.items?[index];
        return _buildOverviewItem(item!);
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
          title: isArabic ? item.title?.ar : item.title?.en ?? '',
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
    if (value is int || value is String) return value.toString();
    if (value is AreaValue) return value.formatted?.en ?? '';
    return '';
  }

  IconData _getIconForOverviewItem(String? iconName) {
    switch (iconName) {
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

  // Description Section Widget
  Widget _buildDescriptionSection(String? description) {
    return CustomTextWidget(
      title: description ?? "No description available.",
      fontSize: screenHeight * 0.015,
      fontWeight: FontWeight.w500,
      color: AppColors.black800,
      maxLines: 3,
    );
  }

  // Overview Section Widget
  Widget _buildOverviewSection(Overview? overview) {
    return Obx(() {
      if (overview == null || overview.items!.isEmpty) {
        return const Text('No overview information available');
      }

      return _buildPropertyOverviewGrid();
    });
  }

  // Grid View Widget for Property Overview
  Widget _buildPropertyOverviewGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: Get.width * 0.015,
        mainAxisSpacing: Get.height * 0.01,
        childAspectRatio: 2,
      ),
      itemCount: propertyDetailsController.propertyOverView.length * 8,
      itemBuilder: (context, index) {
        var property = propertyDetailsController.propertyOverView[index ~/ 8];
        int detailIndex = index % 8;

        return _buildRowWithIcon(detailIndex, property);
      },
    );
  }

  // Property Overview Row Widget
  Widget _buildRowWithIcon(int detailIndex, var property) {
    String label;
    dynamic value;
    IconData icon;

    switch (detailIndex) {
      case 0:
        label = 'ID:';
        value = property['id'];
        icon = Icons.home;
        break;
      case 1:
        label = 'Type:';
        value = property['type'];
        icon = Icons.home_work;
        break;
      case 2:
        label = 'Garages:';
        value = property['garages'];
        icon = Icons.garage_sharp;
        break;
      case 3:
        label = 'Bedrooms:';
        value = property['bedrooms'];
        icon = Icons.bed;
        break;
      case 4:
        label = 'Bathrooms:';
        value = property['bathrooms'];
        icon = Icons.bathtub;
        break;
      case 5:
        label = 'Size:';
        value = '${property['size']} sq.ft';
        icon = Icons.scale;
        break;
      case 6:
        label = 'Built Year:';
        value = property['builtYear'];
        icon = Icons.calendar_today;
        break;
      case 7:
        label = 'Balcony:';
        value = property['hasBalcony'] ? 'Available' : 'Not-Available';
        icon = Icons.filter_hdr;
        break;
      default:
        return Container();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: Get.height * 0.015),
      child: Row(
        spacing: Get.width * 0.015,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Get.width * 0.025,
              vertical: Get.height * 0.013,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(width: 1, color: AppColors.lightGrey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.black,
              size: Get.height * 0.022,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextWidget(
                title: label,
                fontSize: Get.height * 0.012,
                color: AppColors.black800,
                fontWeight: FontWeight.w400,
              ),
              SizedBox(height: Get.height * 0.002),
              CustomTextWidget(
                title: '$value',
                fontSize: Get.height * 0.015,
                color: AppColors.black,
                fontWeight: FontWeight.w500,
              )
            ],
          ),
        ],
      ),
    );
  }

  // Agent Details Widget
  Widget _buildAgentDetails() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildAgentInfo(),
        _buildAgentActions(),
      ],
    );
  }

  Widget _buildAgentInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: Get.height * 0.035,
          backgroundImage: const AssetImage('assets/images/agent.jpg'),
          backgroundColor: AppColors.white,
        ),
        SizedBox(width: Get.width * 0.02),
        Column(
          spacing: Get.height * 0.005,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextWidget(
              title: 'Sudhaker Poojary',
              fontSize: Get.height * 0.02,
              color: AppColors.black,
              fontWeight: FontWeight.w500,
            ),
            CustomTextWidget(
              title: 'Real Estate Agent',
              fontSize: Get.height * 0.015,
              color: AppColors.lightGrey,
              fontWeight: FontWeight.w400,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAgentActions() {
    return Row(
      spacing: Get.width * 0.02,
      children: [
        InkWell(
          onTap: () {
            auth.currentUser == null
                ? Get.toNamed(AppRoute.signupWarning)
                : auth.currentUser != null &&
                        auth.currentUser?.displayName != null
                    ? propertyDetailsController.navigateToAgentChat(
                        "teat@gmail.com", "Riverview Retreat")
                    : auth.currentUser?.email == null
                        ? propertyDetailsController.navigateToAgentChat(
                            "teat@gmail.com", "Riverview Retreat")
                        : CustomSnackbar.show(
                            title: "Failed",
                            message:
                                "Currently, the agent is unable to connect.");
          },
          child: CircleAvatar(
            backgroundColor: AppColors.whiteLight,
            radius: Get.height * 0.026,
            child: Icon(
              Icons.message,
              color: AppColors.secondaryColor,
              size: Get.height * 0.023,
            ),
          ),
        ),
        InkWell(
          onTap: () {
            propertyDetailsController.callToAgent('9544418765');
          },
          child: CircleAvatar(
            backgroundColor: AppColors.whiteLight,
            radius: Get.height * 0.026,
            child: Icon(
              Icons.call,
              color: AppColors.secondaryColor,
              size: Get.height * 0.023,
            ),
          ),
        ),
      ],
    );
  }

  // Video section widget for video tour
  Widget _buildVideoTourSection() {
    return Container(
      width: double.infinity,
      height: Get.height * 0.25,
      decoration: BoxDecoration(
        color: AppColors.redColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Obx(() => videoController.isInitialized.value
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: VideoPlayer(videoController.videoPlayerController),
                )
              : const Center(child: CircularProgressIndicator())),
          Positioned(
            bottom: 5,
            left: 8,
            child: ElevatedButton(
              onPressed: () {
                // Add your onPressed code here!
              },
              child: const Text("View All"),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: CustomTextWidget(
              title: "Watch the video for taking your\n decision easily.",
              color: AppColors.white,
            ),
          )
        ],
      ),
    );
  }

  // Features & Amenities Section
  Widget _buildFeaturesAmenitiesSection() {
    return Obx(() {
      var features = propertyDetailsController.featuresAndAmenities;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: Get.width * 0.03,
          childAspectRatio: 1,
        ),
        itemCount: features.length,
        itemBuilder: (context, index) {
          var feature = features[index];

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(Get.height * 0.015),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(
                    width: 1,
                    color: AppColors.lightGrey,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _getIconData(feature["icon"]),
                    color: AppColors.black,
                    size: Get.height * 0.02,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: CustomTextWidget(
                    title: feature["name"],
                    color: AppColors.black800,
                    fontWeight: FontWeight.w400,
                    fontSize: Get.height * 0.012,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  // Helper function to map the icon string to IconData
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case "bathtub":
        return Icons.bathtub;
      case "spa":
        return Icons.spa;
      case "ac_unit":
        return Icons.ac_unit;
      case "storage":
        return Icons.storage;
      case "business_center":
        return Icons.business_center;
      default:
        return Icons.help_outline;
    }
  }

  // Regulatory Information Section
  Widget _buildRegulatoryInfoSection() {
    return Obx(() {
      var regulatoryList = propertyDetailsController.regulatoryInfo;

      return Column(
        children: List.generate(regulatoryList.length, (index) {
          var item = regulatoryList[index];
          return Padding(
            padding: EdgeInsets.only(bottom: Get.height * 0.015),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  spacing: Get.width * 0.01,
                  children: [
                    CustomTextWidget(
                      title: item['title']!,
                      color: AppColors.black800,
                      fontWeight: FontWeight.w500,
                      fontSize: Get.height * 0.015,
                    ),
                    Icon(
                      Icons.warning_outlined,
                      color: AppColors.redColor,
                      size: Get.height * 0.015,
                    ),
                  ],
                ),
                CustomTextWidget(
                  title: item['value']!,
                  color: AppColors.black500,
                  fontWeight: FontWeight.w400,
                  fontSize: Get.height * 0.015,
                )
              ],
            ),
          );
        }),
      );
    });
  }

  // Location nearby section
  Widget _buildLocationNearbySection() {
    return Obx(() {
      var locations = propertyDetailsController.nearbyLocations;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: screenWidth * 0.03,
          mainAxisSpacing: screenHeight2,
          childAspectRatio: 1,
        ),
        itemCount: locations.length,
        itemBuilder: (context, index) {
          var location = locations[index];

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                padding: EdgeInsets.all(Get.width * 0.03),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(
                    width: 1,
                    color: AppColors.lightGrey,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _getIconDataForNearByLocations(location["icon"]),
                    color: AppColors.black,
                    size: Get.height * 0.025,
                  ),
                ),
              ),
              // Location Name
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Get.width * 0.01),
                child: CustomTextWidget(
                  title: location["name"],
                  color: AppColors.black800,
                  fontWeight: FontWeight.w500,
                  fontSize: screenHeight * 0.012,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              kHeight(0.005),

              // Distance
              CustomTextWidget(
                title: '${location["distance"]} km',
                color: AppColors.black600,
                fontWeight: FontWeight.w400,
                fontSize: Get.height * 0.012,
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      );
    });
  }

// Helper function to map the icon string to IconData
  IconData _getIconDataForNearByLocations(String iconName) {
    switch (iconName) {
      case "bathtub":
        return Icons.bathtub;
      case "spa":
        return Icons.spa;
      case "ac_unit":
        return Icons.ac_unit;
      case "storage":
        return Icons.storage;
      case "business_center":
        return Icons.business_center;
      case "school":
        return Icons.school;
      case "local_hospital":
        return Icons.local_hospital;
      case "park":
        return Icons.park;
      case "restaurant":
        return Icons.restaurant;
      case "airplanemode_active":
        return Icons.airplanemode_active;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildFeatures(PropertyFeatures? features) {
    if (features == null || features.items!.isEmpty) {
      return const Text('No features information available');
    }

    return Wrap(
      spacing: screenWidth * 0.03,
      runSpacing: screenHeight * 0.015,
      children: features.items!.map((feature) {
        return Chip(
          label: Text(isArabic ? (feature.ar ?? 'N/A') : (feature.en ?? 'N/A')),
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
    if (regulations == null || regulations.data!.isEmpty) {
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
                    ? (regulation.title?.ar ?? 'N/A')
                    : (regulation.title?.en ?? 'N/A'),
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

  Widget _buildNearbyLocations(List<Nearby>? nearby) {
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

  Widget _buildNearbyLocationItem(Nearby location) {
    return Column(
      children: [
        Icon(
          _getIconForNearbyLocation(location.icon),
          size: screenHeight * 0.03,
          color: AppColors.primaryColor,
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
    switch (icon) {
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
