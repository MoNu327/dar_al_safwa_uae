import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class CustomBottomSheet extends StatelessWidget {
  final String totalPrice;
  final String period;
  final VoidCallback? onWhatsAppPressed;
  final VoidCallback? onCallPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color buttonColor;
  final double height;

  const CustomBottomSheet({
    Key? key,
    this.totalPrice = "3000 OMR",
    this.period = "month",
    this.onWhatsAppPressed,
    this.onCallPressed,
    this.backgroundColor = Colors.white,
    this.textColor = AppColors.black,
    this.buttonColor = const Color(0xFF25D366),
    this.height = 80.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Price Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Total Price',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        totalPrice,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/ $period',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.7),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action Buttons
            Row(
              children: [
                // WhatsApp Button
                _buildActionButton(
                  icon: Icons.message,
                  backgroundColor: AppColors.primaryColor,
                  onPressed: onWhatsAppPressed,
                ),
                const SizedBox(width: 12),
                // Call Button
                _buildActionButton(
                  icon: Icons.phone_outlined,
                  backgroundColor: AppColors.primaryColor,
                  onPressed: onCallPressed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          // shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: AppColors.black,
          size: 24,
        ),
      ),
    );
  }
}

// Usage Example and Helper Methods
class BottomSheetHelper {
  // Method to show the bottom sheet as a modal
  static void showCustomBottomSheet({
    required BuildContext context,
    String totalPrice = "3000 OMR",
    String period = "month",
    VoidCallback? onWhatsAppPressed,
    VoidCallback? onCallPressed,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CustomBottomSheet(
        totalPrice: totalPrice,
        period: period,
        onWhatsAppPressed: onWhatsAppPressed,
        onCallPressed: onCallPressed,
      ),
    );
  }

  // Method to create a persistent bottom sheet
  static Widget buildPersistentBottomSheet({
    String totalPrice = "3000 OMR",
    String period = "month",
    VoidCallback? onWhatsAppPressed,
    VoidCallback? onCallPressed,
  }) {
    return CustomBottomSheet(
      totalPrice: totalPrice,
      period: period,
      onWhatsAppPressed: onWhatsAppPressed,
      onCallPressed: onCallPressed,
    );
  }
}
