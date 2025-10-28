import 'package:majan/data/model/notification_model.dart';
import 'package:majan/domain/controller/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/presentation/view_model/localization_controller.dart';

class NotificationsScreen extends StatelessWidget {
  NotificationsScreen({super.key});
  
  final NotificationController notificationController = Get.find<NotificationController>();
  final LocalizationController localizationController = Get.find<LocalizationController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.secondaryColor,
        elevation: 0,
        title: CustomTextWidget(
          title: localizationController.translate('notifications'),
          fontSize: Get.height * 0.022,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryColor,
        ),
        actions: [
          Obx(() {
            if (notificationController.notifications.isNotEmpty) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'mark_all_read':
                      notificationController.markAllAsRead();
                      Get.snackbar(
                        'Success',
                        'All notifications marked as read',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                      break;
                    case 'clear_all':
                      _showClearAllDialog();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        const Icon(Icons.mark_email_read),
                        const SizedBox(width: 8),
                        Text('Mark All Read'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        const Icon(Icons.clear_all, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Clear All',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Icon(Icons.more_vert, color: Colors.white),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (notificationController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          );
        }

        if (notificationController.notifications.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            notificationController.loadStoredNotifications();
          },
          color: AppColors.primaryColor,
          child: _buildNotificationsList(),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: Get.height * 0.1,
            color: Colors.grey[400],
          ),
          SizedBox(height: Get.height * 0.02),
          CustomTextWidget(
            title: 'No Notifications',
            fontSize: Get.height * 0.02,
            color: Colors.grey[600]!,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Get.height * 0.01),
          CustomTextWidget(
            title: 'Your notifications will appear here',
            fontSize: Get.height * 0.016,
            color: Colors.grey[500]!,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    final groupedNotifications = _groupNotificationsByDate();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedNotifications.keys.length,
      itemBuilder: (context, index) {
        final dateKey = groupedNotifications.keys.elementAt(index);
        final notifications = groupedNotifications[dateKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(dateKey),
            ...notifications.map((notification) => _buildNotificationItem(notification)),
            SizedBox(height: Get.height * 0.02),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(String dateKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: CustomTextWidget(
        title: dateKey,
        fontSize: Get.height * 0.018,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : AppColors.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead ? Colors.grey[200]! : AppColors.primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          notificationController.markAsRead(notification.id);
          _handleNotificationTap(notification);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(notification.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextWidget(
                            title: notification.title,
                            fontSize: Get.height * 0.018,
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                            color: notification.isRead ? Colors.black87 : Colors.black,
                            maxLines: 2,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    CustomTextWidget(
                      title: notification.body,
                      fontSize: Get.height * 0.016,
                      color: Colors.grey[600]!,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomTextWidget(
                          title: _formatTime(notification.timestamp),
                          fontSize: Get.height * 0.014,
                          color: Colors.grey[500]!,
                        ),
                        _buildNotificationTypeChip(notification.type),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'mark_read':
                      notificationController.markAsRead(notification.id);
                      break;
                    case 'delete':
                      _showDeleteDialog(notification);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (!notification.isRead)
                    PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          const Icon(Icons.mark_email_read, size: 18),
                          const SizedBox(width: 8),
                          Text('Mark as Read'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert, color: Colors.grey, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'chat':
      case 'message':
        iconData = Icons.chat;
        iconColor = Colors.blue;
        break;
      case 'technician_assignment':
      case 'technician_ticket':
      case 'technician_rectify':
        iconData = Icons.build;
        iconColor = Colors.orange;
        break;
      case 'property':
      case 'property_update':
      case 'tenant_property':
        iconData = Icons.home;
        iconColor = Colors.green;
        break;
      case 'ticket':
      case 'complaint':
      case 'tenant_ticket':
        iconData = Icons.support;
        iconColor = Colors.red;
        break;
      case 'enquiry':
        iconData = Icons.help;
        iconColor = Colors.purple;
        break;
      case 'approval_pending':
        iconData = Icons.pending;
        iconColor = Colors.amber;
        break;
      case 'tenant_documents':
        iconData = Icons.description;
        iconColor = Colors.indigo;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = AppColors.primaryColor;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildNotificationTypeChip(String type) {
    String displayType = _getDisplayType(type);
    Color chipColor = _getChipColor(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        displayType,
        style: TextStyle(
          color: chipColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getDisplayType(String type) {
    switch (type) {
      case 'chat':
      case 'message':
        return 'Chat';
      case 'technician_assignment':
        return 'Assignment';
      case 'technician_ticket':
        return 'Ticket';
      case 'technician_rectify':
        return 'Rectify';
      case 'job_update':
        return 'Job Update';
      case 'property':
      case 'property_update':
        return 'Property';
      case 'tenant_property':
        return 'Property';
      case 'ticket':
      case 'complaint':
      case 'tenant_ticket':
        return 'Support';
      case 'enquiry':
        return 'Enquiry';
      case 'approval_pending':
        return 'Approval';
      case 'tenant_documents':
        return 'Documents';
      default:
        return 'General';
    }
  }

  Color _getChipColor(String type) {
    switch (type) {
      case 'chat':
      case 'message':
        return Colors.blue;
      case 'technician_assignment':
      case 'technician_ticket':
      case 'technician_rectify':
      case 'job_update':
        return Colors.orange;
      case 'property':
      case 'property_update':
      case 'tenant_property':
        return Colors.green;
      case 'ticket':
      case 'complaint':
      case 'tenant_ticket':
        return Colors.red;
      case 'enquiry':
        return Colors.purple;
      case 'approval_pending':
        return Colors.amber;
      case 'tenant_documents':
        return Colors.indigo;
      default:
        return AppColors.primaryColor;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }

  Map<String, List<NotificationModel>> _groupNotificationsByDate() {
    final Map<String, List<NotificationModel>> grouped = {};
    final now = DateTime.now();

    for (final notification in notificationController.notifications) {
      final notificationDate = notification.timestamp;
      String dateKey;

      if (_isSameDay(notificationDate, now)) {
        dateKey = 'Today';
      } else if (_isSameDay(notificationDate, now.subtract(const Duration(days: 1)))) {
        dateKey = 'Yesterday';
      } else if (now.difference(notificationDate).inDays < 7) {
        dateKey = DateFormat('EEEE').format(notificationDate);
      } else {
        dateKey = DateFormat('MMM dd, yyyy').format(notificationDate);
      }

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(notification);
    }

    return grouped;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

 void _handleNotificationTap(NotificationModel notification) {
  // Use the new controller method that handles both PDFs and regular navigation
  notificationController.handleNotificationTap(notification);
}
  void _showDeleteDialog(NotificationModel notification) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              notificationController.deleteNotification(notification.id);
              Get.back();
              Get.snackbar(
                'Success',
                'Notification deleted',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              notificationController.clearAllNotifications();
              Get.back();
              Get.snackbar(
                'Success',
                'All notifications cleared',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}