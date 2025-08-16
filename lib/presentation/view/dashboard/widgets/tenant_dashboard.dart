import 'package:cached_network_image/cached_network_image.dart';
import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/routes/app_route.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/presentation/controllers/bottom_navbar_controller.dart';
import 'package:majan/presentation/view/dashboard/controller/tenant_property_controller.dart';
import 'package:majan/presentation/view/dashboard/widgets/custom_tenant_property_detail_widget.dart';
import 'package:majan/presentation/view/dashboard/widgets/custom_tenant_property_list_widget.dart';
import 'package:majan/presentation/view/dashboard/widgets/dashboard_tile_widget.dart';
import 'package:majan/presentation/view/dashboard/widgets/tenant_properties_list.dart';
import 'package:majan/presentation/view/dashboard/widgets/tenants_tickets_list_widget.dart';
import 'package:majan/presentation/view_model/localization_controller.dart';
import 'package:majan/presentation/view_model/login_controller.dart';
import 'package:majan/presentation/widgets/common_signout_button.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/presentation/widgets/language_text_button.dart';
import 'package:majan/presentation/widgets/notification_navigation_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class TenantDashboard extends StatelessWidget {
  const TenantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final BottomNavbarController navBarController =
        Get.put(BottomNavbarController());

    final LocalizationController localizationController = Get.find();
    final LoginController loginController = Get.put(LoginController());

    final FirebaseAuth auth = FirebaseAuth.instance;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Get.offAllNamed(AppRoute.navbar);
        }
      },
      child: Scaffold(
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
                        loginController.logout(); // Call your logout function
                        Get.back(); // Close dialog
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
                // child: const CircleAvatar(
                //   radius: 20,
                //   backgroundImage: AssetImage('assets/images/person.png'),
                // ),
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
          padding: const EdgeInsets.all(8.0),
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
                        navBarController.selectedIndex(3);
                      },
                    ),
                    buildMenuTile(
                      leading: Image.asset("assets/images/Properties.png"),
                      title: 'My Properties',
                      onTap: () {
                        Get.to(() => TenantPropertiesList());
                       }

                    ),
                    buildMenuTile(
                      leading: Image.asset("assets/images/Documents.png"),
                      title: 'My Documents',
                      onTap: () {
                        Get.toNamed("/tenantDocumentsList");
                      },
                    ),
                    buildMenuTile(
                      leading: Image.asset("assets/images/Tickets.png"),
                      title: 'Tickets',
                      onTap: () {
                        Get.to(TenantsTicketsListWidget());
                      },
                    ),
                    buildMenuTile(
                      leading: Image.asset("assets/images/Messages.png"),
                      title: "Messages",
                      onTap: () {
                        navBarController.selectedIndex(2);
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
      ),
    );
  }
}
