import 'package:majan/core/theme/app_colors.dart';
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
    backgroundColor: AppColors.whiteLight,
    appBar: AppBar(
      title: Text('Payment Tracking', style: TextStyle(color: AppColors.black)),
      elevation: 0,
      backgroundColor: AppColors.primaryColor,
      iconTheme: IconThemeData(color: AppColors.black),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: AppColors.black),
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
              CircularProgressIndicator(color: AppColors.primaryColor),
              SizedBox(height: 16),
              Text('Loading payment details...', style: TextStyle(color: AppColors.black600)),
            ],
          ),
        );
      }

      // Beautiful 404 Empty State
      if (controller.errorMessage.value == 'no_data_404') {
        return _buildBeautiful404EmptyState(context);
      }

      // Other error states
      if (controller.errorMessage.value.isNotEmpty && controller.leaseData.value == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              SizedBox(height: 16),
              Text(
                'Failed to load data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => controller.retryLoadData(),
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
        );
      }

      if (controller.leaseData.value == null) {
        return _buildBeautiful404EmptyState(context);
      }

      final leaseData = controller.leaseData.value!;
      if (!_hasInstallments(leaseData)) {
        return SingleChildScrollView(
          child: Column(
            children: [
              // Property selector for multiple properties
              _buildPropertySelector(),
              _buildPaymentOverviewCard(leaseData, []),
              _buildLeaseSummaryCard(leaseData),
              SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.payment_outlined, size: 64, color: AppColors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No payment installments found',
                      style: TextStyle(fontSize: 16, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      final allInstallments = _getAllInstallments(leaseData);

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property selector for multiple properties
            _buildPropertySelector(),
            _buildPaymentOverviewCard(leaseData, allInstallments),
            _buildLeaseSummaryCard(leaseData),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.timeline, color: AppColors.secondaryColor, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Payment Timeline',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
            _buildPaymentTimeline(allInstallments),
            SizedBox(height: 24),
          ],
        ),
      );
    }),
  );
}

Widget _buildBeautiful404EmptyState(BuildContext context) {
  return Container(
    width: double.infinity,
    height: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryColor.withOpacity(0.1),
          AppColors.whiteLight,
        ],
      ),
    ),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated illustration container
            Container(
              padding: EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.home_work_outlined,
                size: 100,
                color: AppColors.primaryColor.withOpacity(0.7),
              ),
            ),
            
            SizedBox(height: 40),
            
            // Title
            Text(
              'No Properties Found',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 16),
            
            // Subtitle
            Text(
              'You don\'t have any rental properties or lease agreements yet.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.black600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 40),
            
            // Refresh button
            // ElevatedButton.icon(
            //   onPressed: () => controller.retryLoadData(),
            //   icon: Icon(Icons.refresh, size: 20),
            //   label: Text('Refresh'),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: AppColors.primaryColor,
            //     foregroundColor: AppColors.black,
            //     padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(12),
            //     ),
            //     elevation: 2,
            //   ),
            // ),
          ],
        ),
      ),
    ),
  );
}
// Property Selector Widget
Widget _buildPropertySelector() {
  return Obx(() {
    // If controller has allLeases list
    final allLeases = controller.allLeases; // Assume this exists in controller
    
    // If user has only one property, don't show selector
    if (allLeases.length <= 1) {
      return SizedBox.shrink();
    }
    
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.apartment, color: AppColors.secondaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Select Property',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${allLeases.length} Properties',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: controller.leaseData.value?.id,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.lightGrey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.lightGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: AppColors.whiteLight,
            ),
            icon: Icon(Icons.keyboard_arrow_down, color: AppColors.secondaryColor),
            items: allLeases.map((lease) {
              return DropdownMenuItem<String>(
                value: lease.id,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lease.property_title ?? 'Unknown Property',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lease.unit_title != null)
                      Text(
                        'Unit: ${lease.unit_title}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.black600,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newLeaseId) {
              if (newLeaseId != null) {
                controller.selectLeaseById(newLeaseId);
              }
            },
          ),
        ],
      ),
    );
  });
}



Widget _buildPaymentOverviewCard(LeaseDataModel leaseData, List<PaymentInstallmentModel> installments) {
  final totalAmount = double.tryParse(leaseData.rent_amount ?? '0') ?? 0;
  
  // Fixed: Trim and lowercase for better matching
  final paidInstallments = installments.where((i) {
    final status = (i.payment_status ?? '').trim().toLowerCase();
    return status == 'paid';
  }).length;
  
  final totalInstallments = installments.length;
  
  // Fixed: Better amount parsing with trim
  final paidAmount = installments
      .where((i) {
        final status = (i.payment_status ?? '').trim().toLowerCase();
        return status == 'paid';
      })
      .fold(0.0, (sum, i) {
        final amount = double.tryParse((i.amount ?? '0').trim()) ?? 0;
        return sum + amount;
      });
  
  final pendingAmount = totalAmount - paidAmount;
  
  // Get upcoming payments with days
  final upcomingPaymentsWithDays = installments.where((i) {
    final status = (i.payment_status ?? '').trim().toLowerCase();
    if (status == 'paid') return false;
    final daysUntil = _getDaysUntilPayment(i);
    return daysUntil >= 0; // Not overdue
  }).toList();
  
  // Sort by days
  upcomingPaymentsWithDays.sort((a, b) {
    final aDays = _getDaysUntilPayment(a);
    final bDays = _getDaysUntilPayment(b);
    return aDays.compareTo(bDays);
  });
  
  // Get the next 1 upcoming payments
  final nextUpcoming = upcomingPaymentsWithDays.take(1).toList();
  
  final overduePayments = _getOverduePayments(installments);
  final overdueAmount = overduePayments.fold(0.0, (sum, i) => sum + (double.tryParse(i.amount ?? '0') ?? 0));
  
  // Calculate progress percentage
  final progressPercentage = totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0.0;
  
  return Container(
    margin: EdgeInsets.all(16),
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.primaryColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: AppColors.primaryColor.withOpacity(0.3),
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Overview',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$paidInstallments/$totalInstallments Paid',
                style: TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        
        // Upcoming Payments Section - WITH DATES ADDED
        if (nextUpcoming.isNotEmpty) ...[
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.black.withOpacity(0.1), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, color: AppColors.black, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Upcoming Payments',
                      style: TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                ...nextUpcoming.map((installment) {
                  final daysUntil = _getDaysUntilPayment(installment);
                  final amount = installment.amount ?? '0';
                  final installmentNum = installment.installment_number ?? 'N/A';
                  
                  // Get payment date
                  final paymentMethod = controller.getPaymentMethodForInstallment(installment);
                  final paymentDate = _getDisplayPaymentDate(installment, paymentMethod);
                  final formattedDate = paymentDate != null ? _formatPaymentDate(paymentDate) : null;
                  
                  String daysText;
                  Color daysColor;
                  IconData daysIcon;
                  
                  if (daysUntil == 0) {
                    daysText = 'Due Today';
                    daysColor = AppColors.warning;
                    daysIcon = Icons.warning_amber_rounded;
                  } else if (daysUntil == 1) {
                    daysText = 'Due Tomorrow';
                    daysColor = AppColors.warning.withOpacity(0.8);
                    daysIcon = Icons.access_time;
                  } else if (daysUntil <= 2) {
                    daysText = 'Due in $daysUntil days';
                    daysColor = AppColors.warning.withOpacity(0.7);
                    daysIcon = Icons.access_time;
                  } else if (daysUntil <= 7) {
                    daysText = 'Due in $daysUntil days';
                    daysColor = AppColors.blueColor;
                    daysIcon = Icons.schedule;
                  } else {
                    daysText = 'Due in $daysUntil days';
                    daysColor = AppColors.black600;
                    daysIcon = Icons.schedule;
                  }
                  
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: daysUntil <= 2 
                            ? AppColors.warning.withOpacity(0.5)
                            : AppColors.black.withOpacity(0.1),
                        width: daysUntil <= 2 ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: daysColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(daysIcon, color: daysColor, size: 16),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Installment #$installmentNum',
                                style: TextStyle(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    daysText,
                                    style: TextStyle(
                                      color: daysColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    ' • AED $amount',
                                    style: TextStyle(
                                      color: AppColors.black600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              // PAYMENT DATE ADDED HERE
                              if (formattedDate != null) ...[
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, 
                                         size: 11, 
                                         color: AppColors.black600),
                                    SizedBox(width: 4),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        color: AppColors.black600,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
        
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Rent',
                'AED ${totalAmount.toStringAsFixed(0)}',
                Icons.account_balance_wallet,
                AppColors.black,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Paid',
                'AED ${paidAmount.toStringAsFixed(0)}',
                Icons.check_circle,
                AppColors.onlineGreen,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pending',
                'AED ${pendingAmount.toStringAsFixed(0)}',
                Icons.pending,
                AppColors.warning,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Progress',
                '${progressPercentage.toStringAsFixed(0)}%',
                Icons.trending_up,
                AppColors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: totalAmount > 0 ? paidAmount / totalAmount : 0,
            backgroundColor: AppColors.black.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.onlineGreen),
            minHeight: 8,
          ),
        ),
        
        // Overdue Payments Alert
        if (overduePayments.isNotEmpty) ...[
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.redColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.redColor.withOpacity(0.5), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.redColor, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overdue Payments!',
                        style: TextStyle(
                          color: AppColors.redColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${overduePayments.length} payment(s) overdue - AED ${overdueAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.black800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}


Widget _buildStatCard(String label, String value, IconData icon, Color iconColor) {
  return Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.white.withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.black600,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: AppColors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildLeaseSummaryCard(LeaseDataModel leaseData) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(Icons.home_work, color: AppColors.secondaryColor),
        title: Text(
          'Lease Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.black),
        ),
        subtitle: Text(leaseData.property_title ?? 'N/A', style: TextStyle(color: AppColors.black600)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInfoRow('Unit', '${leaseData.unit_type_title ?? 'N/A'} - ${leaseData.unit_title ?? 'N/A'}'),
                if (leaseData.rental_duration != null || _calculateDuration(leaseData.start_date, leaseData.end_date) != 'N/A')
                  _buildInfoRow('Duration', leaseData.rental_duration != null 
                      ? '${leaseData.rental_duration} months'
                      : _calculateDuration(leaseData.start_date, leaseData.end_date)),
                _buildInfoRow('Start Date', leaseData.start_date ?? 'N/A'),
                _buildInfoRow('End Date', leaseData.end_date ?? 'N/A'),
                _buildInfoRow('Status', (leaseData.confirmation_status ?? 'pending').toUpperCase()),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Add this method to show urgent payment alert
void _showUrgentPaymentAlert(BuildContext context, List<PaymentInstallmentModel> installments) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final urgentPayments = installments.where((i) {
      final status = i.payment_status?.toLowerCase() ?? 'pending';
      if (status == 'paid') return false;
      
      final daysUntil = _getDaysUntilPayment(i);
      return daysUntil <= 2; // Overdue or within 2 days
    }).toList();
    
    if (urgentPayments.isEmpty) return;
    
    final overdue = urgentPayments.where((i) => _getDaysUntilPayment(i) < 0).length;
    final dueToday = urgentPayments.where((i) => _getDaysUntilPayment(i) == 0).length;
    final dueSoon = urgentPayments.where((i) {
      final days = _getDaysUntilPayment(i);
      return days > 0 && days <= 2;
    }).length;
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: overdue > 0 
                  ? [AppColors.redColor.withOpacity(0.1), AppColors.warning.withOpacity(0.05)]
                  : [AppColors.warning.withOpacity(0.1), AppColors.blueColor.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                overdue > 0 ? Icons.error_outline : Icons.warning_amber_rounded,
                color: overdue > 0 ? AppColors.redColor : AppColors.warning,
                size: 56,
              ),
              SizedBox(height: 16),
              Text(
                overdue > 0 ? 'Payment Alert!' : 'Upcoming Payments',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              SizedBox(height: 12),
              if (overdue > 0)
                _buildAlertRow(
                  Icons.error,
                  '$overdue payment${overdue > 1 ? 's' : ''} overdue',
                  AppColors.redColor,
                ),
              if (dueToday > 0)
                _buildAlertRow(
                  Icons.today,
                  '$dueToday payment${dueToday > 1 ? 's' : ''} due today',
                  AppColors.warning,
                ),
              if (dueSoon > 0)
                _buildAlertRow(
                  Icons.schedule,
                  '$dueSoon payment${dueSoon > 1 ? 's' : ''} due within 2 days',
                  AppColors.blueColor,
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: overdue > 0 ? AppColors.redColor : AppColors.warning,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'View Payments',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  });
}

Widget _buildAlertRow(IconData icon, String text, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ),
      ],
    ),
  );
}

// Add this method to sort installments by priority
List<PaymentInstallmentModel> _sortInstallmentsByPriority(List<PaymentInstallmentModel> installments) {
  final now = DateTime.now();
  
  return installments..sort((a, b) {
    final aStatus = a.payment_status?.toLowerCase() ?? 'pending';
    final bStatus = b.payment_status?.toLowerCase() ?? 'pending';
    
    // Paid items go to the end
    if (aStatus == 'paid' && bStatus != 'paid') return 1;
    if (bStatus == 'paid' && aStatus != 'paid') return -1;
    
    // Get dates for comparison
    final aDate = _getPaymentDate(a);
    final bDate = _getPaymentDate(b);
    
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    
    // Overdue payments first
    final aOverdue = aDate.isBefore(now) && aStatus != 'paid';
    final bOverdue = bDate.isBefore(now) && bStatus != 'paid';
    
    if (aOverdue && !bOverdue) return -1;
    if (bOverdue && !aOverdue) return 1;
    
    // Then sort by date
    return aDate.compareTo(bDate);
  });
}

// Helper to get payment date
DateTime? _getPaymentDate(PaymentInstallmentModel installment) {
  String? dateStr = installment.expected_date ?? 
                    installment.cheque_date ?? 
                    installment.transfer_date ?? 
                    installment.cash_payment_date ?? 
                    installment.otherpaymentdate;
  
  if (dateStr == null) return null;
  
  try {
    return DateTime.parse(dateStr);
  } catch (e) {
    return null;
  }
}

// Helper to calculate days difference
int _getDaysUntilPayment(PaymentInstallmentModel installment) {
  final paymentDate = _getPaymentDate(installment);
  if (paymentDate == null) return 0;
  
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final payment = DateTime(paymentDate.year, paymentDate.month, paymentDate.day);
  
  return payment.difference(today).inDays;
}

// Update _buildPaymentTimeline to use sorted list
Widget _buildPaymentTimeline(List<PaymentInstallmentModel> installments) {
  final sortedInstallments = _sortInstallmentsByPriority(installments);
  
  return ListView.builder(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    padding: EdgeInsets.symmetric(horizontal: 16),
    itemCount: sortedInstallments.length,
    itemBuilder: (context, index) {
      final installment = sortedInstallments[index];
      final isLast = index == sortedInstallments.length - 1;
      return _buildTimelineItem(installment, isLast);
    },
  );
}
// Enhanced timeline item with payment date added
Widget _buildTimelineItem(PaymentInstallmentModel installment, bool isLast) {
  final paymentMethod = controller.getPaymentMethodForInstallment(installment);
  final status = installment.payment_status?.toLowerCase() ?? 'pending';
  final isPaid = status == 'paid';
  final isUpcoming = installment.upcoming ?? false;
  final daysUntil = _getDaysUntilPayment(installment);
  final isOverdue = daysUntil < 0 && !isPaid;
  final isUrgent = daysUntil >= 0 && daysUntil <= 2 && !isPaid;
  
  Color statusColor = controller.getStatusColor(status);
  if (isOverdue) statusColor = AppColors.redColor;
  if (isUrgent) statusColor = AppColors.warning;
  
  IconData statusIcon = isPaid ? Icons.check_circle : 
                        isOverdue ? Icons.error : 
                        isUrgent ? Icons.warning_amber_rounded :
                        isUpcoming ? Icons.schedule : Icons.pending;
  
  // More subtle colors
  Color circleBackground = isPaid ? AppColors.onlineGreen.withOpacity(0.15) : 
                           isOverdue ? AppColors.redColor.withOpacity(0.15) :
                           isUrgent ? AppColors.warning.withOpacity(0.15) :
                           AppColors.grey.withOpacity(0.1);

  // Build urgency message
  String? urgencyMessage;
  Color? urgencyColor;
  IconData? urgencyIcon;
  
  if (isOverdue) {
    urgencyMessage = 'Overdue by ${daysUntil.abs()} ${daysUntil.abs() == 1 ? 'day' : 'days'}';
    urgencyColor = AppColors.redColor;
    urgencyIcon = Icons.error_outline;
  } else if (isUrgent) {
    urgencyMessage = daysUntil == 0 
        ? 'Due today' 
        : 'Due in $daysUntil ${daysUntil == 1 ? 'day' : 'days'}';
    urgencyColor = AppColors.warning;
    urgencyIcon = Icons.access_time;
  } else if (isUpcoming && daysUntil > 2) {
    urgencyMessage = 'Upcoming in $daysUntil days';
    urgencyColor = AppColors.blueColor;
    urgencyIcon = Icons.schedule;
  }

  // Get payment date based on payment method
  String? paymentDate = _getDisplayPaymentDate(installment, paymentMethod);

  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator column
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: circleBackground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: statusColor,
                  width: 2,
                ),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 18,
              ),
            ),
            if (!isLast)
              Expanded(
                child: Container(
                  width: 2,
                  color: AppColors.lightGrey.withOpacity(0.5),
                  margin: EdgeInsets.symmetric(vertical: 4),
                ),
              ),
          ],
        ),
        SizedBox(width: 12),
        
        // Content card
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 1,
              color: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AppColors.lightGrey,
                  width: 1,
                ),
              ),
              child: ExpansionTile(
                tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                childrenPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Installment #${installment.installment_number ?? 'N/A'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Amount
                      Row(
                        children: [
                          Icon(Icons.payments, size: 14, color: AppColors.black600),
                          SizedBox(width: 6),
                          Text(
                            'AED ${installment.amount ?? '0'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                      
                      // Payment Date - NEW ADDITION
                      if (paymentDate != null) ...[
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 13, color: AppColors.black600),
                            SizedBox(width: 6),
                            Text(
                              _formatPaymentDate(paymentDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.black600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      // Urgency message - subtle inline version
                      if (urgencyMessage != null) ...[
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(urgencyIcon, size: 13, color: urgencyColor),
                            SizedBox(width: 6),
                            Text(
                              urgencyMessage,
                              style: TextStyle(
                                fontSize: 12,
                                color: urgencyColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      // Payment method
                      SizedBox(height: 6),
                      _buildMethodChip(paymentMethod),
                    ],
                  ),
                ),
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.grey.withOpacity(0.03),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (installment.received_amount != null) ...[
                          _buildDetailRow(
                            Icons.account_balance_wallet,
                            'Received Amount',
                            'AED ${installment.received_amount}',
                          ),
                          SizedBox(height: 12),
                        ],
                        
                        _buildPaymentMethodDetails(installment, paymentMethod),
                        
                        if (installment.payment_notes != null && 
                            installment.payment_notes!.isNotEmpty) ...[
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.blueColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.blueColor.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.note, size: 16, color: AppColors.blueColor),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Notes',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: AppColors.blueColor,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        installment.payment_notes!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.black800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// Helper method to get the display payment date based on payment method
String? _getDisplayPaymentDate(PaymentInstallmentModel installment, PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cash:
      return installment.cash_payment_date;
    case PaymentMethod.cheque:
      return installment.cheque_date;
    case PaymentMethod.bank:
      return installment.transfer_date;
    case PaymentMethod.other:
      return installment.otherpaymentdate;
  }
}

// Helper method to format the payment date
String _formatPaymentDate(String date) {
  try {
    final parsedDate = DateTime.parse(date);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final dateOnly = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else {
      // Format as "31 Dec 2025"
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}';
    }
  } catch (e) {
    return date; // Return original if parsing fails
  }
}
  Widget _buildMethodChip(PaymentMethod method) {
    IconData icon;
    String label;
    Color color;
    
    switch (method) {
      case PaymentMethod.cheque:
        icon = Icons.receipt_long;
        label = 'Cheque';
        color = AppColors.secondaryColor;
        break;
      case PaymentMethod.bank:
        icon = Icons.account_balance;
        label = 'Bank Transfer';
        color = AppColors.blueColor;
        break;
      case PaymentMethod.cash:
        icon = Icons.money;
        label = 'Cash';
        color = AppColors.onlineGreen;
        break;
      case PaymentMethod.other:
        icon = Icons.payment;
        label = 'Other';
        color = AppColors.grey;
        break;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.black600),
          SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.black600,
              fontSize: 13,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasInstallments(LeaseDataModel leaseData) {
    if (leaseData.payment_groups == null) return false;
    
    final groups = leaseData.payment_groups!;
    return groups.cash.isNotEmpty || 
           groups.cheque.isNotEmpty || 
           groups.bank.isNotEmpty || 
           groups.other.isNotEmpty;
  }

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

  // Helper method to get overdue payments
  List<PaymentInstallmentModel> _getOverduePayments(List<PaymentInstallmentModel> installments) {
    final now = DateTime.now();
    return installments.where((installment) {
      // Check if payment is pending and has an expected date
      if (installment.payment_status?.toLowerCase() != 'pending') return false;
      
      // Try to get expected date from different fields
      String? dateStr = installment.expected_date ?? 
                        installment.cheque_date ?? 
                        installment.transfer_date ?? 
                        installment.cash_payment_date ?? 
                        installment.otherpaymentdate;
      
      if (dateStr == null) return false;
      
      try {
        final expectedDate = DateTime.parse(dateStr);
        // Payment is overdue if expected date is before today
        return expectedDate.isBefore(now) && !_isSameDay(expectedDate, now);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Helper to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
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
        if (installment.cheque_number != null)
          _buildDetailRow(Icons.numbers, 'Cheque Number', installment.cheque_number!),
        if (installment.cheque_date != null)
          _buildDetailRow(Icons.calendar_today, 'Cheque Date', installment.cheque_date!),
        if (installment.cheque_bank_name != null)
          _buildDetailRow(Icons.account_balance, 'Bank Name', installment.cheque_bank_name!),
        if (installment.cheque_image != null)
          _buildImagePreview('Cheque Image', installment.cheque_image!),
      ],
    );
  }

  Widget _buildBankTransferDetails(PaymentInstallmentModel installment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (installment.transaction_reference != null)
          _buildDetailRow(Icons.tag, 'Transaction Ref', installment.transaction_reference!),
        if (installment.transfer_bank_name != null)
          _buildDetailRow(Icons.account_balance, 'Bank Name', installment.transfer_bank_name!),
        if (installment.transfer_date != null)
          _buildDetailRow(Icons.calendar_today, 'Transfer Date', installment.transfer_date!),
        if (installment.transfer_proof != null)
          _buildImagePreview('Transfer Proof', installment.transfer_proof!),
      ],
    );
  }

  Widget _buildCashDetails(PaymentInstallmentModel installment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (installment.receipt_number != null)
          _buildDetailRow(Icons.receipt, 'Receipt Number', installment.receipt_number!),
        if (installment.cash_payment_date != null)
          _buildDetailRow(Icons.calendar_today, 'Payment Date', installment.cash_payment_date!),
        if (installment.receipt_image != null)
          _buildImagePreview('Receipt Image', installment.receipt_image!),
      ],
    );
  }

  Widget _buildOtherPaymentDetails(PaymentInstallmentModel installment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (installment.payment_description != null)
          _buildDetailRow(Icons.description, 'Description', installment.payment_description!),
        if (installment.payment_reference != null)
          _buildDetailRow(Icons.tag, 'Reference', installment.payment_reference!),
        if (installment.otherpaymentdate != null)
          _buildDetailRow(Icons.calendar_today, 'Payment Date', installment.otherpaymentdate!),
        if (installment.payment_image != null)
          _buildImagePreview('Payment Proof', installment.payment_image!),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.black600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String label, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image, size: 16, color: AppColors.black600),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.black600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Get.dialog(
                Dialog(
                  backgroundColor: Colors.transparent,
                  child: Stack(
                    children: [
                      Center(
                        child: Image.network(imageUrl),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: IconButton(
                          icon: Icon(Icons.close, color: AppColors.white, size: 30),
                          onPressed: () => Get.back(),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.black500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.lightGrey),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
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
                          Icon(Icons.broken_image, size: 32, color: AppColors.grey),
                          SizedBox(height: 4),
                          Text(
                            'Failed to load image',
                            style: TextStyle(fontSize: 11, color: AppColors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryColor,
                      ),
                    );
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