import 'package:dar_al_safwa/presentation/controllers/bottom_navbar_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../../core/constants/custom_size.dart';
import '../../core/theme/app_colors.dart';

class BottomNavbarWidget extends StatelessWidget {
  const BottomNavbarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final BottomNavbarController bottomNavbarController =
        Get.put(BottomNavbarController());

    return Scaffold(
      body: Obx(() => bottomNavbarController
          .pages[bottomNavbarController.selectedIndex.value]),
      bottomNavigationBar: Obx(
        () => FittedBox(
          child: SalomonBottomBar(
              currentIndex: bottomNavbarController.selectedIndex.value,
              onTap: bottomNavbarController.changeIndex,
              backgroundColor: AppColors.primaryColor,
              selectedItemColor: AppColors.secondaryColor,
              unselectedItemColor: AppColors.black,
              items: [
                SalomonBottomBarItem(
                  icon: Icon(
                    Icons.home_outlined,
                    size: screenHeight * 0.018,
                  ),
                  title: Text(
                    'Home',
                    style: GoogleFonts.lato(
                      fontSize: screenHeight * 0.011,
                    ),
                  ),
                ),
                // SalomonBottomBarItem(
                //   icon: Icon(
                //     Icons.search,
                //     size: screenHeight * 0.018,
                //   ),
                //   title: Text(
                //     'Search',
                //     style: GoogleFonts.lato(
                //       fontSize: screenHeight * 0.011,
                //     ),
                //   ),
                // ),
                SalomonBottomBarItem(
                  icon: Icon(
                    Icons.dashboard_outlined,
                    size: screenHeight * 0.02,
                  ),
                  title: Text(
                    'Dashboard',
                    style: GoogleFonts.lato(
                      fontSize: screenHeight * 0.011,
                    ),
                  ),
                ),
                SalomonBottomBarItem(
                  icon: Icon(
                    Icons.chat_outlined,
                    size: screenHeight * 0.018,
                  ),
                  title: Text(
                    'Inbox',
                    style: GoogleFonts.lato(
                      fontSize: screenHeight * 0.011,
                    ),
                  ),
                ),
                SalomonBottomBarItem(
                  icon: Icon(
                    Icons.person_outlined,
                    size: screenHeight * 0.018,
                  ),
                  title: Text(
                    'Profile',
                    style: GoogleFonts.lato(
                      fontSize: screenHeight * 0.011,
                    ),
                  ),
                ),
              ]),
        ),
      ),
    );
  }
}
