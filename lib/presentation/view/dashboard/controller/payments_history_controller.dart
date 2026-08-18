import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/data/model/lease_data_model.dart';
import 'package:majan/data/model/lease_response_model.dart';
import 'package:majan/data/model/payments_installments_model.dart';
import 'package:majan/data/repositories/api_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum PaymentMethod { cash, cheque, bank, other }

class PaymentDetailsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  
  var isLoading = false.obs;
  var leaseData = Rxn<LeaseDataModel>(); // Currently selected lease
  var allLeases = RxList<LeaseDataModel>([]); // All user's leases
  var selectedPaymentMethod = PaymentMethod.cash.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadLeaseData();
  }

  /// Shows a snackbar safely. During onInit()/first load the Navigator overlay
  /// may not be mounted yet, so calling Get.snackbar directly throws
  /// "No Overlay widget found". Deferring to after the current frame guarantees
  /// the overlay exists.
  void _showSnack(
    String title,
    String message, {
    SnackPosition position = SnackPosition.BOTTOM,
    Color? background,
    Duration duration = const Duration(seconds: 3),
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.snackbar(
        title,
        message,
        snackPosition: position,
        backgroundColor: (background ?? Colors.black87).withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        duration: duration,
      );
    });
  }

  String? _getUserId() {
    // Try to get from arguments
    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      final uid = Get.arguments['uid'];
      if (uid != null && uid.toString().isNotEmpty) {
        return uid.toString();
      }
    }
    
    // Try to get from parameters (if using named routes)
    final paramUid = Get.parameters['uid'];
    if (paramUid != null && paramUid.isNotEmpty) {
      return paramUid;
    }
    
    // TODO: Get from your auth service as fallback
    // final authService = Get.find<AuthService>();
    // return authService.currentUser?.uid;
    
    return null;
  }

   Future<void> loadLeaseData() async {
  try {
    isLoading.value = true;
    errorMessage.value = '';
    
    final uid = _getUserId();
    
    if (uid == null || uid.isEmpty) {
      errorMessage.value = 'User ID not found. Please log in again.';
      _showSnack(
        'Authentication Error',
        'Unable to retrieve user information',
        background: Colors.red,
      );
      return;
    }
    
    print('📡 Fetching payment history for UID: $uid');
    
    final response = await _apiService.getpaymentsHistory(uid);
    
    // Handle 404 - No data found
    if (response.statusCode == 404) {
      errorMessage.value = 'no_data_404'; // Special flag for 404
      print('📭 404: No lease data found for user');
      return;
    }
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('📦 API Response Data: ${response.data}');
      
      final leaseResponse = LeaseResponseModel.fromJson(response.data);
      
      if (leaseResponse.success && leaseResponse.data.isNotEmpty) {
        allLeases.value = leaseResponse.data;
        leaseData.value = allLeases.first;
        
        print('✅ Loaded ${allLeases.length} lease(s) successfully');

        if (allLeases.length > 1) {
          _showSnack(
            'Properties Loaded',
            'You have ${allLeases.length} properties. Use the selector to switch between them.',
            position: SnackPosition.TOP,
            background: AppColors.secondaryColor,
          );
        }
      } else {
        errorMessage.value = 'no_data_404';
      }
    } else {
      errorMessage.value = 'Failed to load data: ${response.statusMessage}';
      _showSnack('Error', 'Failed to load lease data', background: Colors.red);
    }
  } on TypeError catch (e) {
    errorMessage.value = 'Data parsing error';
    print('❌ Type Error: $e');
    print('❌ Stack trace: ${StackTrace.current}');
    _showSnack(
      'Data Error',
      'Failed to parse server response. Please check the data format.',
      background: Colors.red,
    );
  } catch (e, stackTrace) {
    errorMessage.value = e.toString();
    print('❌ Error: $e');
    print('❌ Stack trace: $stackTrace');
    _showSnack('Error', 'An error occurred: ${e.toString()}',
        background: Colors.red);
  } finally {
    isLoading.value = false;
  }
}
  // NEW: Method to switch between properties
  void selectLeaseById(String leaseId) {
    final selectedLease = allLeases.firstWhereOrNull((lease) => lease.id == leaseId);
    if (selectedLease != null) {
      leaseData.value = selectedLease;
      print('🏠 Switched to property: ${selectedLease.property_title}');

      _showSnack(
        'Property Selected',
        selectedLease.property_title ?? 'Property',
        position: SnackPosition.TOP,
        background: AppColors.onlineGreen,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // NEW: Get property display name
  String getPropertyDisplayName(LeaseDataModel lease) {
    final parts = <String>[];
    
    if (lease.property_title != null && lease.property_title!.isNotEmpty) {
      parts.add(lease.property_title!);
    }
    
    if (lease.unit_title != null && lease.unit_title!.isNotEmpty) {
      parts.add('Unit ${lease.unit_title}');
    }
    
    return parts.isEmpty ? 'Property' : parts.join(' - ');
  }

  void retryLoadData() {
    loadLeaseData();
  }

  void changePaymentMethod(PaymentMethod method) {
    selectedPaymentMethod.value = method;
  }

  PaymentMethod getPaymentMethodForInstallment(PaymentInstallmentModel installment) {
    if (installment.cheque_number != null || 
        installment.cheque_date != null || 
        installment.cheque_bank_name != null) {
      return PaymentMethod.cheque;
    } else if (installment.transaction_reference != null || 
               installment.transfer_bank_name != null || 
               installment.transfer_date != null) {
      return PaymentMethod.bank;
    } else if (installment.receipt_number != null || 
               installment.cash_payment_date != null) {
      return PaymentMethod.cash;
    } else if (installment.payment_description != null || 
               installment.otherpaymentdate != null) {
      return PaymentMethod.other;
    }
    return PaymentMethod.cash;
  }

  bool hasPaymentDetails(PaymentInstallmentModel installment) {
    return installment.cheque_number != null ||
        installment.transaction_reference != null ||
        installment.receipt_number != null ||
        installment.payment_description != null;
  }

  String getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash Payment';
      case PaymentMethod.cheque:
        return 'Cheque Payment';
      case PaymentMethod.bank:
        return 'Bank Transfer';
      case PaymentMethod.other:
        return 'Other Payment';
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Map<String, dynamic> getPaymentSummary() {
    if (leaseData.value == null || leaseData.value!.payment_groups == null) {
      return {
        'total': 0,
        'paid': 0,
        'pending': 0,
        'totalAmount': 0.0,
        'paidAmount': 0.0,
        'remainingAmount': 0.0,
      };
    }
    
    final groups = leaseData.value!.payment_groups!;
    final allInstallments = [
      ...groups.cash,
      ...groups.cheque,
      ...groups.bank,
      ...groups.other,
    ];
    
    if (allInstallments.isEmpty) {
      return {
        'total': 0,
        'paid': 0,
        'pending': 0,
        'totalAmount': 0.0,
        'paidAmount': 0.0,
        'remainingAmount': 0.0,
      };
    }
    
    int totalInstallments = allInstallments.length;
    int paidInstallments = allInstallments.where((i) => 
      (i.payment_status ?? '').toLowerCase() == 'paid'
    ).length;
    int pendingInstallments = allInstallments.where((i) => 
      (i.payment_status ?? '').toLowerCase() == 'pending'
    ).length;
    
    double totalAmount = allInstallments.fold(0.0, (sum, i) {
      return sum + (double.tryParse(i.amount ?? '0') ?? 0.0);
    });
    
    double paidAmount = allInstallments
        .where((i) => (i.payment_status ?? '').toLowerCase() == 'paid')
        .fold(0.0, (sum, i) {
          return sum + (double.tryParse(i.received_amount ?? '0') ?? 0.0);
        });
    
    return {
      'total': totalInstallments,
      'paid': paidInstallments,
      'pending': pendingInstallments,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingAmount': totalAmount - paidAmount,
    };
  }

  List<PaymentInstallmentModel> getUpcomingPayments() {
    if (leaseData.value == null || leaseData.value!.payment_groups == null) {
      return [];
    }
    
    final groups = leaseData.value!.payment_groups!;
    final allInstallments = [
      ...groups.cash,
      ...groups.cheque,
      ...groups.bank,
      ...groups.other,
    ];
    
    return allInstallments
        .where((i) => (i.upcoming ?? false) && (i.payment_status ?? '').toLowerCase() == 'pending')
        .toList();
  }

  List<PaymentInstallmentModel> getOverduePayments() {
    if (leaseData.value == null || leaseData.value!.payment_groups == null) {
      return [];
    }
    
    final groups = leaseData.value!.payment_groups!;
    final allInstallments = [
      ...groups.cash,
      ...groups.cheque,
      ...groups.bank,
      ...groups.other,
    ];
    
    return allInstallments
        .where((i) => !(i.upcoming ?? false) && (i.payment_status ?? '').toLowerCase() == 'pending')
        .toList();
  }
}