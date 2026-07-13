// lib/core/database/database_web.dart
import 'package:drift/drift.dart';
// ignore: deprecated_member_use
import 'package:drift/web.dart';

LazyDatabase openConnection() {
  // For web, Drift uses IndexedDB with sql.js
  // sql.js must be loaded in web/index.html before this code runs
  // The script tag is added in web/index.html to load sql.js from CDN
  return LazyDatabase(() async {
    // Wait for sql.js to be available (with timeout)
    int attempts = 0;
    const maxAttempts = 50; // 5 seconds total (50 * 100ms)

    while (attempts < maxAttempts) {
      try {
        // Try to create WebDatabase - it will throw if sql.js isn't ready
        return WebDatabase('hymns.db');
      } catch (e) {
        // Check if it's a sql.js error
        if (e.toString().contains('sql.js') ||
            e.toString().contains('sqljs') ||
            e.toString().contains('Could not access')) {
          attempts++;
          if (attempts >= maxAttempts) {
            throw Exception(
                'sql.js is not available after waiting. Please ensure the sql.js script is included in web/index.html. '
                'Add: <script src="https://cdn.jsdelivr.net/npm/sql.js@1.8.0/dist/sql-wasm.js"></script> '
                'Error: $e');
          }
          // Wait a bit before retrying
          await Future.delayed(const Duration(milliseconds: 100));
          continue;
        }
        // If it's a different error, rethrow it
        rethrow;
      }
    }

    // Should never reach here, but just in case
    throw Exception(
        'Failed to initialize database after $maxAttempts attempts');
  });
}
