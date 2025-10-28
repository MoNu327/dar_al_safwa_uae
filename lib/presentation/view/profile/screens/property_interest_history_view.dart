
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/data/model/property_interest_history_model.dart';
import 'package:majan/presentation/view/profile/controller/profile_controller.dart';
import 'package:majan/presentation/view/property_details/screens/proprety_details_screen.dart';


class PropertyInterestHistoryScreen extends StatelessWidget {
  const PropertyInterestHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: AppColors.whiteLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.secondaryColor,
            size: iconSize,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Property Interest History',
          style: TextStyle(
            color: AppColors.secondaryColor,
            fontSize: appBarTitles,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: AppColors.secondaryColor,
              size: iconSize,
            ),
            onPressed: () => controller.refreshPropertyInterests(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingInterests.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppColors.secondaryColor,
                  strokeWidth: 3,
                ),
                kHeight(0.02),
                Text(
                  'Loading your property interests...',
                  style: TextStyle(
                    color: AppColors.black600,
                    fontSize: tagTitle,
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.interestsError.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: screenHeight * 0.08,
                  color: AppColors.error,
                ),
                kHeight(0.02),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth5),
                  child: Text(
                    controller.interestsError.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.black800,
                      fontSize: packageTitle,
                    ),
                  ),
                ),
                kHeight(0.03),
                ElevatedButton.icon(
                  onPressed: () => controller.refreshPropertyInterests(),
                  icon: Icon(Icons.refresh, size: smallIconSize),
                  label: Text(
                    'Try Again',
                    style: TextStyle(fontSize: tagTitle),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryColor,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth6,
                      vertical: screenHeight2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.propertyInterests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.house_outlined,
                  size: screenHeight * 0.12,
                  color: AppColors.lightGrey,
                ),
                kHeight(0.02),
                Text(
                  'No Property Interests Yet',
                  style: TextStyle(
                    color: AppColors.black800,
                    fontSize: heading,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                kHeight(0.01),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth8),
                  child: Text(
                    'Start exploring properties and show your interest to see them here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.black500,
                      fontSize: tagTitle,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshPropertyInterests(),
          color: AppColors.secondaryColor,
          child: Column(
            children: [
              // Header Stats
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(screenWidth5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      icon: Icons.favorite,
                      label: 'Total Interests',
                      value: controller.propertyInterestCount.toString(),
                    ),
                    _buildStatCard(
                      icon: Icons.home_work,
                      label: 'Properties',
                      value: controller.propertyInterests
                          .map((e) => e.propertyId)
                          .toSet()
                          .length
                          .toString(),
                    ),
                  ],
                ),
              ),

              // List of Interests
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(screenWidth4),
                  itemCount: controller.propertyInterests.length,
                  itemBuilder: (context, index) {
                    final interest = controller.propertyInterests[index];
                    return _buildPropertyInterestCard(interest, index);
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth5,
        vertical: screenHeight2,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.secondaryColor,
            size: iconSize,
          ),
          kHeight(0.01),
          Text(
            value,
            style: TextStyle(
              color: AppColors.secondaryColor,
              fontSize: heading,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppColors.black600,
              fontSize: detailContentTitle,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPropertyDetails(String propertyId) {
    // Convert propertyId to int if needed
    final int? propertyIdInt = int.tryParse(propertyId);
    
    if (propertyIdInt == null) {
      Get.snackbar(
        'Error',
        'Invalid property ID',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
        margin: EdgeInsets.all(screenWidth4),
        borderRadius: 12,
      );
      return;
    }
    
    Get.to(
      () => PropertyDetailsScreen(),
      arguments: {'propertyId': propertyIdInt},
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildPropertyInterestCard(PropertyInterestUser interest, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Image with overlay
              InkWell(
                onTap: () => _navigateToPropertyDetails(interest.propertyId),
                child: Stack(
                  children: [
                    // Property Image
                    Container(
                      height: screenHeight * 0.25,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey2,
                      ),
                      child: interest.propertyImageUrl != null &&
                              interest.propertyImageUrl!.isNotEmpty
                          ? Image.network(
                              interest.propertyImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage();
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.secondaryColor,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            )
                          : _buildPlaceholderImage(),
                    ),
                    
                    // Gradient Overlay
                    Container(
                      height: screenHeight * 0.25,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    
                    // Index Badge
                    Positioned(
                      top: screenHeight2,
                      left: screenWidth3,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth3,
                          vertical: screenHeight05,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(
                            color: AppColors.secondaryColor,
                            fontSize: tagTitle,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    // Favorite Icon
                    Positioned(
                      top: screenHeight2,
                      right: screenWidth3,
                      child: Container(
                        padding: EdgeInsets.all(screenWidth2),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite,
                          color: AppColors.redColor,
                          size: smallIconSize,
                        ),
                      ),
                    ),
                    
                    // Property Title at bottom of image
                    Positioned(
                      bottom: screenHeight2,
                      left: screenWidth3,
                      right: screenWidth3,
                      child: Text(
                        interest.propertyTitle ?? 'Property',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: packageTitle,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: AppColors.black.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Content Section
              Padding(
                padding: EdgeInsets.all(screenWidth4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property Details
                    _buildDetailRow(
                      icon: Icons.home,
                      label: 'Property ID',
                      value: interest.propertyId,
                    ),
                    kHeight(0.01),
                    _buildDetailRow(
                      icon: Icons.door_front_door,
                      label: 'Unit ID',
                      value: interest.unitId,
                    ),
                    kHeight(0.01),
                    _buildDetailRow(
                      icon: Icons.category,
                      label: 'Unit Type',
                      value: _formatUnitType(interest.unitType),
                    ),
                    kHeight(0.02),
                    
                    // View Property Button
                    ElevatedButton.icon(
  onPressed: () => _navigateToPropertyDetails(interest.propertyId),
  icon: Icon(
    Icons.visibility,
    size: smallIconSize,
    color: AppColors.black, // optional: set icon color
  ),
  label: Text(
    'View Property',
    style: TextStyle(
      color: AppColors.black,
      fontSize: tagTitle,
      fontWeight: FontWeight.w600,
    ),
  ),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryColor,
    foregroundColor: AppColors.black,    
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // optional
  ),
)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.lightGrey2,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: iconSize * 2,
              color: AppColors.lightGrey,
            ),
            kHeight(0.01),
            Text(
              'No Image Available',
              style: TextStyle(
                color: AppColors.black500,
                fontSize: detailContentTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth2),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.secondaryColor,
            size: smallIconSize,
          ),
        ),
        kWidth(0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.black500,
                  fontSize: detailContentTitle,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: tagTitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatUnitType(String unitType) {
    if (unitType.isEmpty) return 'N/A';
    return unitType.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

// Add this getter if not present in size_config.dart
extension SizeConfigExtension on double {
  double get screenHeight15 => screenHeightFactor(0.015);
}