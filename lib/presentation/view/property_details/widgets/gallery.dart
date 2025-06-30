import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/routes/app_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_snackbar.dart';
import '../../../widgets/loader_widget.dart';
import '../controller/property_details_controller.dart';
import 'price_bottom_sheet.dart';

class Gallery extends StatelessWidget {
  Gallery({super.key});

  final PropertyDetailsController propertyDetailsController =
      Get.find<PropertyDetailsController>();

  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final galleryImages =
        propertyDetailsController.property.value?.imageGallery;
    final property = propertyDetailsController.property.value;

    return Scaffold(
      bottomSheet: CustomBottomSheet(
        onCallPressed: () {
          propertyDetailsController.showUnitTypeBottomSheetForCall(
              property?.agent?.phone ?? "9544418765", property?.id as int ?? 0);
          // propertyDetailsController
          //     .callToAgent(property.agent?.phone ?? "");
        },
        onWhatsAppPressed: () {
          auth.currentUser == null
              ? Get.toNamed(AppRoute.signupWarning)
              : auth.currentUser != null &&
                      auth.currentUser?.displayName != null
                  ? propertyDetailsController.showUnitTypeBottomSheetForChat(
                      property?.agent?.email ?? "test@gmail.com",
                      property?.id as int ?? 0,
                      property?.title?.en ?? "")
                  : auth.currentUser?.email == null
                      ? propertyDetailsController
                          .showUnitTypeBottomSheetForChat(
                              property?.agent?.email ?? "test@gmail.com",
                              41,
                              property?.title?.en ?? "")
                      : CustomSnackbar.show(
                          title: "Failed",
                          message:
                              "Currently, the agent is unable to connect.");
        },
        height: 80,
      ),
      backgroundColor: AppColors.white,
      body: _buildGalleryContent(galleryImages),
    );
  }

  Widget _buildGalleryContent(List<String>? galleryImages) {
    // Handle empty or null gallery
    if (galleryImages == null || galleryImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No images available',
              style: Get.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: screenHeight * 0.02,
        left: screenWidth2,
        right: screenWidth2,
      ),
      child: GridView.builder(
        padding:
            EdgeInsets.only(bottom: Get.height * 0.1, top: Get.height * 0.015),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: galleryImages.length,
        itemBuilder: (context, index) =>
            _buildGalleryItem(galleryImages, index),
      ),
    );
  }

  Widget _buildGalleryItem(List<String> galleryImages, int index) {
    return GestureDetector(
      onTap: () => _openFullScreenGallery(galleryImages, index),
      child: Hero(
        tag: galleryImages[index],
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: galleryImages[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildPlaceholder(),
            errorWidget: (context, url, error) => _buildErrorWidget(),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.lightGrey,
      child: const Center(
        child: CustomLoaderWidget(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  void _openFullScreenGallery(List<String> images, int initialIndex) {
    Get.toNamed(
      AppRoute.viewGallery,
      arguments: {
        'images': images,
        'initialIndex': initialIndex,
      },
    );
  }
}
