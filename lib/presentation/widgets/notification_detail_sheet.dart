import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/data/model/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationDetailSheet extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailSheet({super.key, required this.notification});

  // ── Public entry point ────────────────────────────────────────────────────
  static void show(NotificationModel notification) {
    Get.bottomSheet(
      NotificationDetailSheet(notification: notification),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
    );
  }

  // ── Colour/icon lookup ────────────────────────────────────────────────────
  static _TypeMeta _meta(String type, [Map<String, dynamic>? data]) {
    final urgency = data?['urgency'] as String? ??
        data?['subType'] as String? ??
        '';

    switch (type) {
      case 'chat':
      case 'message':
        return _TypeMeta(Icons.chat_bubble_rounded, Colors.blue, 'Message');

      case 'ticket':
      case 'complaint':
      case 'tenant_ticket':
      case 'complaint_reply':
      case 'ticket_reply':
      case 'ticket_update':
      case 'complaint_status_update':
      case 'new_complaint':
      case 'new_ticket':
        return _TypeMeta(Icons.support_agent_rounded, Colors.green, 'Ticket');

      case 'follow_up':
      case 'followup':
      case 'site_visit':
      case 'property_visit_scheduled':
      case 'property_visit_pending':
      case 'property_visited':
      case 'property_agreed':
        return _TypeMeta(Icons.event_note_rounded, Colors.orange, 'Follow‑up');

      case 'booking':
      case 'property_booking':
      case 'new_booking':
      case 'booking_confirmed':
        return _TypeMeta(Icons.event_available_rounded, Colors.teal, 'Booking');

      case 'contract_expiry':
        final expired = urgency == 'expired' || urgency == 'critical';
        return _TypeMeta(Icons.assignment_late_rounded,
            expired ? Colors.red : Colors.orange, 'Contract');

      case 'document_expiry':
        final expired = urgency == 'expired' || urgency == 'critical';
        return _TypeMeta(Icons.description_rounded,
            expired ? Colors.red : Colors.blue, 'Document');

      case 'payment_reminder':
      case 'upcoming_payment':
        final overdue = urgency == 'overdue' || urgency == 'critical';
        return _TypeMeta(Icons.receipt_long_rounded,
            overdue ? Colors.red : Colors.green, 'Payment');

      case 'property_interest':
      case 'customer_interest':
      case 'property_enquiry':
      case 'enquiry':
      case 'customer_enquiry':
        return _TypeMeta(Icons.question_answer_rounded, Colors.indigo, 'Enquiry');

      case 'technician_assignment':
      case 'technician_ticket':
      case 'job_update':
      case 'technician_rectify':
        return _TypeMeta(Icons.engineering_rounded, Colors.orange, 'Assignment');

      case 'property':
      case 'property_update':
      case 'tenant_property':
        return _TypeMeta(Icons.home_work_rounded, Colors.purple, 'Property');

      case 'tenant_documents':
      case 'document':
      case 'letter':
      case 'lease_renewal':
        return _TypeMeta(Icons.folder_rounded, Colors.teal, 'Document');

      case 'custom_notice':
      case 'pdf_notice':
      case 'notice_pdf':
      case 'tenant_notice':
        return _TypeMeta(Icons.campaign_rounded, Colors.red, 'Notice');

      case 'approval_pending':
        return _TypeMeta(Icons.pending_actions_rounded, Colors.amber, 'Approval');

      default:
        return _TypeMeta(Icons.notifications_rounded, AppColors.secondaryColor,
            'Notification');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final meta = _meta(notification.type, notification.data);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Handle bar ────────────────────────────────────────────
              const _HandleBar(),

              // ── Header ────────────────────────────────────────────────
              _Header(notification: notification, meta: meta),

              const Divider(height: 1, indent: 20, endIndent: 20),

              // ── Scrollable body ───────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    // Body text
                    if (notification.body.isNotEmpty)
                      _BodySection(body: notification.body),

                    // Type-specific details
                    _TypeSpecificSection(notification: notification),

                    // Image if present
                    if (notification.imageUrl != null &&
                        notification.imageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          notification.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Action button
                    _ActionButton(notification: notification, meta: meta),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Internal sub-widgets ──────────────────────────────────────────────────

class _HandleBar extends StatelessWidget {
  const _HandleBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final NotificationModel notification;
  final _TypeMeta meta;

  const _Header({required this.notification, required this.meta});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle with accent colour
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: meta.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(meta.icon, color: meta.color, size: 24),
          ),
          const SizedBox(width: 14),

          // Title + type chip + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Type chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: meta.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        meta.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: meta.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Unread dot
                    if (!notification.isRead)
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: meta.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1C),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(notification.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close_rounded),
            color: Colors.grey[500],
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM dd, yyyy · hh:mm a').format(ts);
  }
}

class _BodySection extends StatelessWidget {
  final String body;

  const _BodySection({required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        body,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF2C2C2C),
          height: 1.6,
        ),
      ),
    );
  }
}

// ── Type-specific structured data ─────────────────────────────────────────

class _TypeSpecificSection extends StatelessWidget {
  final NotificationModel notification;

  const _TypeSpecificSection({required this.notification});

  @override
  Widget build(BuildContext context) {
    final data = notification.data ?? {};
    final type = notification.type;

    switch (type) {
      case 'payment_reminder':
      case 'upcoming_payment':
        return _PaymentSection(data: data);

      case 'contract_expiry':
        return _ExpirySection(
          data: data,
          label: 'Contract Expiry',
          color: Colors.orange,
        );

      case 'document_expiry':
        return _ExpirySection(
          data: data,
          label: 'Document Expiry',
          color: Colors.blue,
        );

      case 'booking':
      case 'property_booking':
      case 'new_booking':
      case 'booking_confirmed':
        return _BookingSection(data: data);

      case 'follow_up':
      case 'followup':
      case 'site_visit':
      case 'property_visit_scheduled':
      case 'property_visit_pending':
      case 'property_visited':
      case 'property_agreed':
        return _VisitSection(data: data);

      case 'chat':
      case 'message':
        return _ChatSection(data: data);

      default:
        return const SizedBox.shrink();
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor ?? Colors.grey[500]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1C1C1C),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  final Color? borderColor;

  const _SectionCard({required this.children, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: borderColor?.withOpacity(0.25) ?? Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ── Payment section ──────────────────────────────────────────────────────

class _PaymentSection extends StatelessWidget {
  final Map<String, dynamic> data;

  const _PaymentSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final amount = _parseAmount(data['amount']);
    final property = data['property_title'] as String?;
    final unit = data['unit_number']?.toString();
    final method = data['payment_method'] as String?;
    final dueDate = data['expected_date'] as String? ??
        data['cheque_date'] as String? ??
        data['cash_payment_date'] as String?;
    final chequeNum = data['cheque_number'] as String?;
    final bank = data['cheque_bank_name'] as String? ??
        data['transfer_bank_name'] as String?;

    if (amount == null && property == null && dueDate == null) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      borderColor: Colors.green,
      children: [
        // Amount highlight
        if (amount != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount Due',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(
                  'OMR ${amount.toStringAsFixed(3)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        if (property != null && property.isNotEmpty)
          _InfoRow(
              icon: Icons.home_rounded,
              label: 'Property',
              value: property,
              iconColor: Colors.green),

        if (unit != null && unit.isNotEmpty)
          _InfoRow(
              icon: Icons.apartment_rounded,
              label: 'Unit',
              value: unit,
              iconColor: Colors.green),

        if (dueDate != null && dueDate.isNotEmpty)
          _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Due Date',
              value: _formatDate(dueDate),
              iconColor: Colors.red),

        if (method != null && method.isNotEmpty)
          _InfoRow(
              icon: Icons.payment_rounded,
              label: 'Payment Method',
              value: method.toUpperCase(),
              iconColor: Colors.orange),

        if (chequeNum != null && chequeNum.isNotEmpty)
          _InfoRow(
              icon: Icons.receipt_rounded,
              label: 'Cheque Number',
              value: chequeNum),

        if (bank != null && bank.isNotEmpty)
          _InfoRow(
              icon: Icons.account_balance_rounded,
              label: 'Bank',
              value: bank),
      ],
    );
  }

  double? _parseAmount(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }
}

// ── Expiry section ───────────────────────────────────────────────────────

class _ExpirySection extends StatelessWidget {
  final Map<String, dynamic> data;
  final String label;
  final Color color;

  const _ExpirySection(
      {required this.data, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final daysRaw = data['daysUntilExpiry'];
    int? days;
    if (daysRaw is int) {
      days = daysRaw;
    } else if (daysRaw is String) {
      days = int.tryParse(daysRaw);
    }

    final property = data['propertyName'] as String? ??
        data['documentName'] as String?;
    final expiryDate = data['expiryDate'] as String?;
    final docType = data['documentType'] as String?;

    final badgeColor = days == null
        ? color
        : days <= 0
            ? Colors.red
            : days <= 7
                ? Colors.orange
                : color;

    final badgeText = days == null
        ? label
        : days <= 0
            ? 'EXPIRED'
            : days == 1
                ? 'EXPIRES TOMORROW'
                : 'EXPIRES IN $days DAYS';

    return _SectionCard(
      borderColor: badgeColor,
      children: [
        // Urgency badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: badgeColor),
              const SizedBox(width: 6),
              Text(
                badgeText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        if (property != null && property.isNotEmpty)
          _InfoRow(
              icon: Icons.home_rounded, label: 'Property/Item', value: property),

        if (docType != null && docType.isNotEmpty)
          _InfoRow(
              icon: Icons.category_rounded, label: 'Type', value: docType),

        if (expiryDate != null && expiryDate.isNotEmpty)
          _InfoRow(
            icon: Icons.event_rounded,
            label: 'Expiry Date',
            value: _formatDate(expiryDate),
            iconColor: badgeColor,
          ),
      ],
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }
}

// ── Booking section ──────────────────────────────────────────────────────

class _BookingSection extends StatelessWidget {
  final Map<String, dynamic> data;

  const _BookingSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final customer = data['customerName'] as String?;
    final property = data['propertyName'] as String?;
    final date = data['bookingDate'] as String?;

    if (customer == null && property == null && date == null) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      borderColor: Colors.teal,
      children: [
        if (customer != null && customer.isNotEmpty)
          _InfoRow(
              icon: Icons.person_rounded,
              label: 'Customer',
              value: customer,
              iconColor: Colors.teal),
        if (property != null && property.isNotEmpty)
          _InfoRow(
              icon: Icons.home_rounded,
              label: 'Property',
              value: property,
              iconColor: Colors.teal),
        if (date != null && date.isNotEmpty)
          _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Booking Date',
              value: date,
              iconColor: Colors.teal),
      ],
    );
  }
}

// ── Site visit section ───────────────────────────────────────────────────

class _VisitSection extends StatelessWidget {
  final Map<String, dynamic> data;

  const _VisitSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final notes = data['notes'] as String?;
    final location = notes != null ? _extractLocation(notes) : null;
    final phone = notes != null ? _extractPhone(notes) : null;

    if (location == null && phone == null) return const SizedBox.shrink();

    return _SectionCard(
      borderColor: Colors.orange,
      children: [
        if (phone != null) ...[
          _TappableRow(
            icon: Icons.phone_rounded,
            label: 'Contact Number',
            value: phone,
            color: Colors.blue,
            onTap: () => _launchUrl('tel:$phone'),
            trailingLabel: 'Tap to call',
          ),
          const SizedBox(height: 8),
        ],
        if (location != null) ...[
          _TappableRow(
            icon: Icons.location_on_rounded,
            label: 'Location',
            value: location.startsWith('http') ? 'View on Maps' : location,
            color: Colors.green,
            onTap: () => _launchUrl(
              location.startsWith('http')
                  ? location
                  : 'https://maps.google.com/?q=${Uri.encodeComponent(location)}',
            ),
            trailingLabel: 'Open map',
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: location));
                  Get.snackbar('Copied', 'Location copied to clipboard',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.black87,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2));
                },
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text('Copy location', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static String? _extractLocation(String text) {
    final pattern = RegExp(
        r'(?:Location|Address|Where|Place):\s*(.+?)(?:\n|Phone|Mobile|$)',
        caseSensitive: false,
        multiLine: true);
    final match = pattern.firstMatch(text);
    if (match != null) return match.group(1)?.trim();
    final urlMatch = RegExp(r'https?://[^\s]+').firstMatch(text);
    if (urlMatch != null) return urlMatch.group(0);
    return null;
  }

  static String? _extractPhone(String text) {
    final pattern = RegExp(
        r'(?:Phone|Mobile|Contact|Tel|Call):\s*([\d\s\+\-\(\)]+)',
        caseSensitive: false,
        multiLine: true);
    final match = pattern.firstMatch(text);
    return match?.group(1)?.trim();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _TappableRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;
  final String trailingLabel;

  const _TappableRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    required this.trailingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color)),
                ],
              ),
            ),
            Text(trailingLabel,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontStyle: FontStyle.italic)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
          ],
        ),
      ),
    );
  }
}

// ── Chat section ─────────────────────────────────────────────────────────

class _ChatSection extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ChatSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final sender = data['userName'] as String? ??
        data['user_name'] as String? ??
        data['senderName'] as String?;
    final message = data['message'] as String? ?? data['chatMessage'] as String?;

    if (sender == null && message == null) return const SizedBox.shrink();

    return _SectionCard(
      borderColor: Colors.blue,
      children: [
        if (sender != null)
          _InfoRow(
              icon: Icons.person_rounded,
              label: 'From',
              value: sender,
              iconColor: Colors.blue),
        if (message != null && message.isNotEmpty) ...[
          const Divider(height: 16),
          Text('Message',
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(height: 6),
          Text(message,
              style: const TextStyle(
                  fontSize: 14, height: 1.5, color: Color(0xFF2C2C2C))),
        ],
      ],
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final NotificationModel notification;
  final _TypeMeta meta;

  const _ActionButton({required this.notification, required this.meta});

  @override
  Widget build(BuildContext context) {
    final data = notification.data ?? {};
    final label = _actionLabel;
    if (label == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Get.back();
          _performAction(data);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: meta.color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label,
            style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  String? get _actionLabel {
    final data = notification.data ?? {};
    switch (notification.type) {
      case 'follow_up':
      case 'followup':
      case 'site_visit':
      case 'property_visit_scheduled':
      case 'property_visit_pending':
      case 'property_visited':
      case 'property_agreed':
        final notes = data['notes'] as String?;
        final loc = notes != null ? _VisitSection._extractLocation(notes) : null;
        if (loc != null) return 'Open Location in Maps';
        return null;
      default:
        return null;
    }
  }

  void _performAction(Map<String, dynamic> data) async {
    switch (notification.type) {
      case 'follow_up':
      case 'followup':
      case 'site_visit':
      case 'property_visit_scheduled':
      case 'property_visit_pending':
      case 'property_visited':
      case 'property_agreed':
        final notes = data['notes'] as String?;
        if (notes == null) return;
        final loc = _VisitSection._extractLocation(notes);
        if (loc == null) return;
        final url = loc.startsWith('http')
            ? loc
            : 'https://maps.google.com/?q=${Uri.encodeComponent(loc)}';
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) await launchUrl(uri);
        break;
    }
  }
}

// ── Data model ───────────────────────────────────────────────────────────

class _TypeMeta {
  final IconData icon;
  final Color color;
  final String label;

  const _TypeMeta(this.icon, this.color, this.label);
}
