import 'package:cached_network_image/cached_network_image.dart';
import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/presentation/controllers/bottom_navbar_controller.dart';
import 'package:majan/presentation/view/dashboard/controller/agent_registered_property_controller.dart';
import 'package:majan/presentation/view/dashboard/widgets/dashboard_tile_widget.dart';
import 'package:majan/presentation/view_model/localization_controller.dart';
import 'package:majan/presentation/view_model/login_controller.dart';
import 'package:majan/presentation/widgets/common_signout_button.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/presentation/widgets/language_text_button.dart';
import 'package:majan/presentation/widgets/notification_navigation_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'agent_reports.dart';

class AgentDashboard extends StatelessWidget {
  AgentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final LocalizationController localizationController = Get.find();
    final LoginController loginController = Get.put(LoginController());
    final BottomNavbarController navbarController =
        Get.put(BottomNavbarController());

    final AgentRegisteredPropertyController agentPropertyController =
        Get.put(AgentRegisteredPropertyController());
    final FirebaseAuth auth = FirebaseAuth.instance;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: Get.height * 0.1,
        title: Obx(() {
          return CustomTextWidget(
            title: localizationController.translate('title'),
            fontSize: Get.height * 0.025,
            color: AppColors.secondaryColor,
            fontWeight: FontWeight.w600,
          );
        }),
        actions: [
          // LanguageTextButton(localizationController: localizationController),
          Padding(
              padding: const EdgeInsets.all(10.0),
              child: notificationNavigation()),
          Padding(
            padding: const EdgeInsets.all(10),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == "logout") {
                  Get.defaultDialog(
                    title: "Logout",
                    middleText: "Are you sure you want to log out?",
                    textConfirm: "Yes",
                    textCancel: "No",
                    confirmTextColor: Colors.white,
                    onConfirm: () {
                      loginController.logout();
                      Get.back();
                    },
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: "logout",
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 10),
                      Text("Logout"),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                radius: screenHeight * 0.025, // Adjust size as needed
                backgroundColor:
                    AppColors.primaryColor, // Placeholder background color
                child: ClipOval(
                    child: CachedNetworkImage(
                  imageUrl: auth.currentUser?.photoURL ??
                      "https://i.postimg.cc/VLRdMxPK/profileimage.png",
                  useOldImageOnUrlChange: false,
                  width: screenWidth,
                  height: screenHeight,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) {
                    return const Icon(
                      Icons.error,
                      color: AppColors.primaryColor,
                      // size: radius ?? screenHeight5,
                    );
                  },
                )),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Get.width * 0.04,
          vertical: Get.height * 0.02,
        ),
        child: Column(
          children: [
            // Custom App Bar

            kHeight(0.01),

            // Menu Items
            Expanded(
              child: Column(
                children: [
                  buildMenuTile(
                    leading: Image.asset("assets/images/Profile.png"),
                    title: 'My Profile',
                    onTap: () {
                      navbarController.selectedIndex(3);
                    },
                  ),
                  buildMenuTile(
                    leading: Image.asset("assets/images/Properties.png"),
                    title: 'Properties',
                    onTap: () {
                      Get.toNamed('/properties');
                    },
                  ),
                  // buildMenuTile(
                  //   leading: Image.asset("assets/images/Enquiry.png"),
                  //   title: 'Enquiry',
                  //   onTap: () {
                  //     Get.toNamed('/enquiry');
                  //   },
                  // ),
                  buildMenuTile(
                    leading: Image.asset("assets/images/Enquiry.png"),
                    title: 'Enquiry',
                    onTap: () {
                      Get.to(PropertyInteractionPage());
                    },
                  ),
                  buildMenuTile(
                    leading: Image.asset("assets/images/Messages.png"),
                    title: 'Messages',
                    onTap: () {
                      navbarController.selectedIndex(2);
                    },
                  ),
                ],
              ),
            ),

            kHeight(0.05),

            // Sign Out Button
            commonSignOutButton(loginController),

            kHeight(0.05),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Navigate to add new property screen
      //     // Get.to(() => AddNewPropertyScreen());
      //   },
      //   backgroundColor: AppColors.secondaryColor,
      //   child: const Icon(Icons.add, color: Colors.white),
      // ),
    );
  }
}

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:majan/core/constants/custom_size.dart';
// import 'package:majan/core/theme/app_colors.dart';
// import 'package:majan/presentation/controllers/bottom_navbar_controller.dart';
// import 'package:majan/presentation/view/dashboard/controller/agent_registered_property_controller.dart';
// import 'package:majan/presentation/view/dashboard/widgets/dashboard_tile_widget.dart';
// import 'package:majan/presentation/view_model/localization_controller.dart';
// import 'package:majan/presentation/view_model/login_controller.dart';
// import 'package:majan/presentation/widgets/common_signout_button.dart';
// import 'package:majan/presentation/widgets/custom_text_widget.dart';
// import 'package:majan/presentation/widgets/language_text_button.dart';
// import 'package:majan/presentation/widgets/notification_navigation_widget.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'agent_reports.dart';

// class AgentDashboard extends StatefulWidget {
//   const AgentDashboard({super.key});

//   @override
//   State<AgentDashboard> createState() => _AgentDashboardState();
// }

// class _AgentDashboardState extends State<AgentDashboard> {
//   final LocalizationController localizationController = Get.find();
//   final LoginController loginController = Get.put(LoginController());
//   final BottomNavbarController navbarController = Get.put(BottomNavbarController());
//   final AgentRegisteredPropertyController agentPropertyController = Get.put(AgentRegisteredPropertyController());
//   final FirebaseAuth auth = FirebaseAuth.instance;

//   @override
//   void initState() {
//     super.initState();
//     _updateFcmToken();
//   }

//   Future<void> _updateFcmToken() async {
//     try {
//       final String? fcmToken = await FirebaseMessaging.instance.getToken();
//       final String? uid = auth.currentUser?.uid;

//       if (uid != null && fcmToken != null) {
//         await agentPropertyController.loadFcmTokenforagent(uid, fcmToken);
//       } else {
//         debugPrint("⚠️ UID or FCM Token is null");
//       }
//     } catch (e) {
//       debugPrint("❌ Error in updating FCM token: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         toolbarHeight: Get.height * 0.1,
//         title: Obx(() {
//           return CustomTextWidget(
//             title: localizationController.translate('title'),
//             fontSize: Get.height * 0.025,
//             color: AppColors.secondaryColor,
//             fontWeight: FontWeight.w600,
//           );
//         }),
//         actions: [
//           Padding(
//               padding: const EdgeInsets.all(10.0),
//               child: notificationNavigation()),
//           Padding(
//             padding: const EdgeInsets.all(10),
//             child: PopupMenuButton<String>(
//               onSelected: (value) {
//                 if (value == "logout") {
//                   Get.defaultDialog(
//                     title: "Logout",
//                     middleText: "Are you sure you want to log out?",
//                     textConfirm: "Yes",
//                     textCancel: "No",
//                     confirmTextColor: Colors.white,
//                     onConfirm: () {
//                       loginController.logout();
//                       Get.back();
//                     },
//                   );
//                 }
//               },
//               itemBuilder: (context) => [
//                 const PopupMenuItem(
//                   value: "logout",
//                   child: Row(
//                     children: [
//                       Icon(Icons.logout, color: Colors.red),
//                       SizedBox(width: 10),
//                       Text("Logout"),
//                     ],
//                   ),
//                 ),
//               ],
//               child: CircleAvatar(
//                 radius: screenHeight * 0.025,
//                 backgroundColor: AppColors.primaryColor,
//                 child: ClipOval(
//                   child: CachedNetworkImage(
//                     imageUrl: auth.currentUser?.photoURL ??
//                         "https://i.postimg.cc/VLRdMxPK/profileimage.png",
//                     useOldImageOnUrlChange: false,
//                     width: screenWidth,
//                     height: screenHeight,
//                     fit: BoxFit.cover,
//                     errorWidget: (context, url, error) {
//                       return const Icon(Icons.error, color: AppColors.primaryColor);
//                     },
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: EdgeInsets.symmetric(
//           horizontal: Get.width * 0.04,
//           vertical: Get.height * 0.02,
//         ),
//         child: Column(
//           children: [
//             kHeight(0.01),
//             Expanded(
//               child: Column(
//                 children: [
//                   buildMenuTile(
//                     leading: Image.asset("assets/images/Profile.png"),
//                     title: 'My Profile',
//                     onTap: () {
//                       navbarController.selectedIndex(3);
//                     },
//                   ),
//                   buildMenuTile(
//                     leading: Image.asset("assets/images/Properties.png"),
//                     title: 'Properties',
//                     onTap: () {
//                       Get.toNamed('/properties');
//                     },
//                   ),
//                   buildMenuTile(
//                     leading: Image.asset("assets/images/Enquiry.png"),
//                     title: 'Enquiry',
//                     onTap: () {
//                       Get.to(PropertyInteractionPage());
//                     },
//                   ),
//                   buildMenuTile(
//                     leading: Image.asset("assets/images/Messages.png"),
//                     title: 'Messages',
//                     onTap: () {
//                       navbarController.selectedIndex(2);
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             kHeight(0.05),
//             commonSignOutButton(loginController),
//             kHeight(0.05),
//           ],
//         ),
//       ),
//     );
//   }
// }
