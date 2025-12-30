import 'package:majan/data/model/lease_data_model.dart';
import 'package:majan/data/model/payments_installments_model.dart';
import 'package:majan/presentation/view/dashboard/controller/payments_history_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentDetailsPage extends StatelessWidget {
  final PaymentDetailsController controller = Get.put(PaymentDetailsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Details'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => controller.retryLoadData(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading payment details...'),
              ],
            ),
          );
        }

        if (controller.errorMessage.value.isNotEmpty && controller.leaseData.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Failed to load data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => controller.retryLoadData(),
                  icon: Icon(Icons.refresh),
                  label: Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.leaseData.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No lease data available'),
              ],
            ),
          );
        }

        final leaseData = controller.leaseData.value!;
        
        // Check if there are any installments
        if (!_hasInstallments(leaseData)) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildLeaseSummaryCard(leaseData),
                SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No payment installments found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Get all installments from all payment groups
        final allInstallments = _getAllInstallments(leaseData);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lease Summary Card
              _buildLeaseSummaryCard(leaseData),
              
              // Payment Installments List
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Payment Installments (${allInstallments.length})',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: allInstallments.length,
                itemBuilder: (context, index) {
                  final installment = allInstallments[index];
                  return _buildInstallmentCard(installment);
                },
              ),
            ],
          ),
        );
      }),
    );
  }

  // Helper method to check if there are any installments
  bool _hasInstallments(LeaseDataModel leaseData) {
    if (leaseData.payment_groups == null) return false;
    
    final groups = leaseData.payment_groups!;
    return groups.cash.isNotEmpty || 
           groups.cheque.isNotEmpty || 
           groups.bank.isNotEmpty || 
           groups.other.isNotEmpty;
  }

  // Helper method to get all installments from all payment groups
  List<PaymentInstallmentModel> _getAllInstallments(LeaseDataModel leaseData) {
    if (leaseData.payment_groups == null) return [];
    
    final groups = leaseData.payment_groups!;
    return [
      ...groups.cash,
      ...groups.cheque,
      ...groups.bank,
      ...groups.other,
    ];
  }

  Widget _buildLeaseSummaryCard(LeaseDataModel leaseData) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lease Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildInfoRow('Property', leaseData.property_title ?? 'N/A'),
            _buildInfoRow('Unit', '${leaseData.unit_type_title ?? 'N/A'} - ${leaseData.unit_title ?? 'N/A'}'),
            _buildInfoRow('Rent Amount', 'AED ${leaseData.rent_amount ?? '0'}'),
            if (leaseData.rental_duration != null)
              _buildInfoRow('Duration', '${leaseData.rental_duration} months')
            else
              _buildInfoRow('Duration', _calculateDuration(leaseData.start_date, leaseData.end_date)),
            _buildInfoRow('Start Date', leaseData.start_date ?? 'N/A'),
            _buildInfoRow('End Date', leaseData.end_date ?? 'N/A'),
            _buildInfoRow('Status', (leaseData.confirmation_status ?? 'pending').toUpperCase()),
            if (leaseData.notes != null && leaseData.notes!.isNotEmpty)
              _buildInfoRow('Notes', leaseData.notes!),
          ],
        ),
      ),
    );
  }

  // Helper method to calculate duration
  String _calculateDuration(String? startDate, String? endDate) {
    if (startDate == null || endDate == null) return 'N/A';
    
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final days = end.difference(start).inDays;
      
      if (days < 30) {
        return '$days days';
      } else {
        final months = (days / 30).round();
        return '$months months';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildInstallmentCard(PaymentInstallmentModel installment) {
    final paymentMethod = controller.getPaymentMethodForInstallment(installment);
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Installment #${installment.installment_number ?? 'N/A'}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: controller.getStatusColor(installment.payment_status ?? 'pending').withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                (installment.payment_status ?? 'pending').toUpperCase(),
                style: TextStyle(
                  color: controller.getStatusColor(installment.payment_status ?? 'pending'),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Amount: AED ${installment.amount ?? '0'}'),
            if (installment.upcoming ?? false)
              Chip(
                label: Text('Upcoming', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.blue.shade100,
                labelPadding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Amount', 'AED ${installment.amount ?? '0'}'),
                if (installment.received_amount != null)
                  _buildInfoRow('Received Amount', 'AED ${installment.received_amount}'),
                
                SizedBox(height: 16),
                
                // Payment Method Specific Details
                _buildPaymentMethodDetails(installment, paymentMethod),
                
                if (installment.payment_notes != null && installment.payment_notes!.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Text(
                    'Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(installment.payment_notes!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodDetails(
    PaymentInstallmentModel installment,
    PaymentMethod method,
  ) {
    switch (method) {
      case PaymentMethod.cheque:
        return _buildChequeDetails(installment);
      case PaymentMethod.bank:
        return _buildBankTransferDetails(installment);
      case PaymentMethod.cash:
        return _buildCashDetails(installment);
      case PaymentMethod.other:
        return _buildOtherPaymentDetails(installment);
    }
  }

  Widget _buildChequeDetails(PaymentInstallmentModel installment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Cheque Payment Details', Icons.receipt_long),
        if (installment.cheque_number != null)
          _buildInfoRow('Cheque Number', installment.cheque_number!),
        if (installment.cheque_date != null)
          _buildInfoRow('Cheque Date', installment.cheque_date!),
        if (installment.cheque_bank_name != null)
          _buildInfoRow('Bank Name', installment.cheque_bank_name!),
        if (installment.cheque_image != null)
          _buildImagePreview('Cheque Image', installment.cheque_image!),
      ],
    );
  }

  Widget _buildBankTransferDetails(PaymentInstallmentModel installment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Bank Transfer Details', Icons.account_balance),
        if (installment.transaction_reference != null)
          _buildInfoRow('Transaction Reference', installment.transaction_reference!),
        if (installment.transfer_bank_name != null)
          _buildInfoRow('Bank Name', installment.transfer_bank_name!),
        if (installment.transfer_date != null)
          _buildInfoRow('Transfer Date', installment.transfer_date!),
        if (installment.transfer_proof != null)
          _buildImagePreview('Transfer Proof', installment.transfer_proof!),
      ],
    );
  }

  Widget _buildCashDetails(PaymentInstallmentModel installment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Cash Payment Details', Icons.money),
        if (installment.receipt_number != null)
          _buildInfoRow('Receipt Number', installment.receipt_number!),
        if (installment.cash_payment_date != null)
          _buildInfoRow('Payment Date', installment.cash_payment_date!),
        if (installment.receipt_image != null)
          _buildImagePreview('Receipt Image', installment.receipt_image!),
      ],
    );
  }

  Widget _buildOtherPaymentDetails(PaymentInstallmentModel installment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Other Payment Details', Icons.payment),
        if (installment.payment_description != null)
          _buildInfoRow('Description', installment.payment_description!),
        if (installment.payment_reference != null)
          _buildInfoRow('Reference', installment.payment_reference!),
        if (installment.otherpaymentdate != null)
          _buildInfoRow('Payment Date', installment.otherpaymentdate!),
        if (installment.payment_image != null)
          _buildImagePreview('Payment Proof', installment.payment_image!),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String label, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              // Open full screen image viewer
              Get.dialog(
                Dialog(
                  child: Image.network(imageUrl),
                ),
              );
            },
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Failed to load image'),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}