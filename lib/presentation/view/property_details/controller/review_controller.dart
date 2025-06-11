import 'package:dar_al_safwa/data/model/property_user_review_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/repositories/api_services.dart';

class ReviewController extends GetxController {
  var reviews = <Map<String, dynamic>>[].obs;
  final ApiService apiService = ApiService();

  @override
  void onInit() {
    super.onInit();
    loadDummyReviews();
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

  void loadDummyReviews() {
    List<Map<String, dynamic>> dummyReviews = [
      {
        'id': '1',
        'userName': 'Jonathan Drew',
        'userImage': 'https://randomuser.me/api/portraits/men/32.jpg',
        'rating': 4.5,
        'timestamp': '2023-11-15T14:30:00Z',
        'description':
            'Great property with amazing views. The location is perfect and the amenities are top-notch.',
      },
      {
        'id': '2',
        'userName': 'Emily Sullivan',
        'userImage': 'https://randomuser.me/api/portraits/women/44.jpg',
        'rating': 5.0,
        'timestamp': '2023-10-28T09:15:00Z',
        'description':
            'Absolutely loved our stay! The property was clean, modern, and had everything we needed.',
      },
      {
        'id': '3',
        'userName': 'Michael Carter',
        'userImage': 'https://randomuser.me/api/portraits/men/67.jpg',
        'rating': 3.8,
        'timestamp': '2023-09-05T16:45:00Z',
        'description':
            'Good overall experience, but the parking was a bit tight for our SUV.',
      },
      {
        'id': '4',
        'userName': 'Olivia Bennett',
        'userImage': 'https://randomuser.me/api/portraits/women/28.jpg',
        'rating': 4.2,
        'timestamp': '2023-08-12T11:20:00Z',
        'description':
            'Beautiful property with excellent customer service. Would definitely recommend!',
      },
    ];

    reviews.value = dummyReviews;
  }
}
