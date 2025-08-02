// utils/date_formatter.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  // Format any DateTime string to 12-hour format
  static String formatTo12Hour(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
    } catch (e) {
      debugPrint('Date parsing error: $e');
      return dateString; // Return original if parsing fails
    }
  }

  // Format current date to 12-hour format
  static String formatCurrentDate() {
    return DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now());
  }

  // Format to ISO8601 with time (for database storage)
  static String toIso8601String(DateTime date) {
    return date.toIso8601String();
  }

  // Format from ISO8601 to display format
  static String fromIso8601ToDisplay(String isoString) {
    try {
      return formatTo12Hour(isoString);
    } catch (e) {
      debugPrint('ISO8601 parsing error: $e');
      return isoString;
    }
  }

  // New: Format for Firestore timestamps
  static String fromFirestoreTimestamp(dynamic timestamp) {
    try {
      final date = timestamp.toDate();
      return DateFormat('MMM dd, yyyy hh:mm a').format(date);
    } catch (e) {
      debugPrint('Timestamp parsing error: $e');
      return timestamp.toString();
    }
  }
}