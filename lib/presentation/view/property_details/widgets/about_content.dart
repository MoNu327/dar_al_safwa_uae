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
    return Obx(() {
      final property = propertyDetailsController.property.value;
      
      if (propertyDetailsController.isLoading.value) {
        return const Center(child: CustomLoaderWidget());
      }
      
      if (property == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No property data available'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => propertyDetailsController.retryFetchPropertyDetails(),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.white,
        body: Column(
          children: [
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
                    // Property Price Section
                    if (property.price != null)
                      _buildPriceSection(property.price!),
                    
                    SizedBox(height: Get.height * 0.020),

                    // Description
                    _buildTitle(
                      'Description',
                      _buildDescriptionSection(isArabic
                          ? property.description?.ar ?? ""
                          : property.description?.en ?? ""),
                    ),

                    SizedBox(height: Get.height * 0.020),

                    // Location Map
                    if (property.location?.address?.coordinates != null)
                      _buildSection(
                        title: "Directions",
                        child: LocationPreview(
                          initialLocation: LatLng(
                            property.location!.address!.coordinates!.latitude ?? 0.0,
                            property.location!.address!.coordinates!.longitude ?? 0.0,
                          ),
                          previewHeight: 200,
                        ),
                      ),

                    SizedBox(height: Get.height * 0.020),

                    // Overview
                    if (property.overview != null)
                      _buildSection(
                        title: 'Overview',
                        child: _buildOverview(property.overview!),
                      ),

                    SizedBox(height: Get.height * 0.020),

                    // Unit Types Section
                    if (property.unitTypes != null && 
                        property.unitTypes!.data != null && 
                        property.unitTypes!.data!.isNotEmpty)
                      _buildUnitTypesSection(property.unitTypes!),

                    SizedBox(height: Get.height * 0.020),

                    // Agent Details
                    if (property.agent != null)
                      _buildAgentDetails(propertyDetailsController),

                    SizedBox(height: Get.height * 0.020),

                    // Video Tour
                    if (property.youtubeVideo?.url != null && 
                        property.youtubeVideo!.url!.isNotEmpty)
                      _buildTitle(
                        'Take a video tour',
                        OptimizedYoutubePlayer(
                          thumbnailUrl: property.youtubeVideo?.thumbnail ?? "",
                          videoUrl: property.youtubeVideo!.url!,
                        ),
                      ),

                    SizedBox(height: Get.height * 0.020),

                    // Features & Amenities
                    if (property.propertyFeatures != null)
                      _buildSection(
                        title: property.propertyFeatures!.sectionTitle?.en ?? 'Features & Amenities',
                        child: _buildFeatures(property.propertyFeatures!),
                      ),

                    SizedBox(height: Get.height * 0.020),

                    // Regulatory Information
                    if (property.regulations != null)
                      _buildSection(
                        title: property.regulations!.mainTitle?.en ?? 'Regulatory Information',
                        child: _buildRegulations(property.regulations!),
                      ),

                    SizedBox(height: Get.height * 0.020),

                    // Nearby Locations
                    if (property.nearbyTypes != null && property.nearbyTypes!.isNotEmpty)
                      _buildSection(
                        title: 'Nearby Locations',
                        child: _buildNearbyLocations(property.nearbyTypes!),
                      ),

                    const SizedBox(height: 100), // Space for bottom sheet
                  ],
                ),
              ),
            ),

            // Bottom Action Sheet
            if (property.agent != null)
              SafeArea(
                child: CustomBottomSheet(
                  onCallPressed: () {
                    propertyDetailsController.handleCallOrChat(
                      isCall: true,
                      phone: property.agent!.phone ?? "",
                      propertyId: property.id.toString(),
                      propertyName: property.title?.en ?? "",
                      agentEmail: property.agent!.email ?? "",
                    );
                  },
                  onWhatsAppPressed: () {
                    propertyDetailsController.handleCallOrChat(
                      isCall: false,
                      phone: property.agent!.phone ?? "",
                      propertyId: property.id.toString(),
                      propertyName: property.title?.en ?? "",
                      agentEmail: property.agent!.email ?? "",
                    );
                  },
                  height: 80,
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildPriceSection(Price price) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor),
      ),
      child: Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: "Price",
          fontSize: Get.height * 0.014,
          color: AppColors.black600,
        ),
        const SizedBox(height: 4),
        CustomTextWidget(
          title: "AED ${price.raw?.toStringAsFixed(0) ?? 'N/A'}",
          fontSize: Get.height * 0.022,
          fontWeight: FontWeight.bold,
          color: AppColors.secondaryColor,
        ),
      ],
    ),
    // Replaced icon with text "AED"
    CustomTextWidget(
      title: "AED",
      fontSize: Get.height * 0.022,
      fontWeight: FontWeight.bold,
      color: AppColors.secondaryColor,
    ),
  ],
)

    );
  }

  Widget _buildUnitTypesSection(UnitTypes unitTypes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: isArabic 
            ? (unitTypes.mainTitle?.ar ?? 'Unit Types')
            : (unitTypes.mainTitle?.en ?? 'Unit Types'),
          fontSize: popularPlaceTitle,
          color: AppColors.black,
          fontWeight: FontWeight.w600,
        ),
        SizedBox(height: Get.height * 0.015),
        ...unitTypes.data!.map((unitType) => _buildUnitTypeCard(unitType)).toList(),
      ],
    );
  }

  Widget _buildUnitTypeCard(UnitTypeData unitType) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomTextWidget(
                  title: isArabic 
                    ? (unitType.unitType?.name?.ar ?? '')
                    : (unitType.unitType?.name?.en ?? ''),
                  fontSize: Get.height * 0.018,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryColor,
                ),
              ),
              if (unitType.baseRentAmount?.raw != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomTextWidget(
                    title: "AED ${unitType.baseRentAmount!.raw!.toStringAsFixed(0)}",
                    fontSize: Get.height * 0.016,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryColor,
                  ),
                ),
            ],
          ),
          
          if (unitType.unitType?.description != null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: CustomTextWidget(
                title: isArabic 
                  ? (unitType.unitType!.description!.ar ?? '')
                  : (unitType.unitType!.description!.en ?? ''),
                fontSize: Get.height * 0.014,
                color: AppColors.black600,
              ),
            ),
          
          SizedBox(height: 12),
          
          Row(
            children: [
              if (unitType.beds != null)
                _buildUnitFeature(Icons.bed, "${unitType.beds} Beds"),
              SizedBox(width: 16),
              if (unitType.baths != null)
                _buildUnitFeature(Icons.bathtub, "${unitType.baths} Baths"),
              SizedBox(width: 16),
              if (unitType.area != null)
                _buildUnitFeature(Icons.straighten, 
                  isArabic ? (unitType.area!.ar ?? '') : (unitType.area!.en ?? '')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryColor),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: Get.height * 0.014,
            color: AppColors.black800,
          ),
        ),
      ],
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
            fontWeight: FontWeight.w600,
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildOverview(Overview overview) {
    if (overview.items == null || overview.items!.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightGrey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No overview information available',
          style: TextStyle(color: AppColors.black600),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: screenWidth * 0.03,
        mainAxisSpacing: screenHeight * 0.015,
        childAspectRatio: 1.2,
      ),
      itemCount: overview.items!.length,
      itemBuilder: (context, index) {
        final item = overview.items![index];
        return _buildOverviewItem(item);
      },
    );
  }

  Widget _buildOverviewItem(OverviewItem item) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGrey.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForOverviewItem(item.icon),
            size: screenHeight * 0.025,
            color: AppColors.primaryColor,
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            isArabic ? (item.title?.ar ?? '') : (item.title?.en ?? ''),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenHeight * 0.012,
              fontWeight: FontWeight.w500,
              color: AppColors.black600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2),
          Text(
            _formatOverviewValue(item.value),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenHeight * 0.014,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatOverviewValue(dynamic value) {
    if (value == null) return 'N/A';
    
    // Handle simple types first
    if (value is int) return value.toString();
    if (value is String) return value;
    
    // Handle Message object (for property type, etc.)
    if (value is Message) {
      String text = isArabic ? (value.ar ?? '') : (value.en ?? '');
      return text.isNotEmpty ? text : 'N/A';
    }
    
    // Handle OverviewValue object (for area with units)
    if (value is OverviewValue) {
      if (value.formatted != null) {
        String formatted = isArabic 
          ? (value.formatted!.ar ?? '') 
          : (value.formatted!.en ?? '');
        if (formatted.isNotEmpty) return formatted;
      }
      
      if (value.number != null) {
        String number = value.number.toString();
        if (value.unit != null) {
          String unit = isArabic 
            ? (value.unit!.ar ?? '') 
            : (value.unit!.en ?? '');
          return unit.isNotEmpty ? '$number $unit' : number;
        }
        return number;
      }
    }
    
    // Handle Map (JSON that wasn't properly deserialized)
    if (value is Map<String, dynamic>) {
      // Check if it's a Message-like structure
      if (value.containsKey('en') || value.containsKey('ar')) {
        String text = isArabic ? (value['ar'] ?? '') : (value['en'] ?? '');
        if (text.isNotEmpty) return text;
      }
      
      // Try to parse as OverviewValue
      try {
        if (value.containsKey('number') || value.containsKey('unit') || value.containsKey('formatted')) {
          OverviewValue ov = OverviewValue.fromJson(value);
          return _formatOverviewValue(ov);
        }
      } catch (e) {
        print('Error parsing OverviewValue from Map: $e');
      }
    }
    
    // Fallback - but avoid showing "Instance of..."
    String stringValue = value.toString();
    if (stringValue.startsWith('Instance of')) {
      return 'N/A';
    }
    
    return stringValue;
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
      case 'floor':
        return Icons.layers;
      case 'event_available':
        return Icons.event_available;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildTitle(String title, Widget content) {
    return Column(
      spacing: Get.height * 0.010,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: title,
          color: AppColors.black,
          fontSize: Get.height * 0.020,
          fontWeight: FontWeight.w600,
        ),
        content,
      ],
    );
  }

  Widget _buildDescriptionSection(String? description) {
    if (description == null || description.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightGrey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No description available',
          style: TextStyle(color: AppColors.black600),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGrey.withOpacity(0.5)),
      ),
      child: CustomTextWidget(
        title: description,
        fontSize: screenHeight * 0.015,
        fontWeight: FontWeight.w400,
        color: AppColors.black800,
        maxLines: 100,
      ),
    );
  }

  Widget _buildAgentDetails(PropertyDetailsController controller) {
    final agent = controller.property.value?.agent;
    if (agent == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: _buildAgentInfo(agent)),
          _buildAgentActions(controller),
        ],
      ),
    );
  }

  Widget _buildAgentInfo(Agent agent) {
    return Row(
      children: [
        CircleAvatar(
          radius: Get.height * 0.035,
          backgroundImage: agent.image != null && agent.image!.isNotEmpty
            ? NetworkImage(agent.image!)
            : null,
          backgroundColor: AppColors.primaryColor.withOpacity(0.2),
          child: agent.image == null || agent.image!.isEmpty
            ? Icon(
                Icons.person,
                color: AppColors.secondaryColor,
                size: Get.height * 0.03,
              )
            : null,
        ),
        SizedBox(width: Get.width * 0.03),
        Expanded(
          child: Column(
            spacing: Get.height * 0.005,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextWidget(
                title: isArabic 
                  ? (agent.name?.ar ?? 'Agent')
                  : (agent.name?.en ?? 'Agent'),
                fontSize: Get.height * 0.018,
                color: AppColors.black,
                fontWeight: FontWeight.w600,
              ),
              CustomTextWidget(
                title: 'Real Estate Agent',
                fontSize: Get.height * 0.014,
                color: AppColors.darkGrey,
                fontWeight: FontWeight.w400,
              ),
              if (agent.phone != null && agent.phone!.isNotEmpty)
                CustomTextWidget(
                  title: agent.phone!,
                  fontSize: Get.height * 0.013,
                  color: AppColors.black,
                  fontWeight: FontWeight.w500,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgentActions(PropertyDetailsController controller) {
    final property = controller.property.value;
    if (property == null || property.agent == null) return SizedBox.shrink();

    final gmail = property.agent!.email ?? "";
    final phone = property.agent!.phone ?? "";
    final propertyId = property.id.toString();
    final propertyName = property.title?.en ?? "";

    return Row(
      spacing: Get.width * 0.02,
      children: [
        InkWell(
          onTap: () {
            auth.currentUser == null
              ? Get.toNamed(AppRoute.signupWarning)
              : controller.showUnitTypeBottomSheetForChat(
                  gmail, propertyId, propertyName);
          },
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.message,
              color: AppColors.secondaryColor,
              size: 20,
            ),
          ),
        ),
        InkWell(
          onTap: () {
            controller.showUnitTypeBottomSheetForCall(phone, propertyId);
          },
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.call,
              color: AppColors.secondaryColor,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures(PropertyFeatures features) {
    if (features.items == null || features.items!.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No features information available',
          style: TextStyle(color: AppColors.black600),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: features.items!.map((feature) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
          ),
          child: Text(
            isArabic ? (feature.ar ?? '') : (feature.en ?? ''),
            style: TextStyle(
              fontSize: Get.height * 0.014,
              color: AppColors.secondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRegulations(Regulations regulations) {
    if (regulations.data == null || regulations.data!.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No regulatory information available',
          style: TextStyle(color: AppColors.black600),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGrey.withOpacity(0.5)),
      ),
      child: Column(
        children: regulations.data!.map((regulation) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isArabic
                      ? (regulation.title?.ar ?? '')
                      : (regulation.title?.en ?? ''),
                    style: TextStyle(
                      fontSize: screenHeight * 0.015,
                      color: AppColors.black800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  regulation.value ?? 'N/A',
                  style: TextStyle(
                    fontSize: screenHeight * 0.015,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNearbyLocations(List<NearbyType> nearby) {
    if (nearby.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightGrey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No nearby locations information available',
          style: TextStyle(color: AppColors.black600),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: screenWidth * 0.02,
        mainAxisSpacing: screenHeight * 0.015,
        childAspectRatio: 0.9,
      ),
      itemCount: nearby.length,
      itemBuilder: (context, index) {
        final location = nearby[index];
        return _buildNearbyLocationItem(location);
      },
    );
  }

  Widget _buildNearbyLocationItem(NearbyType location) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGrey.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForNearbyLocation(location.type?.en),
            size: screenHeight * 0.025,
            color: AppColors.primaryColor,
          ),
          SizedBox(height: 4),
          Text(
            (isArabic ? location.name?.ar : location.name?.en) ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenHeight * 0.011,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (location.distance != null && location.distance!.isNotEmpty)
            Text(
              location.distance!,
              style: TextStyle(
                fontSize: screenHeight * 0.011,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForNearbyLocation(String? icon) {
    switch (icon ?? '') {
      case 'local_mall':
      case 'shopping':
        return Icons.local_mall;
      case 'school':
      case 'education':
        return Icons.school;
      case 'local_hospital':
      case 'hospital':
        return Icons.local_hospital;
      case 'restaurant':
        return Icons.restaurant;
      case 'park':
        return Icons.park;
      case 'airport':
        return Icons.flight;
      default:
        return Icons.location_on;
    }
  }
}