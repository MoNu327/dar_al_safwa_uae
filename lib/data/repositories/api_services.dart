import 'dart:convert';
import 'dart:io';

import 'package:dar_al_safwa/data/model/ticket_list_response_model.dart';
import 'package:dar_al_safwa/data/model/user_data_submission_model.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
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



Future<Response> submitUserDetailsAndDoc(UserDataSubmissionModel userDataSubmission) async {
  try {
    debugPrint('🚀 API Service: Starting submission for ${userDataSubmission.isNative ? "Native" : "Foreign"} citizen');
    
    // Create FormData for multipart upload
    FormData formData = FormData();
    
    // Add basic required fields for all users
    formData.fields.addAll([
      MapEntry('uid', userDataSubmission.uid),
      MapEntry('first_name', userDataSubmission.firstName),
      MapEntry('last_name', userDataSubmission.lastName),
      MapEntry('propertyid', userDataSubmission.propertyId.toString()),
      MapEntry('unitid', userDataSubmission.unitId.toString()),
      MapEntry('address', userDataSubmission.address),
      MapEntry('citizenship', userDataSubmission.citizenship.toString()),
      MapEntry('email', userDataSubmission.email),
      MapEntry('mobile', userDataSubmission.mobile),
      MapEntry('property_type', userDataSubmission.propertyType ?? 'residential'),
    ]);

    // Add citizenship-specific fields
    if (userDataSubmission.isNative) {
      // Native citizen fields
      debugPrint('📋 Adding Native citizen fields');
      if (userDataSubmission.civilId != null && userDataSubmission.civilId!.isNotEmpty) {
        formData.fields.add(MapEntry('civil_id', userDataSubmission.civilId!));
      }
      if (userDataSubmission.civilIdExpiry != null && userDataSubmission.civilIdExpiry!.isNotEmpty) {
        formData.fields.add(MapEntry('civil_id_expiry', userDataSubmission.civilIdExpiry!));
      }
    } else {
      // Foreign citizen fields - THIS WAS MISSING!
      debugPrint('🛂 Adding Foreign citizen fields');
      
      if (userDataSubmission.passportNo != null && userDataSubmission.passportNo!.isNotEmpty) {
        formData.fields.add(MapEntry('passport_no', userDataSubmission.passportNo!));
        debugPrint('   ✅ Added passport_no: ${userDataSubmission.passportNo}');
      }
      
      if (userDataSubmission.visaNo != null && userDataSubmission.visaNo!.isNotEmpty) {
        formData.fields.add(MapEntry('visa_no', userDataSubmission.visaNo!));
        debugPrint('   ✅ Added visa_no: ${userDataSubmission.visaNo}');
      }
      
      if (userDataSubmission.visaExpiryDate != null && userDataSubmission.visaExpiryDate!.isNotEmpty) {
        formData.fields.add(MapEntry('visa_expiry_date', userDataSubmission.visaExpiryDate!));
        debugPrint('   ✅ Added visa_expiry_date: ${userDataSubmission.visaExpiryDate}');
      }
      
      if (userDataSubmission.expatCivilId != null && userDataSubmission.expatCivilId!.isNotEmpty) {
        formData.fields.add(MapEntry('expat_civil_id', userDataSubmission.expatCivilId!));
        debugPrint('   ✅ Added expat_civil_id: ${userDataSubmission.expatCivilId}');
      }
      
      if (userDataSubmission.expatCivilIdExpiry != null && userDataSubmission.expatCivilIdExpiry!.isNotEmpty) {
        formData.fields.add(MapEntry('expat_civil_id_expiry', userDataSubmission.expatCivilIdExpiry!));
        debugPrint('   ✅ Added expat_civil_id_expiry: ${userDataSubmission.expatCivilIdExpiry}');
      }
    }

    // Add commercial property fields if applicable
    if (userDataSubmission.propertyType == 'commercial') {
      debugPrint('🏢 Adding Commercial property fields');
      
      if (userDataSubmission.crNumber != null && userDataSubmission.crNumber!.isNotEmpty) {
        formData.fields.add(MapEntry('cr_number', userDataSubmission.crNumber!));
      }
      if (userDataSubmission.crExpiryDate != null && userDataSubmission.crExpiryDate!.isNotEmpty) {
        formData.fields.add(MapEntry('cr_expiry_date', userDataSubmission.crExpiryDate!));
      }
      if (userDataSubmission.municipalityLicenseNumber != null && userDataSubmission.municipalityLicenseNumber!.isNotEmpty) {
        formData.fields.add(MapEntry('municipality_license_number', userDataSubmission.municipalityLicenseNumber!));
      }
      if (userDataSubmission.municipalityLicenseDate != null && userDataSubmission.municipalityLicenseDate!.isNotEmpty) {
        formData.fields.add(MapEntry('municipality_license_date', userDataSubmission.municipalityLicenseDate!));
      }
      if (userDataSubmission.companyAddress != null && userDataSubmission.companyAddress!.isNotEmpty) {
        formData.fields.add(MapEntry('company_address', userDataSubmission.companyAddress!));
      }
      if (userDataSubmission.poBox != null && userDataSubmission.poBox!.isNotEmpty) {
        formData.fields.add(MapEntry('po_box', userDataSubmission.poBox!));
      }
    }
    
    // Add document types
    if (userDataSubmission.requiredDocumentTypes.isNotEmpty) {
      debugPrint('📋 Adding ${userDataSubmission.requiredDocumentTypes.length} document types');
      for (int i = 0; i < userDataSubmission.requiredDocumentTypes.length; i++) {
        formData.fields.add(
          MapEntry('required_document_types[$i]', userDataSubmission.requiredDocumentTypes[i])
        );
        debugPrint('   • ${userDataSubmission.requiredDocumentTypes[i]}');
      }
    }

    // Add additional document titles if any
    if (userDataSubmission.additionalDocumentTitles != null && userDataSubmission.additionalDocumentTitles!.isNotEmpty) {
      debugPrint('📋 Adding ${userDataSubmission.additionalDocumentTitles!.length} additional document titles');
      for (int i = 0; i < userDataSubmission.additionalDocumentTitles!.length; i++) {
        formData.fields.add(
          MapEntry('additional_document_titles[$i]', userDataSubmission.additionalDocumentTitles![i])
        );
      }
    }
    
    // Add required document files
    if (userDataSubmission.requiredDocuments != null && userDataSubmission.requiredDocuments!.isNotEmpty) {
      debugPrint('📁 Adding ${userDataSubmission.requiredDocuments!.length} required document files');
      
      for (int i = 0; i < userDataSubmission.requiredDocuments!.length; i++) {
        String filePath = userDataSubmission.requiredDocuments![i];
        File file = File(filePath);
        
        if (file.existsSync()) {
          String fileName = filePath.split('/').last;
          
          MultipartFile multipartFile = await MultipartFile.fromFile(
            filePath,
            filename: fileName,
            contentType: DioMediaType.parse(_getContentType(fileName)),
          );
          
          formData.files.add(MapEntry('required_documents[$i]', multipartFile));
          debugPrint('   📎 Added file: $fileName');
        } else {
          debugPrint('   ❌ File not found: $filePath');
          throw Exception('File not found: $filePath');
        }
      }
    }

    // Add additional document files
    if (userDataSubmission.additionalDocuments != null && userDataSubmission.additionalDocuments!.isNotEmpty) {
      debugPrint('📁 Adding ${userDataSubmission.additionalDocuments!.length} additional document files');
      
      for (int i = 0; i < userDataSubmission.additionalDocuments!.length; i++) {
        String filePath = userDataSubmission.additionalDocuments![i];
        File file = File(filePath);
        
        if (file.existsSync()) {
          String fileName = filePath.split('/').last;
          
          MultipartFile multipartFile = await MultipartFile.fromFile(
            filePath,
            filename: fileName,
            contentType: DioMediaType.parse(_getContentType(fileName)),
          );
          
          formData.files.add(MapEntry('additional_documents[$i]', multipartFile));
          debugPrint('   📎 Added additional file: $fileName');
        } else {
          debugPrint('   ❌ Additional file not found: $filePath');
          throw Exception('Additional file not found: $filePath');
        }
      }
    }

    // Debug: Print all form fields being sent
    debugPrint('📤 FORM DATA FIELDS BEING SENT:');
    for (var field in formData.fields) {
      // Don't log sensitive data in production
      if (field.key.contains('email') || field.key.contains('mobile')) {
        debugPrint('   ${field.key}: ***masked***');
      } else {
        debugPrint('   ${field.key}: ${field.value}');
      }
    }
    
    debugPrint('📤 FORM DATA FILES BEING SENT:');
    for (var file in formData.files) {
      debugPrint('   ${file.key}: ${file.value.filename}');
    }
    
    debugPrint('🚀 Sending request to server...');
    final response = await apiClient.request(
      "storebooking", 
      method: "post",
      data: formData,
      isFormData: true, // Important for multipart uploads
    );
    
    debugPrint('✅ API Request successful: ${response.statusCode}');
    return response;
  } catch (e) {
    debugPrint('💥 API Service Error: $e');
    rethrow;
  }
}

String _getContentType(String fileName) {
  String extension = fileName.toLowerCase().split('.').last;
  switch (extension) {
    case 'pdf':
      return 'application/pdf';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    default:
      return 'application/octet-stream';
  }
}
    Future<Response> getCommercialPropertyStatus(
      int unitId
      ) async {
    try {
      final response = await apiClient.request(
        "check-commercial-property",
        method: "post",
        data:{
          "unitid": unitId
        }
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