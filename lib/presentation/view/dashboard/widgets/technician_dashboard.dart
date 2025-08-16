import 'package:cached_network_image/cached_network_image.dart';
import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/presentation/view/dashboard/widgets/dashboard_tile_widget.dart';
import 'package:majan/presentation/view/dashboard/widgets/technican_history_ticket.dart';
import 'package:majan/presentation/view_model/localization_controller.dart';
import 'package:majan/presentation/view_model/login_controller.dart';
import 'package:majan/presentation/widgets/common_signout_button.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/presentation/widgets/notification_navigation_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TechnicianDashboard extends StatelessWidget {
  const TechnicianDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final LocalizationController localizationController = Get.find();
    final LoginController loginController = Get.put(LoginController());
    final FirebaseAuth auth = FirebaseAuth.instance;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: Get.height * 0.1,
        title: CustomTextWidget(
          title: "Technician Dashboard", // ✅ Set title directly
          fontSize: Get.height * 0.025,
          color: AppColors.secondaryColor,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: notificationNavigation(),
          ),
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
                radius: screenHeight * 0.025,
                backgroundColor: AppColors.primaryColor,
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: auth.currentUser?.photoURL ??
                        "https://i.postimg.cc/VLRdMxPK/profileimage.png",
                    width: screenWidth,
                    height: screenHeight,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Icon(
                      Icons.error,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            kHeight(0.01),
            Expanded(
              child: Column(
                children: [
                  buildMenuTile(
                    leading: Image.asset("assets/images/Profile.png"),
                    title: 'My Profile',
                    onTap: () {
                      // ✅ Navigate to Technician Profile Screen
                      Get.toNamed('/technician-profile');
                    },
                  ),
                  buildMenuTile(
                    leading: Image.asset("assets/images/Tickets.png"),
                    title: 'Tickets',
                    onTap: () {
                      Get.toNamed('/technician-tickets');
                    },
                  ),
                  buildMenuTile(
                    leading: Icon(Icons.history, color: AppColors.secondaryColor),
                    title: 'History',
                    onTap: () {
                      // ✅ Navigate to Technician Profile Screen
                      Get.to(TechnicianResolvedTicketsListWidget());
                    },
                  ),
                ],
              ),
            ),
            kHeight(0.05),
            commonSignOutButton(loginController),
            kHeight(0.05),
          ],
        ),
      ),
    );
  }
}
