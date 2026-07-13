// lib/core/error/error_handler.dart
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:amharic_hymnal_app/core/error/failures.dart';
import 'package:amharic_hymnal_app/core/error/exceptions.dart';

/// Centralized error handler for consistent error processing across the app
class ErrorHandler {
  /// Handle exceptions and convert to user-friendly failures
  static Failure handleException(dynamic exception) {
    if (kDebugMode) {
      debugPrint('🔴 ErrorHandler: $exception');
    }

    if (exception is DatabaseNotFoundException) {
      return const CacheFailure('Database not found');
    }

    if (exception is DatabaseNotReadyException) {
      return const CacheFailure('Database is not ready');
    }

    // Check for database-related error strings
    final errorString = exception.toString().toLowerCase();
    if (errorString.contains('database') ||
        errorString.contains('sqlite') ||
        errorString.contains('not ready') ||
        errorString.contains('cache')) {
      return const CacheFailure();
    }

    // Default to cache failure for unknown errors (most errors in this app are cache-related)
    return const CacheFailure();
  }

  /// Get user-friendly error message from failure
  static String getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Unable to connect to server. Please check your internet connection.';
    }

    if (failure is CacheFailure) {
      return 'Unable to load data. Please try again later.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Log error with context
  static void logError(
    String context,
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalInfo,
  }) {
    if (kDebugMode) {
      debugPrint('🔴 Error in $context: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
      if (additionalInfo != null && additionalInfo.isNotEmpty) {
        debugPrint('Additional info: $additionalInfo');
      }
    }
    // In production, you might want to send this to a crash reporting service
    // e.g., Firebase Crashlytics, Sentry, etc.
  }

  /// Handle and log error, returning a failure
  static Failure handleAndLog(
    String context,
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalInfo,
  }) {
    logError(context, error,
        stackTrace: stackTrace, additionalInfo: additionalInfo);
    return handleException(error);
  }
}
