import 'package:majan/data/model/property_details_model.dart';
import 'package:majan/data/model/property_user_review_model.dart';
import 'package:majan/presentation/view/property_details/controller/property_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/repositories/api_services.dart';

class ReviewController extends GetxController {
  var reviews = <RecentReview>[].obs;
  final ApiService apiService = ApiService();

  final propertiesController = Get.put(PropertyDetailsController());

  @override
  void onInit() {
    super.onInit();
    loadReviews();
  }

  Future<void> postReview({
    required String uid,
    required int propertyId,
    required double rating,
    required String comments,
  }) async {
    try {
      final propertyUserReview = PropertyUserReviewRequest(
        uid: uid,
        propertyId: propertyId,
        rating: rating,
        comments: comments,
      );
      final response = await apiService.propertyReviewPost(propertyUserReview);

      if (response.statusCode == 200) {
        debugPrint("User review added successfully");
      }
    } catch (e) {
      // Handle error (log, show snackbar, etc.)
      Get.snackbar('Error', 'Failed to post review: $e');
    }
  }

  void loadReviews() {
    List<RecentReview> dummyReviews = propertiesController
            .property?.value?.reviews?.recentReviews as List<RecentReview> ??
        [];

    reviews.value = dummyReviews;
  }
}
