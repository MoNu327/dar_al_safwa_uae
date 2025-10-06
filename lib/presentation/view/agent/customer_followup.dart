import 'package:majan/data/model/followup_history_response.dart';
import 'package:majan/domain/controller/customer_followup_controller.dart';
import 'package:majan/domain/controller/submit_follow_up.dart';
import 'package:majan/presentation/view/agent/screens/follow_up_history.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/core/constants/custom_size.dart';

class CustomerFollowUpScreen extends StatefulWidget {
  final int propertyId;
  final String chatId;
  final String propertyName;
  final String agentEmail;
  final String unitId;
  final String customerId;
  
  const CustomerFollowUpScreen({
    super.key,
    required this.propertyId,
    required this.chatId, 
    required this.propertyName, 
    required this.agentEmail, 
    required this.unitId,
    required this.customerId,
  });

  @override
  State<CustomerFollowUpScreen> createState() => _CustomerFollowUpScreenState();
}
   
class _CustomerFollowUpScreenState extends State<CustomerFollowUpScreen> {
  final CustomerFollowUpController controller = Get.put(CustomerFollowUpController());
  
  String? selectedStatus;
  final TextEditingController _notesController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _currentTabIndex = 0; // 0: New Follow-up, 1: History

  @override
  void initState() {
    super.initState();
    _initializeData();
      _addTabChangeListener();
  }

void _addTabChangeListener() {
  // This will ensure history loads when switching to history tab
  // even if it wasn't loaded initially
  ever(controller.isHistoryLoading, (isLoading) {
    if (!isLoading && _currentTabIndex == 1 && controller.followUpHistory.isEmpty) {
      // If we're on history tab and no data is loaded, try loading
      _loadHistoryData();
    }
  });
}
  // Initialize data loading
void _initializeData() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Load customer follow-up data first
    controller.loadCustomerFollowUp(widget.chatId).then((_) {
      // After customer data is loaded, load history
      _loadHistoryData();
    });
  });
}

void _loadHistoryData() {
  // Use customer ID from follow-up data if available, otherwise use widget customerId
  final customerId = controller.followUpData.value?.userInfo.uid ?? widget.customerId;
  
  if (customerId.isNotEmpty && widget.propertyId != null) {
    print('Loading history with customer UID: $customerId');
    controller.loadFollowUpHistory(customerId, widget.propertyId.toString());
  } else {
    print('Warning: Missing customerId or propertyId for history loading');
    print('customerId: $customerId');
    print('propertyId: ${widget.propertyId}');
  }
}

  // Method to handle status change with improved logic
  void _onStatusChanged(String? status) {
    setState(() {
      selectedStatus = status;
      controller.setSelectedSupervisor(null);
    });
    
    if (status == 'Property Visit Scheduled') {
      controller.loadSupervisors(widget.propertyId);
    } else {
      controller.clearSupervisors();
      _notesController.clear();
    }
  }

  // Enhanced method to handle technician selection
  void _onTechnicianSelected(String? technicianId) {
    controller.setSelectedSupervisor(technicianId);
    
    if (technicianId != null && 
        technicianId.isNotEmpty && 
        selectedStatus == 'Property Visit Scheduled') {
      _generateSiteVisitNotes(technicianId);
    } else {
      // Only clear notes if it was auto-generated
      if (_notesController.text.contains('Your site visit is scheduled')) {
        _notesController.clear();
      }
    }
  }

  // Enhanced method to generate site visit notes
  void _generateSiteVisitNotes(String technicianId) {
    final followUpData = controller.followUpData.value;
    final selectedTechnician = controller.supervisorsList
        .firstWhereOrNull((tech) => tech.uid == technicianId);
    
    if (followUpData != null && selectedTechnician != null) {
      final now = DateTime.now();
      final formattedDate = '${_getMonthName(now.month)} ${now.day}, ${now.year}';
      
      final noteContent = '''Dear ${followUpData.userInfo.fullName},

Your site visit is scheduled for $formattedDate for:
- Property: ${followUpData.propertyInfo.title}
- Contact Person: ${selectedTechnician.fullName} (${selectedTechnician.mobile ?? 'N/A'})

Please ensure you are available at the scheduled time. The technician will contact you prior to the visit.

Best regards,
${followUpData.agentInfo.displayName}''';

      _notesController.text = noteContent;
    }
  }

  // Helper method to get month name
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  // Method to show confirmation dialog
  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const CustomTextWidget(
            title: 'Confirm Submission',
            fontWeight: FontWeight.bold,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomTextWidget(
                title: 'Please confirm the following details:',
                fontSize: 14,
              ),
              SizedBox(height: screenHeight1),
              CustomTextWidget(
                title: 'Status: $selectedStatus',
                fontSize: 12,
                color: Colors.grey[600],
              ),
              if (selectedStatus == 'Property Visit Scheduled' && 
                  controller.selectedSupervisor.value != null)
                CustomTextWidget(
                  title: 'Technician: ${controller.supervisorsList.firstWhereOrNull((s) => s.uid == controller.selectedSupervisor.value)?.fullName ?? 'N/A'}',
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              CustomTextWidget(
                title: 'Notes: ${_notesController.text.length > 50 ? '${_notesController.text.substring(0, 50)}...' : _notesController.text}',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const CustomTextWidget(
                title: 'Cancel',
                color: Colors.grey,
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryColor,
              ),
              child: const CustomTextWidget(
                title: 'Confirm',
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomTextWidget(
          title: _currentTabIndex == 0 ? 'Customer Follow-up' : 'Follow-up History',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _refreshData(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _currentTabIndex == 0 ? _buildNewFollowUpTab() : _buildHistoryTab(),
    );
  }

  Widget _buildNewFollowUpTab() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tab Section
            _buildTabSection(),
            
            SizedBox(height: screenHeight2),
            
            // Error Message Display
            Obx(() {
              if (controller.followUpErrorMessage.isNotEmpty) {
                return Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: screenHeight2),
                  padding: EdgeInsets.all(screenWidth2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600),
                      SizedBox(width: screenWidth1),
                      Expanded(
                        child: CustomTextWidget(
                          title: controller.followUpErrorMessage.value,
                          color: Colors.red.shade600,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        onPressed: () => controller.followUpErrorMessage(''),
                        icon: Icon(Icons.close, color: Colors.red.shade600),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            
            // Customer Information Section
            _buildCustomerInfoSection(),
            
            SizedBox(height: screenHeight2),
            
            // Property Information Section
            _buildPropertyInfoSection(),
            
            SizedBox(height: screenHeight2),
            
            // Agent Information Section
            _buildAgentInfoSection(),
            
            // Chat Information Section
            _buildChatInfoSection(),
            
            SizedBox(height: screenHeight2),
            
            // Property Sale Status Section
            _buildStatusSection(),
            
            SizedBox(height: screenHeight2),
            
            // Site Visit Supervisor Section
            if (selectedStatus == 'Property Visit Scheduled') 
              _buildSupervisorSection(),
            
            // Follow-up Notes Section
            _buildNotesSection(),
            
            SizedBox(height: screenHeight3),
            
            // Submit Button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

 Widget _buildHistoryTab() {
  return Column(
    children: [
      // Tab Section
      Padding(
        padding: EdgeInsets.all(screenWidth3),
        child: _buildTabSection(),
      ),
      
      // History Content
      Expanded(
        child: Obx(() {
          if (controller.isHistoryLoading.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (controller.historyErrorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  SizedBox(height: screenHeight2),
                  CustomTextWidget(
                    title: controller.historyErrorMessage.value,
                    textAlign: TextAlign.center,
                    color: Colors.grey,
                  ),
                  SizedBox(height: screenHeight2),
                  ElevatedButton(
                    onPressed: _loadHistoryData,
                    child: const CustomTextWidget(title: 'Retry'),
                  ),
                ],
              ),
            );
          }
          
          final historyList = controller.sortedHistory;
          
          if (historyList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey),
                  SizedBox(height: screenHeight2),
                  const CustomTextWidget(
                    title: 'No follow-up history found',
                    textAlign: TextAlign.center,
                    color: Colors.grey,
                  ),
                  SizedBox(height: screenHeight2),
                  ElevatedButton(
                    onPressed: _loadHistoryData,
                    child: const CustomTextWidget(title: 'Load History'),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              _loadHistoryData();
            },
            child: ListView.separated(
              padding: EdgeInsets.all(screenWidth3),
              itemCount: historyList.length,
              separatorBuilder: (context, index) => SizedBox(height: screenHeight2),
              itemBuilder: (context, index) {
                final historyItem = historyList[index];
                return _buildHistoryCard(historyItem);
              },
            ),
          );
        }),
      ),
    ],
  );
}
 // In your existing CustomerFollowUpScreen, update the _buildHistoryCard method:

Widget _buildHistoryCard(FollowUpHistoryItem historyItem) {
  return Card(
    elevation: 2,
    margin: EdgeInsets.zero,
    child: InkWell(
      onTap: () {
        // Navigate to detail screen when card is tapped
        _showFollowUpDetails(historyItem);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.all(screenWidth2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth1,
                    vertical: screenHeight05,
                  ),
                  decoration: BoxDecoration(
                    color: historyItem.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: historyItem.statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        historyItem.statusIcon,
                        size: 14,
                        color: historyItem.statusColor,
                      ),
                      SizedBox(width: screenWidth5),
                      CustomTextWidget(
                        title: historyItem.saleStatusText,
                        fontSize: 12,
                        color: historyItem.statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                CustomTextWidget(
                  title: historyItem.formattedCreatedAt,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ],
            ),
            
            SizedBox(height: screenHeight1),
            
            // Customer Information
            _buildHistoryInfoRow(
              'Customer ID:',
              historyItem.customerId,
            ),
            
            // Property Information
            _buildHistoryInfoRow(
              'Property:',
              'ID: ${historyItem.propertyId} | Unit: ${historyItem.unitType}',
            ),
            
            // Technician Information (if available)
            if (historyItem.technicianId != null && historyItem.technicianId!.isNotEmpty)
              _buildHistoryInfoRow(
                'Technician ID:',
                historyItem.technicianId!,
              ),
            
            // Flag Information (if available)
            if (historyItem.flag != null && historyItem.flag!.isNotEmpty)
              _buildHistoryInfoRow(
                'Flag:',
                historyItem.flag!,
              ),
            
            // Notes Preview (show first 100 characters)
            _buildHistoryInfoRow(
              'Notes:',
              _getNotesPreview(historyItem.notes),
            ),
            
            // Tap hint
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: EdgeInsets.only(top: screenHeight1),
                padding: EdgeInsets.symmetric(horizontal: screenWidth1, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 12,
                      color: AppColors.secondaryColor,
                    ),
                    SizedBox(width: 4),
                    CustomTextWidget(
                      title: 'Tap to view details',
                      fontSize: 10,
                      color: AppColors.secondaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Add this helper method to show notes preview
String _getNotesPreview(String notes) {
  if (notes.isEmpty) return 'No notes provided';
  if (notes.length <= 100) return notes;
  return '${notes.substring(0, 100)}...';
}

// Add this method to handle navigation to detail screen
void _showFollowUpDetails(FollowUpHistoryItem historyItem) {
  Get.to(
    () => FollowUpHistoryDetailScreen(historyItem: historyItem),
    transition: Transition.rightToLeft,
    duration: Duration(milliseconds: 300),
  );
}

  Widget _buildHistoryInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: Get.width * 0.25,
            child: CustomTextWidget(
              title: label,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: CustomTextWidget(
              title: value,
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
  return Row(
    children: [
      Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() => _currentTabIndex = 0);
          },
          child: Container(
            decoration: BoxDecoration(
              color: _currentTabIndex == 0 
                  ? AppColors.secondaryColor 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.secondaryColor,
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: screenHeight1),
            child: Center(
              child: CustomTextWidget(
                title: 'New Follow-up',
                color: _currentTabIndex == 0 ? Colors.white : AppColors.secondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      SizedBox(width: screenWidth2),
      Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() => _currentTabIndex = 1);
            // Load history when switching to history tab if not already loaded
            if (controller.followUpHistory.isEmpty && !controller.isHistoryLoading.value) {
              _loadHistoryData();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: _currentTabIndex == 1 
                  ? AppColors.secondaryColor 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.secondaryColor,
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: screenHeight1),
            child: Center(
              child: CustomTextWidget(
                title: 'Follow-up History',
                color: _currentTabIndex == 1 ? Colors.white : AppColors.secondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildCustomerInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Customer Information'),
        Obx(() {
          if (controller.isFollowUpLoading.value) {
            return _buildLoadingInfo();
          }
          
          final followUpData = controller.followUpData.value;
          if (followUpData == null) {
            return _buildInfoRow('Name:', 'Loading...');
          }
          
          return Column(
            children: [
              _buildInfoRow('Name:', followUpData.userInfo.fullName),
              _buildInfoRow('Contact:', 
                followUpData.userInfo.mobile ?? 
                followUpData.userInfo.phoneNumber ?? 
                'N/A'
              ),
              _buildInfoRow('Email:', followUpData.userInfo.email),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildPropertyInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Property Information'),
        Obx(() {
          if (controller.isFollowUpLoading.value) {
            return _buildLoadingInfo();
          }
          
          final followUpData = controller.followUpData.value;
          if (followUpData == null) {
            return _buildInfoRow('Property:', 'Loading...');
          }
          
          return Column(
            children: [
              _buildInfoRow('Property:', followUpData.propertyInfo.title),
              _buildInfoRow('Property ID:', followUpData.propertyInfo.id),
              _buildInfoRow('Unit Type:', followUpData.unitInfo.title),
              _buildInfoRow('Unit ID:', followUpData.unitInfo.id),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildAgentInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Agent Information'),
        Obx(() {
          if (controller.isFollowUpLoading.value) {
            return _buildLoadingInfo();
          }
          
          final followUpData = controller.followUpData.value;
          if (followUpData == null) {
            return _buildInfoRow('Name:', 'Loading...');
          }
          
          return Column(
            children: [
              _buildInfoRow('Name:', followUpData.agentInfo.displayName),
              _buildInfoRow('Email:', followUpData.agentInfo.email),
              _buildInfoRow('Mobile:', followUpData.agentInfo.mobile),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildChatInfoSection() {
    return Obx(() {
      if (controller.isFollowUpLoading.value) {
        return const SizedBox();
      }
      
      final followUpData = controller.followUpData.value;
      if (followUpData == null) {
        return const SizedBox();
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: screenHeight2),
          _buildSectionHeader('Chat Information'),
          _buildInfoRow('Status:', followUpData.chatInfo.status),
          _buildInfoRow('Last Message:', 
            followUpData.chatInfo.lastMessage.isNotEmpty ? 
            followUpData.chatInfo.lastMessage : 'No messages'
          ),
          _buildInfoRow('Last Activity:', 
            _formatDate(followUpData.chatInfo.lastMessageAt)
          ),
          _buildInfoRow('Created:', 
            _formatDate(followUpData.chatInfo.createdAt)
          ),
        ],
      );
    });
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Property Sale Status'),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: screenWidth2, vertical: screenHeight05),
          decoration: BoxDecoration(
            border: Border.all(color: selectedStatus == null ? Colors.red.shade300 : Colors.grey),
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
                  value: 'Property Visit Pending',
                  child: CustomTextWidget(title: 'Property Visit Pending'),
                ),
                DropdownMenuItem(
                  value: 'Property Visit Scheduled',
                  child: CustomTextWidget(title: 'Property Visit Scheduled'),
                ),
                DropdownMenuItem(
                  value: 'Property Visited',
                  child: CustomTextWidget(title: 'Property Visited'),
                ),
                DropdownMenuItem(
                  value: 'Property Agreed',
                  child: CustomTextWidget(title: 'Property Agreed'),
                ),
              ],
              onChanged: _onStatusChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupervisorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Site Visit Supervisor'),
        Obx(() {
          if (controller.isLoading.value) {
            return Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: screenWidth2, vertical: screenHeight2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: screenWidth2, vertical: screenHeight05),
            decoration: BoxDecoration(
              border: Border.all(color: controller.selectedSupervisor.value == null ? Colors.red.shade300 : Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const CustomTextWidget(
                  title: 'Select Technician',
                  color: Colors.grey,
                ),
                value: controller.selectedSupervisor.value,
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: CustomTextWidget(title: 'Select Technician'),
                  ),
                  ...controller.supervisorsList.map((supervisor) {
                    return DropdownMenuItem(
                      value: supervisor.uid,
                      child: CustomTextWidget(
                        title: '${supervisor.fullName} (${supervisor.mobile ?? 'N/A'})',
                      ),
                    );
                  }).toList(),
                ],
                onChanged: _onTechnicianSelected,
              ),
            ),
          );
        }),
        SizedBox(height: screenHeight2),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Follow-up Notes'),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _notesController.text.trim().isEmpty ? Colors.red.shade300 : Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: _notesController,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Enter detailed feedback about the interaction, next steps, or any special instructions...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter follow-up notes';
              }
              if (value.trim().length < 10) {
                return 'Notes should be at least 10 characters long';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() {
      final isLoading = controller.isLoading.value || 
                       controller.isFollowUpLoading.value || 
                       controller.isSubmitting.value;
      
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : _submitFollowUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: isLoading ? Colors.grey : AppColors.secondaryColor,
            padding: EdgeInsets.symmetric(vertical: screenHeight2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isLoading 
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const CustomTextWidget(
                title: 'Submit Follow-up',
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
        ),
      );
    });
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

  Widget _buildLoadingInfo() {
    return Column(
      children: [
        _buildInfoRow('Name:', 'Loading...'),
        _buildInfoRow('Contact:', 'Loading...'),
        _buildInfoRow('Email:', 'Loading...'),
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

  // Enhanced submit method with validation and confirmation
 void _submitFollowUp() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Use controller's validation method
    final validationError = controller.validateFormData(
      selectedStatus: selectedStatus,
      selectedSupervisor: controller.selectedSupervisor.value,
      notes: _notesController.text,
    );

    if (validationError != null) {
      Get.snackbar(
        'Validation Error',
        validationError,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(screenWidth2),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    // Get the follow-up data for additional context
    final followUpData = controller.followUpData.value;
    if (followUpData == null) {
      Get.snackbar(
        'Error',
        'Follow-up data not loaded. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(screenWidth2),
      );
      return;
    }

    // Use the customer UID from the follow-up data
    final String customerId = followUpData.userInfo.uid; // This is the UID
    final String unitType = followUpData.unitInfo.title;
    final String technicianId = selectedStatus == 'Property Visit Scheduled' 
        ? controller.selectedSupervisor.value! 
        : '';
    final int saleStatus = controller.getStatusValue(selectedStatus!);
    final String notes = _notesController.text.trim();

    print('Submitting follow-up with customer UID: $customerId');

    // Submit the follow-up
    final success = await controller.submitFollowUp(
      customerId: customerId, // Pass the UID
      propertyId: widget.propertyId,
      unitType: unitType,
      technicianId: technicianId,
      saleStatus: saleStatus,
      notes: notes,
    );

    if (success) {
      Get.snackbar(
        'Success',
        'Follow-up submitted successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(screenWidth2),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      // Refresh history after successful submission using the same UID
      controller.loadFollowUpHistory(customerId, widget.propertyId.toString());
      
      // Switch to history tab to show the new entry
      setState(() {
        _currentTabIndex = 1;
      });
    } else {
      Get.snackbar(
        'Submission Failed',
        controller.followUpErrorMessage.value.isNotEmpty 
            ? controller.followUpErrorMessage.value 
            : 'Failed to submit follow-up. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(screenWidth2),
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }

  // Refresh all data
  // Refresh all data
void _refreshData() {
  if (_currentTabIndex == 0) {
    // Refresh new follow-up tab
    controller.loadCustomerFollowUp(widget.chatId);
  } else {
    // Refresh history tab
    _loadHistoryData();
  }
  
  Get.snackbar(
    'Refreshing',
    'Data is being updated...',
    backgroundColor: Colors.blue,
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP,
    margin: EdgeInsets.all(screenWidth2),
  );
}

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}