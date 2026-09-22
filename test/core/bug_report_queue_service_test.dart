import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/services/bug_report_queue_service.dart';

/// Runs [body] with every `http.post` answered by [handler].
Future<T> _withServer<T>(
  Future<http.Response> Function(http.Request request) handler,
  Future<T> Function() body,
) =>
    http.runWithClient(body, () => MockClient(handler));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final queue = BugReportQueueService.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'ውዳሴ',
      packageName: 'com.nawey99.wudase',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    // The singleton keeps its queue across tests; empty it.
    for (final report in await queue.getQueuedReports()) {
      await queue.removeReport(report['id'] as String);
    }
  });

  test('a queued report is kept until it is sent', () async {
    expect(await queue.queueBugReport('Verse 2', 'A word is missing.'), isTrue);

    final pending = await queue.getPendingReports();
    expect(pending, hasLength(1));
    expect(pending.single['title'], 'Verse 2');
    expect(await queue.getPendingCount(), 1);
  });

  test('flushing sends pending reports to POST /reports and clears them',
      () async {
    await queue.queueBugReport('Verse 2', 'A word is missing.');
    final posted = <http.Request>[];

    final sent = await _withServer((request) async {
      posted.add(request);
      return http.Response('{"success":true,"data":{"id":"r1"}}', 201);
    }, queue.flushPendingReports);

    expect(sent, 1);
    expect(posted.single.method, 'POST');
    expect(posted.single.url.path, endsWith('/reports'));
    expect(jsonDecode(posted.single.body)['message'],
        'Verse 2\n\nA word is missing.');
    expect(await queue.getPendingCount(), 0);
  });

  test('offline, reports stay queued for the next start', () async {
    await queue.queueBugReport('One', 'first');
    await queue.queueBugReport('Two', 'second');

    final sent = await _withServer(
      (_) async => throw http.ClientException('offline'),
      queue.flushPendingReports,
    );

    expect(sent, 0);
    expect(await queue.getPendingCount(), 2);
  });

  test('a rate limit stops the flush and keeps the rest for later', () async {
    await queue.queueBugReport('One', 'first');
    await queue.queueBugReport('Two', 'second');
    var calls = 0;

    final sent = await _withServer((_) async {
      calls++;
      return http.Response(
          '{"success":false,"error":{"code":"RATE_LIMIT_EXCEEDED"}}', 429);
    }, queue.flushPendingReports);

    expect(sent, 0);
    expect(calls, 1, reason: 'no point hammering a rate-limited inbox');
    expect(await queue.getPendingCount(), 2);
  });

  test('a report the server refuses is dropped so it cannot block the queue',
      () async {
    await queue.queueBugReport('Bad', 'refused');
    await queue.queueBugReport('Good', 'accepted');
    final messages = <String>[];

    final sent = await _withServer((request) async {
      final message = jsonDecode(request.body)['message'] as String;
      messages.add(message);
      return message.startsWith('Bad')
          ? http.Response(
              '{"success":false,"error":{"code":"VALIDATION_ERROR"}}', 400)
          : http.Response('{"success":true,"data":{}}', 201);
    }, queue.flushPendingReports);

    expect(messages, hasLength(2));
    expect(sent, 1);
    expect(await queue.getPendingCount(), 0);
  });

  test('a report about a renumbered hymn is resent without the hymn', () async {
    final bodies = <Map<String, dynamic>>[];

    final ok = await _withServer((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      bodies.add(body);
      return body.containsKey('songId')
          ? http.Response(
              '{"success":false,"error":{"code":"SONG_NOT_FOUND"}}', 404)
          : http.Response('{"success":true,"data":{}}', 201);
    },
        () => queue.submitBugReport('Verse 2', 'missing',
            diagnostics: {'songId': 'am-sda-1975-0130'}));

    expect(ok, isTrue);
    expect(bodies, hasLength(2));
    expect(bodies.last.containsKey('songId'), isFalse);
  });

  test('a report queued before the move to secure storage is migrated',
      () async {
    SharedPreferences.setMockInitialValues({
      'bug_report_queue': jsonEncode([
        {'id': 'old', 'title': 'Old', 'description': 'd', 'submitted': false},
      ]),
    });

    // A fresh service instance cannot be made, so this only holds if the
    // singleton has not initialised yet in this process.
    final pending = await queue.getPendingReports();
    expect(pending.map((report) => report['id']), contains('old'));
  },
      skip: 'Needs a fresh BugReportQueueService: the singleton migrates '
          'once per process and has already initialised in earlier tests');
}
