import 'package:majan/data/model/complaint_details_model.dart';
import 'package:majan/data/repositories/api_services.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class ComplaintDetailsController extends GetxController {
  final ApiService _apiService = ApiService();

  /// Observables
  var isLoading = false.obs;
  var complaintDetails = Rxn<ComplaintDetailsModel>();
  var errorMessage = ''.obs;

  /// Fetch complaint details by complaint ID
  Future<void> fetchComplaintDetails(String complaintId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _apiService.getFullComplaintDetails(complaintId);

      // Parse JSON into model
      complaintDetails.value = ComplaintDetailsModel.fromJson(response.data);

      // DEBUG: Print image information
      _debugImageInfo();

    } catch (e) {
      errorMessage.value = 'Failed to fetch complaint details: $e';
      print('❌ ERROR: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Debug image information
  void _debugImageInfo() {
    final images = complaintDetails.value?.data.images ?? [];
    print('=== IMAGE DEBUG INFO ===');
    print('Total images in response: ${images.length}');
    
    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      final path = image.imagePath.toLowerCase();
      print('Image $i:');
      print('  - Path: ${image.imagePath}');
      print('  - Timestamp: ${image.timestamp}');
      print('  - Categorized as: ${_categorizeImage(path)}');
    }
    
    print('Tenant images count: ${tenantImages.length}');
    print('Technician images count: ${technicianImages.length}');
    print('Admin images count: ${adminImages.length}');
    print('=== END IMAGE DEBUG ===');
  }

  /// Helper to categorize images - returns the PRIMARY category
  String _categorizeImage(String path) {
    // Check in priority order - most specific first
    if (path.contains('tech_complaint_images') || 
        path.contains('technician_images') ||
        path.contains('/tech/')) {
      return 'technician';
    }
    if (path.contains('admin_complaint_images') || 
        path.contains('admin_images') ||
        path.contains('/admin/')) {
      return 'admin';
    }
    if (path.contains('tenant_complaint_images') || 
        path.contains('user_complaint_images') ||
        path.contains('/tenant/') ||
        path.contains('/user/')) {
      return 'tenant';
    }
    // Default to tenant if no clear indicator
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
  List<ComplaintImage> get tenantImages {
    final images = complaintDetails.value?.data.images ?? [];
    return images.where((img) {
      final path = img.imagePath.toLowerCase();
      return _categorizeImage(path) == 'tenant';
    }).toList();
  }

  /// Get technician images - FIXED: No overlapping conditions
  List<ComplaintImage> get technicianImages {
    final images = complaintDetails.value?.data.images ?? [];
    return images.where((img) {
      final path = img.imagePath.toLowerCase();
      return _categorizeImage(path) == 'technician';
    }).toList();
  }

  /// Get admin images - FIXED: No overlapping conditions
  List<ComplaintImage> get adminImages {
    final images = complaintDetails.value?.data.images ?? [];
    return images.where((img) {
      final path = img.imagePath.toLowerCase();
      return _categorizeImage(path) == 'admin';
    }).toList();
  }

  /// Get timeline events
  List<TimelineEvent> get timeline =>
      complaintDetails.value?.data.timeline ?? [];
}