import 'package:intl/intl.dart';

/// Utility class for handling timezone conversions to Oman time (GST - UTC+4)
class TimezoneHelper {
  // Oman timezone offset (Gulf Standard Time - UTC+4)
  static const int omanOffsetHours = 4;
  
  /// Converts a UTC timestamp string to Oman time
  static DateTime convertToOmanTime(String utcTimestamp) {
    try {
      // Parse the UTC timestamp
      DateTime utcTime = DateTime.parse(utcTimestamp);
      
      // If it's already in local time, convert to UTC first
      if (!utcTime.isUtc) {
        utcTime = utcTime.toUtc();
      }
      
      // Add Oman offset (UTC+4)
      final omanTime = utcTime.add(const Duration(hours: omanOffsetHours));
      
      return omanTime;
    } catch (e) {
      print('Error converting timestamp to Oman time: $e');
      // Return current Oman time as fallback
      return DateTime.now().toUtc().add(const Duration(hours: omanOffsetHours));
    }
  }
  
  /// Formats timestamp to readable string in Oman time
  static String formatOmanTime(String utcTimestamp, {String format = 'dd MMM yyyy, hh:mm a'}) {
    try {
      final omanTime = convertToOmanTime(utcTimestamp);
      return DateFormat(format).format(omanTime);
    } catch (e) {
      print('Error formatting Oman time: $e');
      return utcTimestamp;
    }
  }
  
  /// Formats timestamp for notification display (e.g., "Today at 2:30 PM", "Yesterday at 5:00 PM")
  static String formatNotificationTime(String utcTimestamp) {
    try {
      final omanTime = convertToOmanTime(utcTimestamp);
      final now = DateTime.now().toUtc().add(const Duration(hours: omanOffsetHours));
      final difference = now.difference(omanTime);
      
      // Same day - show "Today at HH:MM AM/PM"
      if (difference.inDays == 0 && omanTime.day == now.day) {
        final timeFormat = DateFormat('h:mm a').format(omanTime);
        return 'Today at $timeFormat';
      } 
      // Yesterday - show "Yesterday at HH:MM AM/PM"
      else if (difference.inDays == 1 || (difference.inHours < 48 && omanTime.day == now.day - 1)) {
        final timeFormat = DateFormat('h:mm a').format(omanTime);
        return 'Yesterday at $timeFormat';
      } 
      // Within last 7 days - show "Day at HH:MM AM/PM"
      else if (difference.inDays < 7) {
        final dayFormat = DateFormat('EEEE').format(omanTime);
        final timeFormat = DateFormat('h:mm a').format(omanTime);
        return '$dayFormat at $timeFormat';
      }
      // Older - show "DD MMM YYYY at HH:MM AM/PM"
      else {
        final dateFormat = DateFormat('dd MMM yyyy').format(omanTime);
        final timeFormat = DateFormat('h:mm a').format(omanTime);
        return '$dateFormat at $timeFormat';
      }
    } catch (e) {
      print('Error formatting notification time: $e');
      return utcTimestamp;
    }
  }
  
  /// Get current Oman time
  static DateTime getCurrentOmanTime() {
    return DateTime.now().toUtc().add(const Duration(hours: omanOffsetHours));
  }
  
  /// Format date only (DD MMM YYYY)
  static String formatDateOnly(String utcTimestamp) {
    try {
      final omanTime = convertToOmanTime(utcTimestamp);
      return DateFormat('dd MMM yyyy').format(omanTime);
    } catch (e) {
      print('Error formatting date: $e');
      return utcTimestamp;
    }
  }
  
  /// Format time only (HH:MM AM/PM)
  static String formatTimeOnly(String utcTimestamp) {
    try {
      final omanTime = convertToOmanTime(utcTimestamp);
      return DateFormat('h:mm a').format(omanTime);
    } catch (e) {
      print('Error formatting time: $e');
      return utcTimestamp;
    }
  }
  
  /// Format full date and time (DD MMM YYYY, HH:MM AM/PM)
  static String formatFullDateTime(String utcTimestamp) {
    try {
      final omanTime = convertToOmanTime(utcTimestamp);
      return DateFormat('dd MMM yyyy, h:mm a').format(omanTime);
    } catch (e) {
      print('Error formatting full date time: $e');
      return utcTimestamp;
    }
  }
}