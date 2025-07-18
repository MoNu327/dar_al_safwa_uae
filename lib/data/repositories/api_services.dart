import 'dart:io';

import 'package:dar_al_safwa/data/model/user_data_submission_model.dart';
import 'package:dio/dio.dart';
import '../datasources/api_client.dart';
import '../model/agent_properties_response_model.dart';
import '../model/compliant_model.dart';
import '../model/property_user_review_model.dart';
import '../model/search_property_model.dart';
import '../model/tenant_compliant_subtitle.dart';

class ApiService {
  final ApiClient apiClient = ApiClient();

  ApiService();

  Future<Response> getComplaintCategories() async {
    try {
      final response = await apiClient.request(
        "user/complaint",  // ✅ Dynamic UID
        method: "get",
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getSubtitleComplaintCategories(
      ComplaintSubCategoriesRequest complaintSubCategoriesRequest) async {
    try {
      final response = await apiClient.request(
        "user/complaintSubtitles",
        method: "post",
        data: complaintSubCategoriesRequest.toJson(),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getDynamicImage() async {
    try {
      final response = await apiClient.request(
        "app-image",
        method: "get",
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // register complaint
  Future<Response> insertComplaint(
      CreateComplaintRequest createComplaintRequest) async {
    try {
      final response = await apiClient.request(
        "user/complaintform",
        method: "post",
        data: createComplaintRequest.toJson(),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Response> updateComplaint({
  required int complaintId,
  required int status,
  required String reply,
  required int amountPaid,
  required int amountStatus,
  List<File>? images,
}) async {
  try {
    // Prepare multipart form data
    FormData formData = FormData.fromMap({
      'complaint_id': complaintId,
      'status': status,
      'reply': reply,
      'amount_paid': amountPaid,
      'amount_status': amountStatus,
      if (images != null)
        for (int i = 0; i < images.length; i++)
          'images[$i]': await MultipartFile.fromFile(
            images[i].path,
            filename: images[i].path.split('/').last,
          ),
    });

    final response = await apiClient.request(
      "technician/update-complaint-status", // replace with your actual endpoint
      method: "post",
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return response;
  } catch (e) {
    rethrow;
  }
}

//Home Section
  //banner
  Future<Response> getPropertyBanner() async {
    try {
      final response = await apiClient.request(
        "propertyBanner",
        method: "get",
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

// fetch location in the header dropdown
  Future<Response> getLocations() async {
    try {
      final response = await apiClient.request(
        "locations",
        method: "get",
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  //featured properties
  Future<Response> getFeaturedProperties() async {
    try {
      final response = await apiClient.request(
        "featuredProperties",
        method: "get",
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  //popular properties
  Future<Response> getPopularProperties() async {
    try {
      final response = await apiClient.request(
        "popularProperties",
        method: "get",
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // search drop down
  Future<Response> getSearchDropDown() async {
    try {
      final response = await apiClient.request(
        "search-dropdown",
        method: "get",
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getPropertyDetails(int propertyId) async {
    try {
      final response = await apiClient.request(
        "propertyDetails/$propertyId",
        method: "get",
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getAgentPropertyList() async {
    try {
      final response = await apiClient.request("agent-properties",
          method: "post", data: {"uid": "jznkHrlfH5eFp2Vsc2Jvi7gSd5m2"});

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getAgentPropertiesSearch() async {
    // API Refining Needed
    try {
      final response = await apiClient
          .request("agent-searchproperties", method: "post", data: {
        "uid": "jznkHrlfH5eFp2Vsc2Jvi7gSd5m2",
        "title": "b",
        "city": "",
        "state": "Muscat"
      });

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> postPropertyInterest(
      String uid,
      int PropertyId,
      int unitType,
      int count,
      String comments,
      int enqtype,
      String mobileNumber) async {
    // API Refining Needed
    try {
      final response = await apiClient.request(
        "storeenquiry",
        method: "post",
        data: {
          "uid": uid,
          "propertyid": PropertyId,
          "unittype": unitType,
          "count": count,
          "comments": comments,
          "enqtype": enqtype,
          "mobile": mobileNumber
        },
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  //proerty review post api

  Future<Response> propertyReviewPost(
      PropertyUserReviewRequest propertyUserReviewRequest) async {
    try {
      final response = await apiClient.request(
        "propertyReviewStatus",
        method: "post",
        data: propertyUserReviewRequest,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // get search result
  Future<Response> getPropertySearchResult(
      PropertySearchResultRequest propertySearchResultRequest) async {
    try {
      final response = await apiClient.request(
        "properties/search",
        method: "post",
        data: propertySearchResultRequest.toJson(),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Submit User Details for Booking result
  Future<Response> submitUserDetailsAndDoc(
      UserDataSubmissionModel userDataSubmission) async {
    try {
      final response = await apiClient.request(
        "storebooking",
        method: "post",
        data: userDataSubmission.toJson(),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Submit User Details for Booking result
  Future<Response> fetchingAgentChatReports(String uid) async {
    try {
      final response = await apiClient.request(
        "chatListByAgent",
        method: "post",
        data: {"uid": uid},
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }
    Future<Response> getMyProperties(String uid) async {
  try {
    final response = await apiClient.request(
      "tenant/properties",
      method: "post",
      data: {
        "uid": "8JnK2Se9sBaHJFrPi6brY0ajme53"
      },
    );

    return response;
  } catch (e) {
    rethrow;
  }
}
}