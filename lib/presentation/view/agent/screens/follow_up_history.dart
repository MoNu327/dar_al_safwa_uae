// follow_up_history_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/data/model/followup_history_response.dart';
import 'package:get/get.dart';

class FollowUpHistoryDetailScreen extends StatelessWidget {
  final FollowUpHistoryItem historyItem;

  const FollowUpHistoryDetailScreen({
    super.key,
    required this.historyItem,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const CustomTextWidget(
          title: 'Follow-up Details',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            _buildStatusHeader(),
            
            SizedBox(height: screenHeight2),
            
            // Basic Information
            _buildSectionHeader('Basic Information'),
            _buildDetailCard(
              children: [
                _buildDetailRow('Follow-up ID:', historyItem.id),
                _buildDetailRow('Created Date:', historyItem.formattedCreatedAt),
                _buildDetailRow('Updated Date:', _formatDate(historyItem.updatedAt)),
                if (historyItem.followupDate.isNotEmpty)
                  _buildDetailRow('Follow-up Date:', historyItem.formattedFollowupDate),
              ],
            ),
            
            SizedBox(height: screenHeight2),
            
            // Customer Information
            _buildSectionHeader('Customer Information'),
            _buildDetailCard(
              children: [
                _buildDetailRow('Customer ID:', historyItem.customerId),
              ],
            ),
            
            SizedBox(height: screenHeight2),
            
            // Property Information
            _buildSectionHeader('Property Information'),
            _buildDetailCard(
              children: [
                _buildDetailRow('Property ID:', historyItem.propertyId),
                _buildDetailRow('Unit Type:', historyItem.unitType),
              ],
            ),
            
            SizedBox(height: screenHeight2),
            
            // Technician Information (if available)
            if (historyItem.technicianId != null && historyItem.technicianId!.isNotEmpty) ...[
              _buildSectionHeader('Technician Information'),
              _buildDetailCard(
                children: [
                  _buildDetailRow('Technician ID:', historyItem.technicianId!),
                ],
              ),
              SizedBox(height: screenHeight2),
            ],
            
            // Flag Information (if available)
            if (historyItem.flag != null && historyItem.flag!.isNotEmpty) ...[
              _buildSectionHeader('Additional Information'),
              _buildDetailCard(
                children: [
                  _buildDetailRow('Flag:', historyItem.flag!),
                ],
              ),
              SizedBox(height: screenHeight2),
            ],
            
            // Notes Section
            _buildSectionHeader('Follow-up Notes'),
            _buildDetailCard(
              children: [
                _buildNotesContent(historyItem.notes),
              ],
            ),
            
            SizedBox(height: screenHeight3),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth2),
      decoration: BoxDecoration(
        color: historyItem.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: historyItem.statusColor),
      ),
      child: Row(
        children: [
          Icon(
            historyItem.statusIcon,
            size: 24,
            color: historyItem.statusColor,
          ),
          SizedBox(width: screenWidth1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextWidget(
                  title: historyItem.saleStatusText,
                  fontSize: 16,
                  color: historyItem.statusColor,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: screenHeight05),
                CustomTextWidget(
                  title: 'Status: ${_getStatusDescription(historyItem.saleStatus)}',
                  fontSize: 12,
                  color: historyItem.statusColor.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight1),
      child: CustomTextWidget(
        title: title,
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: AppColors.secondaryColor,
      ),
    );
  }

  Widget _buildDetailCard({required List<Widget> children}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(screenWidth2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: Get.width * 0.35,
            child: CustomTextWidget(
              title: label,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: CustomTextWidget(
              title: value.isNotEmpty ? value : 'Not available',
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesContent(String notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: 'Notes:',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        SizedBox(height: screenHeight1),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(screenWidth2),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300] ?? Colors.grey),
          ),
          child: CustomTextWidget(
            title: notes.isNotEmpty ? notes : 'No notes provided',
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _getStatusDescription(int status) {
    switch (status) {
      case 1:
        return 'Property Visit Pending - Customer is waiting for property visit';
      case 2:
        return 'Property Visit Scheduled - Visit has been arranged';
      case 3:
        return 'Property Visited - Site visit completed';
      case 4:
        return 'Property Agreed - Customer has agreed to proceed';
      default:
        return 'Unknown status';
    }
  }
}