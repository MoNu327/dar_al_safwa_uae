
import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:flutter/material.dart';



class CustomDashboard extends StatelessWidget {
  const CustomDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteLight,
      body: Column(
        children: [
          // Custom App Bar
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth5,
                  vertical: screenHeight2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'MAJAN',
                        style: TextStyle(
                          fontSize: appBarTitles,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    Container(
                      width: screenHeight5,
                      height: screenHeight5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.black600,
                      ),
                      child: ClipOval(
                        child: Icon(
                          Icons.person,
                          color: AppColors.white,
                          size: iconSize * 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          kHeight(0.03),

          // Menu Items
          Expanded(
            child: Column(
              children: [
                _buildMenuTile(
                  icon: Icons.person_outline,
                  title: 'My Profile',
                  onTap: () {},
                ),
                _buildMenuTile(
                  icon: Icons.home_outlined,
                  title: 'My Properties',
                  onTap: () {},
                ),
                _buildMenuTile(
                  icon: Icons.description_outlined,
                  title: 'My Documents',
                  onTap: () {},
                ),
                _buildMenuTile(
                  icon: Icons.local_activity_outlined,
                  title: 'Tickets',
                  onTap: () {},
                ),
                _buildMenuTile(
                  icon: Icons.message_outlined,
                  title: 'Messages',
                  onTap: () {},
                ),
              ],
            ),
          ),

          kHeight(0.05),

          // Sign Out Button
          Container(
            margin: EdgeInsets.symmetric(horizontal: screenWidth5),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryColor,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: screenHeight2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: H18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          kHeight(0.05),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth5,
        vertical: screenHeight1,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth5,
              vertical: screenHeight2,
            ),
            child: Row(
              children: [
                Container(
                  width: iconSize * 1.2,
                  height: iconSize * 1.2,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.secondaryColor,
                    size: iconSize * 0.8,
                  ),
                ),
                kWidth(0.04),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: H18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.black600,
                  size: smallIconSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
