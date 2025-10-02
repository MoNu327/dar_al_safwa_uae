import 'package:dio/dio.dart';
import 'package:majan/data/model/complaint_details_model.dart';
import 'package:majan/data/repositories/api_services.dart';
import 'package:get/get.dart';

class ComplaintDetailsController extends GetxController {
  final ApiService _apiService = ApiService();

  /// Observables
  var isLoading = false.obs;
  var complaintDetails = Rxn<ComplaintDetailsModel>();
  var errorMessage = ''.obs;

  /// Fetch complaint details by complaint ID
 /// Fetch complaint details by complaint ID
/// Enhanced fetch method with detailed API response logging
Future<void> fetchComplaintDetails(String complaintId) async {
  try {
    isLoading.value = true;
    errorMessage.value = '';

    final response = await _apiService.getFullComplaintDetails(complaintId);
    
    // ============================================
    // COMPREHENSIVE API RESPONSE DEBUG
    // ============================================
    print('\n🔍 ========== API RESPONSE DEBUG ==========');
    print('📡 Status Code: ${response.statusCode}');
    print('📋 Response Type: ${response.data.runtimeType}');
    
    // Print the ENTIRE response data
    print('\n📦 FULL RESPONSE DATA:');
    print(response.data);
    
    // Check if response.data is a Map
    if (response.data is Map<String, dynamic>) {
      final Map<String, dynamic> dataMap = response.data;
      
      print('\n🔑 TOP-LEVEL KEYS:');
      dataMap.keys.forEach((key) {
        print('  - $key: ${dataMap[key]?.runtimeType}');
      });
      
      // Check for 'data' key
      if (dataMap.containsKey('data')) {
        print('\n📊 DATA OBJECT KEYS:');
        final dataObj = dataMap['data'];
        if (dataObj is Map<String, dynamic>) {
          dataObj.keys.forEach((key) {
            print('  - $key: ${dataObj[key]?.runtimeType}');
          });
          
          // Specifically check for images
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
          
          // Check if images are nested inside complaint object
          print('\n🔍 CHECKING COMPLAINT OBJECT FOR IMAGES:');
          if (dataObj.containsKey('complaint')) {
            final complaint = dataObj['complaint'];
            if (complaint is Map<String, dynamic>) {
              print('  Complaint keys: ${complaint.keys.toList()}');
              
              // Look for image-related fields in complaint
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
          
          // Check for alternative image field names
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

    // Parse JSON into model
    complaintDetails.value = ComplaintDetailsModel.fromJson(response.data);

    // Model structure debug
    _debugModelStructure();
    
    // Image categorization debug
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

/// Debug the parsed model structure
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

/// Existing debug image info method (keep as is)
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
    final uploaderType = image.by?['type']?.toString().toLowerCase() ?? 'NO BY FIELD';
    final uploaderName = image.by?['name']?.toString() ?? 'NO NAME';
    
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
  /// Helper to categorize images - returns the PRIMARY category
 String _categorizeImage(String path) {
  final lowerPath = path.toLowerCase();
  
  // Check for technician patterns (add more patterns based on your API)
  if (lowerPath.contains('tech_complaint_images') || 
      lowerPath.contains('technician_images') ||
      lowerPath.contains('technician_reply') ||
      lowerPath.contains('/tech/') ||
      lowerPath.contains('/technician/')) {
    return 'technician';
  }
  
  // Check for admin patterns
  if (lowerPath.contains('admin_complaint_images') || 
      lowerPath.contains('admin_images') ||
      lowerPath.contains('/admin/')) {
    return 'admin';
  }
  
  // Default to tenant
  return 'tenant';
}
  /// Latest payment helper
  Payment? get latestPayment {
    final payments = complaintDetails.value?.data.payments;
    if (payments != null && payments.isNotEmpty) {
      return payments.last;
    }
    return null;
  }

  /// Get amount paid
  String get amountPaid => latestPayment?.amount ?? '0';

  /// Get payment status
  String get paymentStatus => latestPayment?.status ?? '0';

  /// Get payment method
  String get paymentMethod => latestPayment?.method ?? '';

  /// Get ALL images (for debugging)
  List<ComplaintImage> get allImages =>
      complaintDetails.value?.data.images ?? [];

  /// Get tenant images - FIXED: No overlapping conditions
 /// Get tenant images - uses 'by' field instead of path
List<ComplaintImage> get tenantImages {
  final images = complaintDetails.value?.data.images ?? [];
  return images.where((img) {
    final uploaderType = img.by?['type']?.toString().toLowerCase() ?? '';
    return uploaderType == 'user' || uploaderType == 'tenant';
  }).toList();
}

/// Get technician images - uses 'by' field
List<ComplaintImage> get technicianImages {
  final images = complaintDetails.value?.data.images ?? [];
  return images.where((img) {
    final uploaderType = img.by?['type']?.toString().toLowerCase() ?? '';
    return uploaderType == 'technician';
  }).toList();
}

/// Get admin images - uses 'by' field
List<ComplaintImage> get adminImages {
  final images = complaintDetails.value?.data.images ?? [];
  return images.where((img) {
    final uploaderType = img.by?['type']?.toString().toLowerCase() ?? '';
    return uploaderType == 'admin';
  }).toList();
}

  /// Get timeline events
  List<TimelineEvent> get timeline =>
      complaintDetails.value?.data.timeline ?? [];
}