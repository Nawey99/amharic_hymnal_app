// lib/core/error/exceptions.dart

/// Custom exceptions used in the app. These are thrown by data sources and
/// caught by repositories to map into `Failure` objects.
class DatabaseNotFoundException implements Exception {
  final String message;
  DatabaseNotFoundException([this.message = 'Database not found']);

  @override
  String toString() => 'DatabaseNotFoundException: $message';
}

class DatabaseNotReadyException implements Exception {
  final String message;
  DatabaseNotReadyException([this.message = 'Database is not ready']);

  @override
  String toString() => 'DatabaseNotReadyException: $message';
}
