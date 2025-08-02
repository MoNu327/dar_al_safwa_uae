import 'package:dio/dio.dart';

String parseDioError(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout) {
    return 'Connection timeout. Please check your internet.';
  } else if (e.response != null) {
    // Try to get server error message
    return e.response?.data?['message']?.toString() ??
        e.response?.statusMessage?.toString() ??
        'Server error (${e.response?.statusCode})';
  } else {
    return e.message?.toString() ?? 'Network error occurred';
  }
}
