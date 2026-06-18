// lib/core/services/bug_report_queue_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Service for managing bug report queue (offline support)
///
/// Stores bug reports locally when offline and submits them when online.
/// This ensures bug reports are never lost, even when the user is offline.
class BugReportQueueService {
  static BugReportQueueService? _instance;
  static BugReportQueueService get instance {
    _instance ??= BugReportQueueService._();
    return _instance!;
  }

  BugReportQueueService._();

  SharedPreferences? _prefs;
  static const String _queueKey = 'bug_report_queue';

  /// Initialize the service
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Add a bug report to the queue
  ///
  /// [title] - Bug report title
  /// [description] - Bug report description
  /// Returns true if successfully queued
  Future<bool> queueBugReport(String title, String description) async {
    await init();
    try {
      final reports = await getQueuedReports();
      final newReport = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
        'submitted': false,
      };
      reports.add(newReport);
      final jsonString = jsonEncode(reports);
      final success = await _prefs?.setString(_queueKey, jsonString) ?? false;
      if (kDebugMode) {
        debugPrint('✅ Queued bug report: $title');
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to queue bug report: $e');
      }
      return false;
    }
  }

  /// Get all queued bug reports
  ///
  /// Returns list of bug reports that haven't been submitted yet
  Future<List<Map<String, dynamic>>> getQueuedReports() async {
    await init();
    try {
      final jsonString = _prefs?.getString(_queueKey);
      if (jsonString == null) {
        return [];
      }
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get queued reports: $e');
      }
      return [];
    }
  }

  /// Get pending (unsubmitted) bug reports
  ///
  /// Returns list of bug reports that haven't been submitted
  Future<List<Map<String, dynamic>>> getPendingReports() async {
    final reports = await getQueuedReports();
    return reports.where((report) => report['submitted'] == false).toList();
  }

  /// Mark a bug report as submitted
  ///
  /// [reportId] - ID of the report to mark as submitted
  Future<bool> markAsSubmitted(String reportId) async {
    await init();
    try {
      final reports = await getQueuedReports();
      final index = reports.indexWhere((r) => r['id'] == reportId);
      if (index != -1) {
        reports[index]['submitted'] = true;
        final jsonString = jsonEncode(reports);
        final success = await _prefs?.setString(_queueKey, jsonString) ?? false;
        if (kDebugMode) {
          debugPrint('✅ Marked bug report as submitted: $reportId');
        }
        return success;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to mark report as submitted: $e');
      }
      return false;
    }
  }

  /// Remove a bug report from the queue
  ///
  /// [reportId] - ID of the report to remove
  Future<bool> removeReport(String reportId) async {
    await init();
    try {
      final reports = await getQueuedReports();
      reports.removeWhere((r) => r['id'] == reportId);
      final jsonString = jsonEncode(reports);
      final success = await _prefs?.setString(_queueKey, jsonString) ?? false;
      if (kDebugMode) {
        debugPrint('✅ Removed bug report: $reportId');
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to remove report: $e');
      }
      return false;
    }
  }

  /// Clear all submitted reports (keep pending ones)
  Future<bool> clearSubmittedReports() async {
    await init();
    try {
      final reports = await getQueuedReports();
      final pending = reports.where((r) => r['submitted'] == false).toList();
      final jsonString = jsonEncode(pending);
      final success = await _prefs?.setString(_queueKey, jsonString) ?? false;
      if (kDebugMode) {
        debugPrint('✅ Cleared submitted reports');
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to clear submitted reports: $e');
      }
      return false;
    }
  }

  /// Get count of pending reports
  Future<int> getPendingCount() async {
    final pending = await getPendingReports();
    return pending.length;
  }

  /// Submit a bug report (placeholder for future API integration)
  ///
  /// [title] - Bug report title
  /// [description] - Bug report description
  /// Returns true if successfully submitted, false otherwise
  ///
  /// Note: When API endpoint is available, implement actual submission here.
  /// For now, this is a placeholder that demonstrates the structure.
  Future<bool> submitBugReport(String title, String description) async {
    // TODO: Implement actual API call when endpoint is available
    // Example structure:
    // try {
    //   final response = await http.post(
    //     Uri.parse('https://api.example.com/bug-reports'),
    //     headers: {'Content-Type': 'application/json'},
    //     body: jsonEncode({
    //       'title': title,
    //       'description': description,
    //       'timestamp': DateTime.now().toIso8601String(),
    //     }),
    //   );
    //   return response.statusCode == 200 || response.statusCode == 201;
    // } catch (e) {
    //   return false;
    // }

    // For now, simulate submission
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}
