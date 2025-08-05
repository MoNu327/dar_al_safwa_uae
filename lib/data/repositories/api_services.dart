import 'dart:convert';
import 'dart:io';

import 'package:dar_al_safwa/data/model/ticket_list_response_model.dart';
import 'package:dar_al_safwa/data/model/user_data_submission_model.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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


//   Future<Response> getFullComplaintDetails(String complaintId) async {
//   try {
//     final response = await apiClient.request(
//       "complaint-details",  // Your endpoint
//       method: "get",
//       data: {'complaint_id': complaintId},
//     );

//     return response;
//   } catch (e) {
//     rethrow;
//   }
// }
 

   Future<Response> getFullComplaintDetails(String complaintId) async {
  try {
    final response = await apiClient.request(
      "complaint-detailscopy",  // Your endpoint
      method: "post",
      data: {'complaint_id': complaintId},
    );

    return response;
  } catch (e) {
    rethrow;
  }
}
 
  Future<Response> getTechnicanHistory(String complaintId) async {
  try {
    print("📤 Sending request to technician-resolved-complaints with id: $complaintId");

    final response = await apiClient.request(
      "technician-resolved-complaints",
      method: "post", // Use POST if required by the backend
      data: {
        "complaint_id": complaintId,
      },
    );

    print("✅ Response status: ${response.statusCode}");
    print("📥 Response data: ${response.data}");

    return response;
  } catch (e) {
    print("❌ Error in getTechnicanHistory: $e");
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


  Future<Response> getAvailableTechnicians() async {
    try {
      final response = await apiClient.request(
        "technicians/except",  
        method: "get",
        data: {
          "exclude_uid": FirebaseAuth.instance.currentUser?.uid,
        }
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

Future<Map<String, dynamic>> getComplaintDetails(String complaintId) async {
  try {
    final response = await apiClient.request(
      "technician/complaint-details",
      method: "get", 
      data: {
        "complaint_id": complaintId,
      },
    );

    return response.data; 
  } catch (e) {
    print("❌ Error in getComplaintDetails: $e");
    rethrow;
  }
}

Future<ComplaintsResponse> getTenantComplaints() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    final response = await apiClient.request(
      "tenant/complaints",
      method: "post",
      data: {"uid": user.uid},
      // options: Options(
      //   validateStatus: (status) => true, // Accept all status codes
      // ),
    );

    debugPrint("API Response: ${response.data}");

    if (response.data == null) {
      throw Exception("Empty response from server");
    }

    return ComplaintsResponse.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    debugPrint("Dio error (${e.response?.statusCode}): ${e.message}");
    if (e.response?.data != null) {
      try {
        // Try to parse error response
        return ComplaintsResponse.fromJson(e.response!.data);
      } catch (_) {
        throw Exception("Failed to parse error response");
      }
    }
    rethrow;
  } catch (e) {
    debugPrint("Unexpected error: $e");
    rethrow;
  }
}
  Future<Response> getComplaints() async {
    try {
      final response = await apiClient.request(
        "tenant/complaints",
        method: "post",
        data: {"uid": FirebaseAuth.instance.currentUser?.uid ?? ''},
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }
  // register complaint

Future<Response> insertComplaint(
    CreateComplaintRequest createComplaintRequest,
    List<File> uploadedImages) async {
  try {
    // Prepare FormData
    final formData = FormData();

    // Add complaint data (from your request model)
    final complaintData = createComplaintRequest.toJson();
    complaintData.forEach((key, value) {
      formData.fields.add(MapEntry(key, value.toString()));
    });

    // Add uploaded images as multipart
    for (var file in uploadedImages) {
      formData.files.add(
        MapEntry(
          "images[]", // Laravel expects images[] for multiple files
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        ),
      );
    }

    // Debug print
    print("=== insertComplaint Form Data ===");
    formData.fields.forEach((f) => print("${f.key}: ${f.value}"));
    print("Images: ${uploadedImages.map((e) => e.path).toList()}");
    print("=======================");

    // Make API call
    final response = await apiClient.request(
      "user/complaintform",
      method: "post",
      data: formData,
      isFormData: true, // Important for multipart upload
    );

    return response;
  } catch (e) {
    print("❌ Error in insertComplaint: $e");
    rethrow;
  }
}

  
Future<Map<String, dynamic>> updateComplaint({
  required String uid,
  required String complaintId,
  required String status,
  required String reply,
  required List<Map<String, dynamic>> payments,
  required List<File> images,
}) async {
  try {
    final formData = FormData.fromMap({
      "uid": uid,
      "complaint_id": complaintId,
      "status": status,
      "reply": reply,
      "payments": payments,
      "images": [
        for (var file in images)
          await MultipartFile.fromFile(file.path, filename: file.path.split('/').last)
      ],
    });

    print("=== FINAL FORM DATA ===");
    print("uid: $uid");
    print("complaint_id: $complaintId");
    print("status: $status");
    print("reply: $reply");
    print("payments: ${jsonEncode(payments)}");
    print("Images: ${images.map((e) => e.path).toList()}");
    print("=======================");

    final response = await apiClient.request(
      "technician/update-complaint-status",
      method: "post",
      data: formData,
      isFormData: true,
    );

    if (response.data is String) {
      throw Exception("Unexpected response: ${response.data}");
    }
    return response.data;
  } catch (e) {
    print("❌ Error in updateComplaint: $e");
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

  Future<Response> getTechnicianDetails(String uid) async {
  try {
    // Using POST (recommended if backend expects uid in body)
    final response = await apiClient.request(
      "technician/details",
      method: "post",
      data: {"uid": uid},
    );

    return response;
  } catch (e) {
    rethrow;
  }
}



Future<Response> updateTechnicianComplaint({
  required String complaintId,
  required String status,
  List<String>? images,
}) async {
  try {
    final response = await apiClient.request(
      "technician/complaints",
      method: "post",
      data: {
        "complaint_id": complaintId,
        "status": status,
        "images": images ?? [],
      },
    );
    return response;
  } catch (e) {
    rethrow;
  }
}
  
  Future<Response> getTechnicianComplaints(String uid) async {
    try {
      final response = await apiClient.request(
        "technician/complaints",
        method: "post",
        data: {"uid": uid},
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

   Future<Response> getSummaryForTechnician(String uid) async {
    try {
      final response = await apiClient.request(
        "Technician/PropertyStats",
        method: "post",
        data: {"technician_id": uid},
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }



  Future<Response> getSummaryForTenant(String user_id) async {
    try {
      final response = await apiClient.request(
        "Tenant/PropertyStats",
        method: "post",
        data: {"user_id": user_id},
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
   Future<Response> getMyProperties([String? uid]) async {
  try {
    // Fetch UID dynamically if not provided
    uid ??= FirebaseAuth.instance.currentUser?.uid ?? '';

    if (uid.isEmpty) {
      throw Exception('User not logged in. UID is empty.');
    }

    final response = await apiClient.request(
      "tenant/properties",
      method: "post",
      data: {
        "uid": uid,  // <-- Dynamic UID
      },
    );

    return response;
  } catch (e) {
    rethrow;
  }
}
}