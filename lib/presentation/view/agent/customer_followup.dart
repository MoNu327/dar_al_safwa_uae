import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/core/constants/custom_size.dart';

class CustomerFollowUpScreen extends StatefulWidget {
  const CustomerFollowUpScreen({super.key});

  @override
  State<CustomerFollowUpScreen> createState() => _CustomerFollowUpScreenState();
}

class _CustomerFollowUpScreenState extends State<CustomerFollowUpScreen> {
  String? selectedStatus;
  String? selectedSupervisor;
  
  final TextEditingController _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const CustomTextWidget(
          title: 'Customer Follow-up Details',
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
            // New Follow-up / Follow-up History tabs
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: screenHeight1),
                    child: const Center(
                      child: CustomTextWidget(
                        title: 'New Follow-up',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth2),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.secondaryColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: screenHeight1),
                    child: const Center(
                      child: CustomTextWidget(
                        title: 'Follow-up History',
                        color: AppColors.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: screenHeight2),
            
            // Customer Information Section
            _buildSectionHeader('Customer Information'),
            _buildInfoRow('Name:', 'User Not Found'),
            _buildInfoRow('Contact:', 'N/A'),
            _buildInfoRow('Email:', 'N/A'),
            
            SizedBox(height: screenHeight2),
            
            // Property Information Section
            _buildSectionHeader('Property Information'),
            _buildInfoRow('Property:', 'Majan Complex- Khaboura'),
            _buildInfoRow('Block:', ''),
            _buildInfoRow('Unit Type:', '1BHK'),
            _buildInfoRow('Reference:', '83'),
            
            SizedBox(height: screenHeight2),
            
            // Agent Information Section
            _buildSectionHeader('Agent Information'),
            _buildInfoRow('Name:', 'Sudhakar Poojary'),
            _buildInfoRow('Agency:', 'N/A'),
            _buildInfoRow('Agent ID:', 'eTNK3FBYtTaI8shatz1ysILZBGE3'),
            
            SizedBox(height: screenHeight2),
            
            // Property Sale Status Section
            _buildSectionHeader('Property Sale Status'),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: screenWidth2, vertical: screenHeight05),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const CustomTextWidget(
                    title: 'Select Status',
                    color: Colors.grey,
                  ),
                  value: selectedStatus,
                  items: const [
                    DropdownMenuItem(
                      value: 'Interested',
                      child: CustomTextWidget(title: 'Interested'),
                    ),
                    DropdownMenuItem(
                      value: 'Not Interested',
                      child: CustomTextWidget(title: 'Not Interested'),
                    ),
                    DropdownMenuItem(
                      value: 'Follow-up Required',
                      child: CustomTextWidget(title: 'Follow-up Required'),
                    ),
                    DropdownMenuItem(
                      value: 'Deal Closed',
                      child: CustomTextWidget(title: 'Deal Closed'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value;
                    });
                  },
                ),
              ),
            ),
            
            SizedBox(height: screenHeight2),
            
            // Site Visit Supervisor Section
            _buildSectionHeader('Site Visit Supervisor'),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: screenWidth2, vertical: screenHeight05),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const CustomTextWidget(
                    title: 'Select Supervisor',
                    color: Colors.grey,
                  ),
                  value: selectedSupervisor,
                  items: const [
                    DropdownMenuItem(
                      value: 'Supervisor 1',
                      child: CustomTextWidget(title: 'Supervisor 1'),
                    ),
                    DropdownMenuItem(
                      value: 'Supervisor 2',
                      child: CustomTextWidget(title: 'Supervisor 2'),
                    ),
                    DropdownMenuItem(
                      value: 'Supervisor 3',
                      child: CustomTextWidget(title: 'Supervisor 3'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedSupervisor = value;
                    });
                  },
                ),
              ),
            ),
            
            SizedBox(height: screenHeight2),
            
            // Follow-up Notes Section
            _buildSectionHeader('Follow-up Notes'),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Enter detailed feedback about the interaction, next steps, or any special instructions...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
            
            SizedBox(height: screenHeight3),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle follow-up submission
                  _submitFollowUp();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryColor,
                  padding: EdgeInsets.symmetric(vertical: screenHeight2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const CustomTextWidget(
                  title: 'Submit Follow-up',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: Get.width * 0.3,
            child: CustomTextWidget(
              title: label,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: CustomTextWidget(
              title: value.isNotEmpty ? value : 'N/A',
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  void _submitFollowUp() {
    // Handle the submission of follow-up data
    if (selectedStatus == null) {
      Get.snackbar(
        'Error',
        'Please select a status',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    // Process the data
    final followUpData = {
      'status': selectedStatus,
      'supervisor': selectedSupervisor,
      'notes': _notesController.text,
    };
    
    // Here you would typically send this data to your backend
    print('Follow-up data: $followUpData');
    
    Get.snackbar(
      'Success',
      'Follow-up submitted successfully',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    
    // Navigate back or reset the form
    Get.back();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}