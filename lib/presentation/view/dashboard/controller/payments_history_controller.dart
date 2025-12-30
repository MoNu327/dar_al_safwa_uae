import 'package:majan/data/model/lease_data_model.dart';
import 'package:majan/data/model/lease_response_model.dart';
import 'package:majan/data/model/payments_installments_model.dart';
import 'package:majan/data/repositories/api_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum PaymentMethod { cash, cheque, bank, other }

class PaymentDetailsController extends GetxController {
  // Inject your API service here
  final ApiService _apiService = Get.find<ApiService>();
  
  var isLoading = false.obs;
  var leaseData = Rxn<LeaseDataModel>();
  var selectedPaymentMethod = PaymentMethod.cash.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadLeaseData();
  }

  // ✅ Add this method
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
        Get.snackbar(
          'Authentication Error',
          'Unable to retrieve user information',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }
      
      print('📡 Fetching payment history for UID: $uid');
      
      final response = await _apiService.getpaymentsHistory(uid);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Debug print to see response
        print('📦 API Response Data: ${response.data}');
        
        // Parse the response
        final leaseResponse = LeaseResponseModel.fromJson(response.data);
        
        if (leaseResponse.success && leaseResponse.data.isNotEmpty) {
          leaseData.value = leaseResponse.data.first;
          print('✅ Lease data loaded successfully');
        } else {
          errorMessage.value = 'No lease data found';
          Get.snackbar(
            'Info',
            'No lease data available',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withOpacity(0.8),
            colorText: Colors.white,
          );
        }
      } else {
        errorMessage.value = 'Failed to load data: ${response.statusMessage}';
        Get.snackbar(
          'Error',
          'Failed to load lease data',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } on TypeError catch (e) {
      errorMessage.value = 'Data parsing error';
      print('❌ Type Error: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      Get.snackbar(
        'Data Error',
        'Failed to parse server response. Please check the data format.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e, stackTrace) {
      errorMessage.value = e.toString();
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'An error occurred: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Retry loading data
  void retryLoadData() {
    loadLeaseData();
  }

  void changePaymentMethod(PaymentMethod method) {
    selectedPaymentMethod.value = method;
  }

  // Determine payment method from installment data
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
    return PaymentMethod.cash; // Default
  }

  // Check if installment has payment details
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
  
  // Combine all installments from all payment groups
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