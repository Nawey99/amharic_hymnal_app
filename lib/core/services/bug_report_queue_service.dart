// lib/core/services/bug_report_queue_service.dart
import 'dart:convert';
import 'package:amharic_hymnal_app/core/config/content_api_config.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/services/song_editions_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'
    show
        TargetPlatform,
        debugPrint,
        defaultTargetPlatform,
        kDebugMode,
        kIsWeb,
        visibleForTesting;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

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

  static const String _queueKey = 'bug_report_queue';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  Future<void>? _initialization;

  /// Initialize the service
  Future<void> init() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (kIsWeb) return;

    final preferences = await SharedPreferences.getInstance();
    final legacyQueue = preferences.getString(_queueKey);
    if (legacyQueue == null) return;

    final secureQueue = await _secureStorage.read(key: _queueKey);
    if (secureQueue == null) {
      await _secureStorage.write(key: _queueKey, value: legacyQueue);
    }
    await preferences.remove(_queueKey);
  }

  /// Add a bug report to the queue
  ///
  /// [title] - Bug report title
  /// [description] - Bug report description
  /// Returns true if successfully queued
  Future<bool> queueBugReport(
    String title,
    String description, {
    String? contactEmail,
    String severity = 'normal',
    Map<String, dynamic>? diagnostics,
  }) async {
    // A browser cannot protect a locally held encryption key from page script.
    // Web reports are submitted directly and are not persisted when offline.
    if (kIsWeb) return false;
    await init();
    try {
      final reports = await getQueuedReports();
      final newReport = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'description': description,
        'contact_email': contactEmail,
        'severity': severity,
        'diagnostics': diagnostics ?? {},
        'timestamp': DateTime.now().toIso8601String(),
        'submitted': false,
      };
      reports.add(newReport);
      final success = await _writeReports(reports);
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
    if (kIsWeb) return [];
    await init();
    try {
      final jsonString = await _secureStorage.read(key: _queueKey);
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
        final success = await _writeReports(reports);
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
      final success = await _writeReports(reports);
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
      final success = await _writeReports(pending);
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

  Future<bool> _writeReports(List<Map<String, dynamic>> reports) async {
    if (kIsWeb) return false;
    if (reports.isEmpty) {
      await _secureStorage.delete(key: _queueKey);
    } else {
      await _secureStorage.write(key: _queueKey, value: jsonEncode(reports));
    }
    return true;
  }

  /// Retries queued reports without blocking app startup.
  Future<int> flushPendingReports() async {
    final pending = await getPendingReports();
    var submittedCount = 0;
    for (final report in pending) {
      final outcome = await _send(
        report['title'] as String? ?? '',
        report['description'] as String? ?? '',
        contactEmail: report['contact_email'] as String?,
        diagnostics:
            (report['diagnostics'] as Map?)?.cast<String, dynamic>() ?? {},
      );
      if (outcome == _SendOutcome.retryLater) break;
      // Sent, or refused for good: a report the server will never accept
      // must not sit at the head of the queue blocking every later one.
      await removeReport(report['id'] as String? ?? '');
      if (outcome == _SendOutcome.sent) submittedCount += 1;
    }
    return submittedCount;
  }

  Future<bool> submitBugReport(
    String title,
    String description, {
    String? contactEmail,
    String severity = 'normal',
    Map<String, dynamic>? diagnostics,
  }) async {
    final outcome = await _send(
      title,
      description,
      contactEmail: contactEmail,
      diagnostics: diagnostics ?? const {},
    );
    return outcome == _SendOutcome.sent;
  }

  /// Sends one report to the hymnal API's report inbox
  /// (`POST /reports`), where it appears in the admin console.
  Future<_SendOutcome> _send(
    String title,
    String description, {
    String? contactEmail,
    required Map<String, dynamic> diagnostics,
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      var request = buildRequest(
        baseUrl: ContentApiConfig.baseUrl,
        title: title,
        description: description,
        contactEmail: contactEmail,
        diagnostics: diagnostics,
        appVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
        platform: _platformName,
      );
      var response = await _post(request);

      // SONG_NOT_FOUND: the hymn is not in that edition (it may have been
      // renumbered since). The report still matters; send it without one.
      if (response.statusCode == 404 && request.body.containsKey('songId')) {
        request = buildRequest(
          baseUrl: ContentApiConfig.baseUrl,
          title: title,
          description: description,
          contactEmail: contactEmail,
          diagnostics: {...diagnostics}..remove('songId'),
          appVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
          platform: _platformName,
        );
        response = await _post(request);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _SendOutcome.sent;
      }
      if (response.statusCode == 429 || response.statusCode >= 500) {
        return _SendOutcome.retryLater;
      }
      if (kDebugMode) {
        debugPrint(
          'Bug report refused (${response.statusCode}): ${response.body}',
        );
      }
      return _SendOutcome.rejected;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Bug report submit failed, queueing locally: $e');
      }
      return _SendOutcome.retryLater;
    }
  }

  Future<http.Response> _post(({Uri uri, Map<String, Object?> body}) request) {
    return http
        .post(
          request.uri,
          headers: {'content-type': 'application/json; charset=utf-8'},
          body: jsonEncode(request.body),
        )
        .timeout(const Duration(seconds: 8));
  }

  static const _reportCategories = {
    'LYRICS',
    'SHEET_MUSIC',
    'AUDIO',
    'APP_BUG',
    'SUGGESTION',
    'OTHER',
  };

  /// The `POST /reports` request for one report. A report about a hymn is
  /// filed under that hymn's edition, taken from its ID; otherwise under the
  /// edition the user has selected.
  @visibleForTesting
  static ({Uri uri, Map<String, Object?> body}) buildRequest({
    required String baseUrl,
    required String title,
    required String description,
    String? contactEmail,
    required Map<String, dynamic> diagnostics,
    required String appVersion,
    required String platform,
  }) {
    final message = [title.trim(), description.trim()]
        .where((part) => part.isNotEmpty)
        .join('\n\n');
    final contact = contactEmail?.trim() ?? '';

    final songIdValue = diagnostics['songId'];
    final songId =
        songIdValue is String && songIdValue.isNotEmpty ? songIdValue : null;
    final selectedVersion = diagnostics['selectedVersion'];
    final version =
        (songId == null ? null : SongEditionsService.versionCodeOf(songId)) ??
            HymnalVersions.apiCode(
              selectedVersion is String && selectedVersion.isNotEmpty
                  ? selectedVersion
                  : HymnalVersions.sdaNew,
            );

    final categoryValue = diagnostics['reportCategory'];
    final category = _reportCategories.contains(categoryValue)
        ? categoryValue as String
        : 'APP_BUG';
    final screenValue = diagnostics['screen'];
    final language = diagnostics['language'];

    return (
      uri: Uri.parse('$baseUrl/reports').replace(
        queryParameters: {'language': 'am', 'version': version},
      ),
      body: {
        'category': category,
        'message': message.length > 4000 ? message.substring(0, 4000) : message,
        if (songId != null) 'songId': songId,
        if (contact.length >= 3) 'contact': contact,
        'context': {
          'appVersion': appVersion,
          'platform': platform,
          'screen': screenValue is String && screenValue.isNotEmpty
              ? screenValue
              : 'settings',
          if (language is String && language.isNotEmpty) 'locale': language,
        },
      },
    );
  }

  /// One of the values the report inbox accepts.
  String get _platformName {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'other',
    };
  }
}

enum _SendOutcome { sent, retryLater, rejected }
