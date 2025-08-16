import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/presentation/view/property_details/controller/review_controller.dart';
import 'package:majan/presentation/view_model/firebase_auth_controller.dart';
import 'package:majan/presentation/view_model/login_controller.dart';
import 'package:majan/presentation/widgets/custom_snackbar.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controller/property_details_controller.dart';

class Reviews extends StatelessWidget {
  final ReviewController reviewController = Get.put(ReviewController());
  final AuthService authService = Get.find<AuthService>();
  final TextEditingController commentController = TextEditingController();
  final RxDouble userRating = 0.0.obs;
  Reviews({super.key});
  FirebaseAuth auth = FirebaseAuth.instance;
  final PropertyDetailsController propertyDetailsController =
      Get.find<PropertyDetailsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // Reviews List (now at the top)
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: screenHeight1,
              ),
              child: Obx(() => ListView.builder(
                    itemCount: reviewController.reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviewController.reviews[index];
                      final date = DateTime.parse(review.date ?? "");
                      final formattedDate =
                          DateFormat('MMM dd, yyyy').format(date);

                      return Padding(
                        padding: EdgeInsets.only(bottom: screenHeight1),
                        child: ReviewCard(
                          userName: review.user?.name ?? "User",
                          userImage: review.user?.avatar ?? "",
                          rating: review.rating ?? 0.0,
                          date: formattedDate,
                          description: review.comment ?? "",
                        ),
                      );
                    },
                  )),
            ),
          ),

          // Add Review Section
          authService.userRole.value == 'agent'
              ? SizedBox.shrink()
              : _buildAddReviewSection(),
        ],
      ),
    );
  }

  Widget _buildAddReviewSection() {
    final currentUser = auth.currentUser;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppColors.lightGrey.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth1,
        vertical: screenHeight1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(
                  currentUser?.photoURL != null
                      ? currentUser!.photoURL!
                      : 'https://randomuser.me/api/portraits/men/1.jpg',
                ),
              ),
              kWidth(0.03),
              Expanded(
                child: Obx(
                  () => RatingBar.builder(
                    initialRating: userRating.value,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: screenHeight * 0.025,
                    itemPadding: EdgeInsets.only(right: screenWidth * 0.01),
                    itemBuilder: (context, _) => Icon(
                      Icons.star,
                      color: userRating.value > 0
                          ? AppColors.primaryColor
                          : AppColors.lightGrey,
                    ),
                    onRatingUpdate: (rating) => userRating.value = rating,
                    glowColor: AppColors.primaryColor.withOpacity(0.2),
                  ),
                ),
              ),
            ],
          ),
          kHeight(0.01),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: commentController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenHeight * 0.015,
                      ),
                      hintText: 'Share your experience...',
                      hintStyle: TextStyle(
                        color: AppColors.lightGrey,
                        fontSize: screenHeight * 0.016,
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: AppColors.lightGrey,
                          width: .5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: AppColors.lightGrey,
                          width: .5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: AppColors.primaryColor,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              kWidth(0.02),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryColor.withOpacity(0.2),
                      spreadRadius: 0,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (userRating.value > 0 &&
                        commentController.text.isNotEmpty) {
                      String comments = commentController.text.trim();
                      double rating = userRating.value.toDouble();
                      int? propertyId =
                          propertyDetailsController.property.value?.id;

                      String currentUserId = auth.currentUser!.uid;
                      reviewController.postReview(
                          uid: currentUserId,
                          propertyId: propertyId ?? 0,
                          rating: rating,
                          comments: comments);
                      // reviewController.reviews.insert(
                      //   0,
                      //   {
                      //     'id':
                      //         DateTime.now().millisecondsSinceEpoch.toString(),
                      //     'userName': 'You',
                      //     'userImage':
                      //         'https://randomuser.me/api/portraits/men/1.jpg',
                      //     'rating': userRating.value,
                      //     'timestamp': DateTime.now().toIso8601String(),
                      //     'description': commentController.text,
                      //   },
                      // );
                      commentController.clear();
                      userRating.value = 0.0;
                    } else {
                      CustomSnackbar.show(
                        title: 'Incomplete Review',
                        message: 'Please add both rating and comment',
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth4,
                      vertical: screenHeight1,
                    ),
                    elevation: 0,
                  ),
                  child: CustomTextWidget(
                    title: 'Post',
                    fontSize: screenHeight * 0.016,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final String userName;
  final String userImage;
  final double rating;
  final String date;
  final String description;

  const ReviewCard({
    super.key,
    required this.userName,
    required this.userImage,
    required this.rating,
    required this.date,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: .5, color: AppColors.lightGrey),
      ),
      padding: EdgeInsets.symmetric(
        vertical: screenHeight2,
        horizontal: screenWidth2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(userImage),
              ),
              kWidth(0.03),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextWidget(
                    title: userName,
                    fontSize: screenHeight * 0.02,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                  kHeight(0.002),
                  CustomTextWidget(
                    title: date,
                    fontSize: screenHeight * 0.013,
                    color: AppColors.lightGrey,
                  )
                ],
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth2,
                  vertical: screenHeight05,
                ),
                decoration: BoxDecoration(
                  color: AppColors.splashBackgroundColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextWidget(
                      title: rating.toString(),
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryColor,
                      fontSize: screenHeight * 0.015,
                    ),
                    kWidth(0.01),
                    Icon(
                      Icons.star,
                      color: AppColors.secondaryColor,
                      size: screenHeight2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          kHeight(0.01),
          CustomTextWidget(
            title: description,
            fontSize: screenHeight * 0.015,
            color: AppColors.black600,
            maxLines: 3,
          )
        ],
      ),
    );
  }
}
