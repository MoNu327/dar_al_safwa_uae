import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:majan/data/model/complaint_details_model.dart';
import 'package:majan/data/repositories/api_services.dart';
import 'package:get/get.dart';

class ComplaintDetailsController extends GetxController {
  final ApiService _apiService = ApiService();

  /// Observables
  var isLoading = false.obs;
  var isSubmittingComment = false.obs; // NEW
  var complaintDetails = Rxn<ComplaintDetailsModel>();
  var errorMessage = ''.obs;

  /// Text Controller for comments
  final TextEditingController commentController = TextEditingController(); // NEW

  /// Fetch complaint details by complaint ID
  Future<void> fetchComplaintDetails(String complaintId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _apiService.getFullComplaintDetails(complaintId);
      
      print('\n🔍 ========== API RESPONSE DEBUG ==========');
      print('📡 Status Code: ${response.statusCode}');
      print('📋 Response Type: ${response.data.runtimeType}');
      
      print('\n📦 FULL RESPONSE DATA:');
      print(response.data);
      
      if (response.data is Map<String, dynamic>) {
        final Map<String, dynamic> dataMap = response.data;
        
        print('\n🔑 TOP-LEVEL KEYS:');
        dataMap.keys.forEach((key) {
          print('  - $key: ${dataMap[key]?.runtimeType}');
        });
        
        if (dataMap.containsKey('data')) {
          print('\n📊 DATA OBJECT KEYS:');
          final dataObj = dataMap['data'];
          if (dataObj is Map<String, dynamic>) {
            dataObj.keys.forEach((key) {
              print('  - $key: ${dataObj[key]?.runtimeType}');
            });
            
            print('\n🖼️ IMAGES ANALYSIS:');
            if (dataObj.containsKey('images')) {
              final images = dataObj['images'];
              print('  - images type: ${images.runtimeType}');
              print('  - images value: $images');
              
              if (images is List) {
                print('  - images length: ${images.length}');
                if (images.isNotEmpty) {
                  print('  - First image: ${images.first}');
                }
              } else if (images is Map) {
                print('  - images keys: ${(images as Map).keys.toList()}');
                print('  - images structure: $images');
              }
            } else {
              print('  ⚠️ NO "images" KEY FOUND in data object!');
              print('  Available keys: ${dataObj.keys.toList()}');
            }
            
            print('\n🔍 CHECKING COMPLAINT OBJECT FOR IMAGES:');
            if (dataObj.containsKey('complaint')) {
              final complaint = dataObj['complaint'];
              if (complaint is Map<String, dynamic>) {
                print('  Complaint keys: ${complaint.keys.toList()}');
                
                complaint.keys.where((k) => 
                  k.toLowerCase().contains('image') || 
                  k.toLowerCase().contains('photo') ||
                  k.toLowerCase().contains('media') ||
                  k.toLowerCase().contains('attachment')
                ).forEach((key) {
                  print('  - Found in complaint: $key = ${complaint[key]}');
                });
              }
            }
            
            print('\n🔎 SEARCHING FOR IMAGE-RELATED FIELDS:');
            dataObj.keys.where((k) => 
              k.toLowerCase().contains('image') || 
              k.toLowerCase().contains('photo') ||
              k.toLowerCase().contains('picture')
            ).forEach((key) {
              print('  - Found: $key = ${dataObj[key]}');
            });
          }
        }
      }
      
      print('\n🔍 ========================================\n');

      complaintDetails.value = ComplaintDetailsModel.fromJson(response.data);

      _debugModelStructure();
      _debugImageInfo();

    } catch (e, stackTrace) {
      errorMessage.value = 'Failed to fetch complaint details: $e';
      print('❌ ERROR: $e');
      print('📍 Stack Trace: $stackTrace');
      
      if (e is DioException) {
        print('❌ DIO ERROR Response: ${e.response?.data}');
        print('❌ DIO ERROR Message: ${e.message}');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// NEW: Add comment to complaint
  Future<void> addComment(String complaintId) async {
    if (commentController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a comment',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isSubmittingComment.value = true;

      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        Get.snackbar(
          'Error',
          'User not logged in!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Colors.white,
        );
        return;
      }

      debugPrint('📤 Adding comment to complaint $complaintId');
      debugPrint('User ID: $userId');
      debugPrint('Comment: ${commentController.text.trim()}');

      final response = await _apiService.addComplaintComment(
        userId,
        int.parse(complaintId),
        commentController.text.trim(),
      );

      debugPrint('[addComment] Response: ${response.data}');

      final responseData = response.data is Map ? response.data as Map<String, dynamic> : {};

      if (responseData["success"] == true) {
        Get.snackbar(
          'Success',
          responseData["message"]?["en"] ?? "Comment added successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Clear comment field
        commentController.clear();

        // Refresh complaint details to show new comment
        await fetchComplaintDetails(complaintId);
      } else {
        Get.snackbar(
          'Error',
          responseData["message"]?["en"] ?? "Failed to add comment",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('❌ Error adding comment: $e');
      Get.snackbar(
        'Error',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Colors.white,
      );
    } finally {
      isSubmittingComment.value = false;
    }
  }

  void _debugModelStructure() {
    print('\n🏗️ ========== MODEL STRUCTURE DEBUG ==========');
    
    if (complaintDetails.value == null) {
      print('❌ complaintDetails.value is NULL');
      return;
    }
    
    final model = complaintDetails.value!;
    print('✅ Model parsed successfully');
    print('  - success: ${model.success}');
    print('  - message: ${model.message?.en}');
    
    final data = model.data;
    print('\n📊 ComplaintData:');
    print('  - complaint: ${data.complaint.complaintNumber}');
    print('  - property: ${data.property.title}');
    print('  - payments count: ${data.payments.length}');
    print('  - images count: ${data.images.length}');
    print('  - timeline count: ${data.timeline.length}');
    
    if (data.images.isNotEmpty) {
      print('\n🖼️ Sample Image Data:');
      final firstImage = data.images.first;
      print('  - imagePath: ${firstImage.imagePath}');
      print('  - timestamp: ${firstImage.timestamp}');
    }
    
    print('🏗️ ==========================================\n');
  }

  void _debugImageInfo() {
    final data = complaintDetails.value?.data;
    if (data == null) {
      print('❌ No data found in complaint details');
      return;
    }

    final images = data.images;
    print('\n📸 ========== IMAGE CATEGORIZATION DEBUG ==========');
    print('Total images: ${images.length}');
    
    if (images.isEmpty) {
      print('❌ No images to categorize');
      print('📸 ==================================================\n');
      return;
    }
    
    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      final uploaderType = image.by?.type?.toString().toLowerCase() ?? 'NO BY FIELD';
      final uploaderName = image.by?.name?.toString() ?? 'NO NAME';
      
      print('\nImage #${i + 1}:');
      print('  Path: ${image.imagePath}');
      print('  Uploader Type: $uploaderType');
      print('  Uploader Name: $uploaderName');
      print('  Timestamp: ${image.timestamp}');
      print('  Full "by" object: ${image.by}');
    }
    
    print('\n📊 CATEGORIZED COUNTS:');
    print('  Tenant: ${tenantImages.length}');
    print('  Technician: ${technicianImages.length}');
    print('  Admin: ${adminImages.length}');
    print('📸 ==================================================\n');
  }

  String _categorizeImage(String path) {
    final lowerPath = path.toLowerCase();
    
    if (lowerPath.contains('tech_complaint_images') || 
        lowerPath.contains('technician_images') ||
        lowerPath.contains('technician_reply') ||
        lowerPath.contains('/tech/') ||
        lowerPath.contains('/technician/')) {
      return 'technician';
    }
    
    if (lowerPath.contains('admin_complaint_images') || 
        lowerPath.contains('admin_images') ||
        lowerPath.contains('/admin/')) {
      return 'admin';
    }
    
    return 'tenant';
  }

  Payment? get latestPayment {
    final payments = complaintDetails.value?.data.payments;
    if (payments != null && payments.isNotEmpty) {
      return payments.last;
    }
    return null;
  }

  String get amountPaid => latestPayment?.amount ?? '0';
  String get paymentStatus => latestPayment?.status ?? '0';
  String get paymentMethod => latestPayment?.method ?? '';

  List<ComplaintImage> get allImages =>
      complaintDetails.value?.data.images ?? [];

  List<ComplaintImage> get tenantImages {
    final images = complaintDetails.value?.data.images ?? [];
    return images.where((img) {
      final uploaderType = img.by?.type?.toString().toLowerCase() ?? '';
      return uploaderType == 'user' || uploaderType == 'tenant';
    }).toList();
  }

  List<ComplaintImage> get technicianImages {
    final images = complaintDetails.value?.data.images ?? [];
    return images.where((img) {
      final uploaderType = img.by?.type?.toString().toLowerCase() ?? '';
      return uploaderType == 'technician';
    }).toList();
  }

  List<ComplaintImage> get adminImages {
    final images = complaintDetails.value?.data.images ?? [];
    return images.where((img) {
      final uploaderType = img.by?.type?.toString().toLowerCase() ?? '';
      return uploaderType == 'admin';
    }).toList();
  }

  List<TimelineEvent> get timeline =>
      complaintDetails.value?.data.timeline ?? [];

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }
}