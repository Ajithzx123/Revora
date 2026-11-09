import 'package:dio/dio.dart';

/// A short message safe to show to the user for a failed API call.
String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          return first['msg'].toString();
        }
      }
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Check your connection and try again.';
      default:
        break;
    }
    final code = error.response?.statusCode;
    if (code == 413) return 'That file is too large.';
    if (code == 415) return 'Only PDF, JPEG and PNG files are accepted.';
    if (code != null && code >= 500) {
      return 'Something went wrong on our side. Please try again.';
    }
  }
  return error.toString().replaceAll('Exception:', '').trim();
}
