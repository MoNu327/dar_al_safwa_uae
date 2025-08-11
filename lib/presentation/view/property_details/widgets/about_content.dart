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
import 'package:latlong2/latlong.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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

                  CustomBottomSheet(
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
  if (value is int || value is String) return value.toString();
  // if (value is AreaValue) return value.formatted?.en ?? '';
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

  // Widget _buildAgentActions(PropertyDetailsController controler) {
  //   final property = controler.property.value;

  //   final gmail = property?.agent?.email ?? "teat@gmail.com";
  //   final phone = property?.agent?.phone ?? "9544418765";
  //   final propertyId = property?.id ?? "0";
  //   final propertyName = property?.title?.en ?? "0";
  //   final unitId = property?.unitTypes?.data?.first.unitType?.name?.en ?? "0";

  //   return Row(
  //     spacing: Get.width * 0.02,
  //     children: [
  //       InkWell(
  //         onTap: () {
  //           auth.currentUser == null
  //               ? Get.toNamed(AppRoute.signupWarning)
  //               : auth.currentUser != null &&
  //                       auth.currentUser?.displayName != null
  //                   ? propertyDetailsController.navigateToAgentChat(
  //                       "$gmail", "$propertyId", "$propertyName", "$unitId")
  //                   : auth.currentUser?.email == null
  //                       ? propertyDetailsController.navigateToAgentChat(
  //                           "teat@gmail.com", "0", "Riverview Retreat", "")
  //                       : CustomSnackbar.show(
  //                           title: "Failed",
  //                           message:
  //                               "Currently, the agent is unable to connect.");
  //         },
  //         child: CircleAvatar(
  //           backgroundColor: AppColors.whiteLight,
  //           radius: Get.height * 0.026,
  //           child: Icon(
  //             Icons.message,
  //             color: AppColors.secondaryColor,
  //             size: Get.height * 0.023,
  //           ),
  //         ),
  //       ),
  //       InkWell(
  //         onTap: () {
  //           propertyDetailsController.callToAgent(phone);
  //         },
  //         child: CircleAvatar(
  //           backgroundColor: AppColors.whiteLight,
  //           radius: Get.height * 0.026,
  //           child: Icon(
  //             Icons.call,
  //             color: AppColors.secondaryColor,
  //             size: Get.height * 0.023,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

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
                            gmail, "41", propertyName)
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

  // Widget _buildVideoTourSection() {
  //   return Container(
  //     width: double.infinity,
  //     height: Get.height * 0.25,
  //     decoration: BoxDecoration(
  //       color: AppColors.redColor,
  //       borderRadius: BorderRadius.circular(16),
  //     ),
  //     child: Stack(
  //       children: [
  //         Obx(() => videoController.isInitialized.value
  //             ? ClipRRect(
  //                 borderRadius: BorderRadius.circular(16),
  //                 child: VideoPlayer(videoController.videoPlayerController),
  //               )
  //             : const Center(child: CircularProgressIndicator())),
  //         Positioned(
  //           bottom: 5,
  //           left: 8,
  //           child: ElevatedButton(
  //             onPressed: () {},
  //             child: const Text("View All"),
  //           ),
  //         ),
  //         const Padding(
  //           padding: EdgeInsets.all(16),
  //           child: CustomTextWidget(
  //             title: "Watch the video for taking your\n decision easily.",
  //             color: AppColors.white,
  //           ),
  //         )
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildYoutubeViewerSection(String youtubeUrl) {
  //   final videoController = Get.find<VideoController>();

  //   if (youtubeUrl.isNotEmpty && !videoController.isYoutubeInitialized.value) {
  //     videoController.initializeYoutubePlayerFromUrl(youtubeUrl);
  //   }

  //   return Container(
  //     width: double.infinity,
  //     height: Get.height * 0.24,
  //     margin: const EdgeInsets.only(bottom: 16),
  //     decoration: BoxDecoration(
  //       color: AppColors.primaryColor,
  //       borderRadius: BorderRadius.circular(16),
  //     ),
  //     child: Stack(
  //       children: [
  //         // YouTube Player
  //         Obx(() {
  //           if (videoController.isYoutubeInitialized.value &&
  //               videoController.youtubeController != null) {
  //             return ClipRRect(
  //               borderRadius: BorderRadius.circular(16),
  //               child: YoutubePlayer(
  //                 controller: videoController.youtubeController!,
  //                 showVideoProgressIndicator: true,
  //                 progressIndicatorColor: AppColors.primaryColor,
  //                 progressColors: ProgressBarColors(
  //                   playedColor: AppColors.primaryColor,
  //                   handleColor: AppColors.primaryColor,
  //                 ),
  //                 thumbnail: propertyDetailsController
  //                             .property.value?.youtubeVideo?.thumbnail !=
  //                         null
  //                     ? Image.network(
  //                         propertyDetailsController
  //                             .property.value!.youtubeVideo!.thumbnail!,
  //                         fit: BoxFit.cover,
  //                       )
  //                     : const SizedBox.shrink(),
  //                 onReady: () {
  //                   debugPrint('YouTube player onReady called');
  //                   videoController.debugMessage.value = 'Player ready!';
  //                 },
  //               ),
  //             );
  //           } else {
  //             return Container(
  //               decoration: BoxDecoration(
  //                 color: Colors.black54,
  //                 borderRadius: BorderRadius.circular(16),
  //               ),
  //               child: Center(
  //                 child: Column(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     const CircularProgressIndicator(color: Colors.white),
  //                     const SizedBox(height: 16),
  //                     Obx(() => Padding(
  //                           padding: const EdgeInsets.all(16.0),
  //                           child: Text(
  //                             videoController.debugMessage.value,
  //                             style: const TextStyle(
  //                               color: Colors.white,
  //                               fontSize: 12,
  //                             ),
  //                             textAlign: TextAlign.center,
  //                           ),
  //                         )),
  //                     const SizedBox(height: 16),
  //                     ElevatedButton(
  //                       onPressed: videoController.retryYoutubeInitialization,
  //                       child:
  //                           const Text('Retry', style: TextStyle(fontSize: 10)),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           }
  //         }),

  //         // Mute Button
  //         Positioned(
  //           top: 8,
  //           left: 8,
  //           child: Obx(() => GestureDetector(
  //                 onTap: videoController.toggleMute,
  //                 child: Container(
  //                   padding: const EdgeInsets.all(6),
  //                   decoration: BoxDecoration(
  //                     color: Colors.black54,
  //                     shape: BoxShape.circle,
  //                   ),
  //                   child: Icon(
  //                     videoController.isMuted.value
  //                         ? Icons.volume_off
  //                         : Icons.volume_up,
  //                     color: Colors.white,
  //                     size: 20,
  //                   ),
  //                 ),
  //               )),
  //         ),

  //         // View More Button
  //         Positioned(
  //           top: 8,
  //           right: 8,
  //           child: SizedBox(
  //             height: screenHeight * 0.04,
  //             width: screenWidth * 0.25,
  //             child: ElevatedButton(
  //               onPressed: () {
  //                 if (youtubeUrl.isNotEmpty) {
  //                   videoController.launchYouTubeVideo(youtubeUrl);
  //                 }
  //               },
  //               style: ElevatedButton.styleFrom(
  //                 shape: StadiumBorder(),
  //                 padding: EdgeInsets.all(4),
  //                 backgroundColor: AppColors.secondaryColor,
  //               ),
  //               child: CustomTextWidget(
  //                 fontSize: tagTitle,
  //                 title: "View More",
  //                 color: AppColors.primaryColor,
  //               ),
  //             ),
  //           ),
  //         ),

  //         // Information Text
  //         Positioned(
  //           top: 8,
  //           left: 48,
  //           child: Container(
  //             padding: const EdgeInsets.all(8),
  //             decoration: BoxDecoration(
  //               color: Colors.black54,
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //             child: const Text(
  //               "Watch our YouTube videos\nfor more information.",
  //               style: TextStyle(color: Colors.white, fontSize: 12),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
