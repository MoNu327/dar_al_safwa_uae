class PropertyUserReviewRequest {
  final String uid;
  final int propertyId;
  final double rating;
  final String comments;

  PropertyUserReviewRequest({
    required this.uid,
    required this.propertyId,
    required this.rating,
    required this.comments,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'property_id': propertyId,
      'rating': rating,
      'comments': comments,
    };
  }

  factory PropertyUserReviewRequest.fromJson(Map<String, dynamic> json) {
    return PropertyUserReviewRequest(
      uid: json['uid'] as String,
      propertyId: json['property_id'] as int,
      rating: (json['rating'] as num).toDouble(),
      comments: json['comments'] as String,
    );
  }
}

// get user property review
class GetPropertyUserReviewRequest {
  final String uid;
  final int propertyId;

  GetPropertyUserReviewRequest({
    required this.uid,
    required this.propertyId,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'property_id': propertyId,
    };
  }

  factory GetPropertyUserReviewRequest.fromJson(Map<String, dynamic> json) {
    return GetPropertyUserReviewRequest(
      uid: json['uid'] as String,
      propertyId: json['property_id'] as int,
    );
  }
}
