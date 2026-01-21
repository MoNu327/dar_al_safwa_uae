import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:majan/data/model/ticket_list_response_model.dart';
import 'package:majan/data/model/user_data_submission_model.dart';
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

   Future<Response> getuserlogactivity(String uid, String mode, String modeUpdated) async {
  try {
    final response = await apiClient.request(
      "log-user-activity", 
      method: "post",
      data: {
        "uid": uid,
        "mode": mode,
        "mode_updated": modeUpdated,  // ⚠️ Changed from "modeupdated" to "mode_updated"
      }
    );

    return response;
  } catch (e) {
    rethrow;
  }
}


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

   Future<Response> getFCMtokenforagent(String uid,String fcmToken) async {
    try {
      final response = await apiClient.request(
        "updateAgentFcmToken",
        method: "post",
        data: {
          "uid": uid,
          "fcm_token": fcmToken
        }
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

Future<Response> gettechnicianbyproperty(int propertyid) async {
  try {
    final response = await apiClient.request(
      "technicians/by-property",
      method: "post",
      data: {
        "property_id": propertyid,
      }
    );

    return response;
  } catch (e) {
    rethrow;
  }
}

Future<Response> getcustomerfollowup(String chatId) async {
  try {
    final response = await apiClient.request(
      "chat/details",
      method: "post",
      data: {
        "chat_id": chatId,  // Now correctly passes String chatId
      }
    );

    return response;
  } catch (e) {
    rethrow;
  }
}


Future<Response> submitFollowUp({
  required String customerId,
  required int propertyId,
  required String unitType,
  required String technicianId,
  required int saleStatus,
  required String notes,
}) async {
  try {
    final response = await apiClient.request(
      "customer-followups/add",
      method: "post",
      data: {
        "customer_id": customerId,
        "property_id": propertyId,
        "unit_type": unitType,
        "technician_id": technicianId,
        "sale_status": saleStatus,
        "notes": notes,
      },
    );

    return response;
  } catch (e) {
    rethrow;
  }
}


Future<Response> getFollowupHistory(String uid, String propertyId) async {
  try {
    final response = await apiClient.request(
      "agent/followup-history",
      method: "post",
      data: {
        "customer_id": uid, 
        "property_id": propertyId, // Ensure this is sent as string
      }
    );

    print('Follow-up History Response: ${response.data}');
    return response;
  } catch (e) {
    print('Error in getFollowupHistory: $e');
    print('Request params: customer_id: $uid, property_id: $propertyId');
    rethrow;
  }
}

Future<Response> getTenantDocuments(String uid) async {
  try {
    final response = await apiClient.request(
      "tenant/documents",  
      method: "post",
      data: {'uid': uid},
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


Future<Response> getpaymentsHistory(String uid) async {
  try {
    final response = await apiClient.request(
      "confirmations/latest",
      method: "get",
      queryParameters: {"uid": uid}, // ✅ Use queryParameters instead of data
    );

    return response;
  } catch (e) {
    rethrow;
  }
}


 Future<Response> addComplaintComment(String uid, int complaintId, String comments) async {
  try {
    final response = await apiClient.request(
      "complaint/view-and-comment",  
      method: "post",
      data: {
        'uid': uid,
        'complaint_id': complaintId,
        'comments': comments,
      },
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

Future<Response> getpropertyinteresthistory(String uid) async {
  try {
    final response = await apiClient.request(
      "property-interests/by-uid",
      method: "post",
      data: {
        "uid": uid, 
      }
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No user logged in");
    }

    final response = await apiClient.request(
      "agent-properties",
      method: "post",
      data: {"uid": user.uid}, // dynamically from Firebase
    );

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
      String mobileNumber,
      String agentid) async {
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
          "mobile": mobileNumber,
          "agent_id":agentid,
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

   Future<Response> getPropertyAgreement(String uid,String unit_address_id) async {
  try {
    final response = await apiClient.request(
      "agreements",
      method: "post",
      data: {
        "uid": uid, 
        "unit_address_id": unit_address_id,
      }
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



Future<Response> submitUserDetailsAndDoc(UserDataSubmissionModel userData) async {
  try {
    debugPrint('🚀 API Service: Starting submission');
    
    // Create FormData for multipart upload
    FormData formData = FormData();

    // Add basic required fields
    _addBasicUserFields(formData, userData);

    // Add additional document titles and expiry dates
    _addAdditionalDocumentFields(formData, userData);
    
    // Add additional document files
    await _addAdditionalDocumentFiles(formData, userData.additionalDocuments);

    // Debug: Print all form fields being sent
    _debugPrintFormData(formData);
    
    debugPrint('🚀 Sending request to server...');
    final response = await apiClient.request(
      "storebooking", 
      method: "post",
      data: formData,
      isFormData: true,
    );
    
    debugPrint('✅ API Request successful: ${response.statusCode}');
    debugPrint('📥 Response data: ${response.data}');
    return response;
    
  } catch (e) {
    debugPrint('💥 API Service Error: $e');
    rethrow;
  }
}

// Helper method to add basic user fields

void _addBasicUserFields(FormData formData, UserDataSubmissionModel userData) {
  final basicFields = [
    if (userData.uid.isNotEmpty)
      MapEntry('uid', userData.uid),
    if (userData.firstName.isNotEmpty)
      MapEntry('first_name', userData.firstName),
    if (userData.lastName.isNotEmpty)
      MapEntry('last_name', userData.lastName),
    if (userData.address.isNotEmpty)
      MapEntry('address', userData.address),
    if (userData.email.isNotEmpty)
      MapEntry('email', userData.email),
    if (userData.mobile.isNotEmpty)
      MapEntry('mobile', userData.mobile),
    if (userData.propertyId.isNotEmpty)
      MapEntry('propertyid', userData.propertyId),
    if (userData.unitId.isNotEmpty)
      MapEntry('unitid', userData.unitId),
    MapEntry('citizenship', userData.citizenship ? '1' : '0'),
    // ✅ ADD THIS LINE - Include rentalPref if it's not null and not empty
    if (userData.rentalPref != null && userData.rentalPref!.isNotEmpty)
      MapEntry('rentalpref', userData.rentalPref!),
  ];

  formData.fields.addAll(basicFields);
  debugPrint('📋 Added basic user fields');
  
  // Add debug print to verify rentalPref is included
  if (userData.rentalPref != null && userData.rentalPref!.isNotEmpty) {
    debugPrint('   ✅ Rental Preference: ${userData.rentalPref}');
  } else {
    debugPrint('   ℹ️ No rental preference provided');
  }
}

// Helper method to add additional document fields
void _addAdditionalDocumentFields(FormData formData, UserDataSubmissionModel userData) {
  // Add additional document titles
  if (userData.additionalDocuments.isNotEmpty) {
    debugPrint('📋 Adding ${userData.additionalDocuments.length} additional document titles');
    for (int i = 0; i < userData.additionalDocuments.length; i++) {
      final doc = userData.additionalDocuments[i];
      if (doc.title.isNotEmpty) {
        formData.fields.add(
          MapEntry('additional_document_titles[$i]', doc.title)
        );
        debugPrint('   • Title[$i]: ${doc.title}');
      }
    }
  }

  // Add additional document expiry dates
  if (userData.additionalDocuments.isNotEmpty) {
    debugPrint('📋 Adding ${userData.additionalDocuments.length} additional document expiry dates');
    for (int i = 0; i < userData.additionalDocuments.length; i++) {
      final doc = userData.additionalDocuments[i];
      formData.fields.add(
        MapEntry('additional_document_expiry_dates[$i]', 
            doc.expiryDate.toIso8601String().split('T')[0])
      );
      debugPrint('   • Expiry[$i]: ${doc.expiryDate.toIso8601String().split('T')[0]}');
    }
  }
}

// Helper method to add additional document files
Future<void> _addAdditionalDocumentFiles(
  FormData formData, 
  List<AdditionalDocument> additionalDocuments,
) async {
  if (additionalDocuments.isNotEmpty) {
    debugPrint('📁 Adding ${additionalDocuments.length} additional document files');
    
    for (int i = 0; i < additionalDocuments.length; i++) {
      final doc = additionalDocuments[i];
      
      if (doc.file != null) {
        try {
          if (doc.file is File) {
            // Handle File objects
            File file = doc.file as File;
            if (file.existsSync()) {
              String fileName = file.path.split('/').last;
              
              MultipartFile multipartFile = await MultipartFile.fromFile(
                file.path,
                filename: fileName,
              );
              
              formData.files.add(MapEntry('additional_documents[$i]', multipartFile));
              debugPrint('   📎 Added additional file: $fileName');
            } else {
              debugPrint('   ❌ Additional file not found: ${file.path}');
            }
          } else if (doc.file is String) {
            // Handle file paths as strings
            String filePath = doc.file as String;
            File file = File(filePath);
            
            if (file.existsSync()) {
              String fileName = filePath.split('/').last;
              
              MultipartFile multipartFile = await MultipartFile.fromFile(
                filePath,
                filename: fileName,
              );
              
              formData.files.add(MapEntry('additional_documents[$i]', multipartFile));
              debugPrint('   📎 Added additional file: $fileName');
            } else {
              debugPrint('   ❌ Additional file not found: $filePath');
            }
          } else if (doc.file is Uint8List) {
            // Handle byte arrays
            Uint8List bytes = doc.file as Uint8List;
            String fileName = 'document_${i}_${doc.title.replaceAll(' ', '_')}.pdf';
            
            MultipartFile multipartFile = MultipartFile.fromBytes(
              bytes,
              filename: fileName,
            );
            
            formData.files.add(MapEntry('additional_documents[$i]', multipartFile));
            debugPrint('   📎 Added additional file from bytes: $fileName');
          } else {
            debugPrint('   ⚠️ Unknown file type for document: ${doc.title}');
          }
        } catch (e) {
          debugPrint('   ❌ Error processing file for document ${doc.title}: $e');
        }
      } else {
        debugPrint('   ⚠️ No file provided for document: ${doc.title}');
      }
    }
  }
}

// Helper method to debug form data
void _debugPrintFormData(FormData formData) {
  debugPrint('📦 FormData contents:');
  debugPrint('   Fields:');
  for (var field in formData.fields) {
    debugPrint('     ${field.key}: ${field.value}');
  }
  debugPrint('   Files:');
  for (var file in formData.files) {
    debugPrint('     ${file.key}: ${file.value.filename}');
  }
}

// If you need to determine content type based on file extension
String _getContentType(String fileName) {
  final extension = fileName.split('.').last.toLowerCase();
  switch (extension) {
    case 'pdf':
      return 'application/pdf';
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'gif':
      return 'image/gif';
    case 'doc':
    case 'docx':
      return 'application/msword';
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
      final user = FirebaseAuth.instance.currentUser;
       if (user == null) {
      throw Exception("No user logged in");
       }
      final response = await apiClient.request(
        "chatListByAgent",
        method: "post",
        data: {"uid": user.uid},
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }
   Future<Response>  getMyProperties([String? uid]) async {
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