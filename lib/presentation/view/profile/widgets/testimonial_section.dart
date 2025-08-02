import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TestimonialSection extends StatelessWidget {
  const TestimonialSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomTextWidget(
            title: 'Testimonials',
            fontSize: H18,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
          kHeight(0.01),
          Divider(
            color: AppColors.lightGrey.withValues(alpha: 0.2),
            indent: 20,
            thickness: 1,
            endIndent: 20,
          ),
          kHeight(0.02),
          // Horizontal scrolling section
          SizedBox(
            height: screenHeight * 0.28, // Fixed height for horizontal scroll
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (int i = 0; i < 4; i++) ...[
                  SizedBox(
                    width: screenWidth *
                        0.4, // Fixed width for each testimonial card
                    child: _buildTestimonialItem(
                      i == 3
                          ? 'We\'ve been using Untitled to kick start every new project...'
                          : ['StayPlus', 'SpyPlus', 'Stopping'][i],
                      isReview: i == 3,
                    ),
                  ),
                  if (i < 3)
                    SizedBox(width: screenWidth4), // Spacing between items
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialItem(String text, {bool isReview = false}) {
    return Container(
      padding: EdgeInsets.all(screenWidth4),
      decoration: BoxDecoration(
        color: AppColors.whiteLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CustomTextWidget(
            title: "SissyPhus",
            fontSize: tagTitle,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            overflow: TextOverflow.ellipsis,
          ),
          CustomTextWidget(
            title: text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            overflow: TextOverflow.ellipsis,
            maxLines: 8,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.black600,
            backgroundImage: NetworkImage(
                "https://images.pexels.com/photos/5682847/pexels-photo-5682847.jpeg?auto=compress&cs=tinysrgb&w=400"),
          ),
          const SizedBox(height: 8),
          CustomTextWidget(
            title: "Candice Wu",
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
            overflow: TextOverflow.ellipsis,
          ),
          CustomTextWidget(
            title: "Product Manager, SissyPhus",
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
