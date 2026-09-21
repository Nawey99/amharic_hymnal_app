import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/services/bug_report_queue_service.dart';
import 'package:amharic_hymnal_app/features/settings/domain/repositories/bug_report_repository.dart';

const _base = 'https://api.example.test/api/v1';

({Uri uri, Map<String, Object?> body}) _build(
  Map<String, dynamic> diagnostics, {
  String? contact,
}) =>
    BugReportQueueService.buildRequest(
      baseUrl: _base,
      title: 'Verse 2',
      description: 'A word is missing.',
      contactEmail: contact,
      diagnostics: diagnostics,
      appVersion: '1.0.0+1',
      platform: 'android',
    );

void main() {
  test('files a hymn report under the hymn\'s own edition', () {
    const payload = BugReportPayload(
      title: 'Verse 2',
      description: 'A word is missing.',
      type: ReportType.lyrics,
      songId: 'am-sda-1975-0130',
      screen: 'hymn',
      // The user has 2004 selected, but the hymn is from 1975.
      diagnostics: {'selectedVersion': 'sda_new', 'language': 'am'},
    );

    final request = _build(payload.queuedDiagnostics);

    expect(request.uri.path, '/api/v1/reports');
    expect(request.uri.queryParameters['version'], 'am-sda-1975');
    expect(request.body, {
      'category': 'LYRICS',
      'message': 'Verse 2\n\nA word is missing.',
      'songId': 'am-sda-1975-0130',
      'context': {
        'appVersion': '1.0.0+1',
        'platform': 'android',
        'screen': 'hymn',
        'locale': 'am',
      },
    });
  });

  test('a report from Settings is an app bug in the selected edition', () {
    const payload = BugReportPayload(
      title: 'Verse 2',
      description: 'A word is missing.',
      diagnostics: {'selectedVersion': 'sda_1960'},
    );

    final request = _build(payload.queuedDiagnostics, contact: ' a@b.org ');

    expect(request.uri.queryParameters['version'], 'am-sda-1961');
    expect(request.body['category'], 'APP_BUG');
    expect(request.body.containsKey('songId'), isFalse);
    expect(request.body['contact'], 'a@b.org');
    expect((request.body['context'] as Map)['screen'], 'settings');
  });

  test('reports queued by the previous version still send', () {
    // Queued before reports had a type: no reportCategory, songId or screen.
    final request = _build({'selectedVersion': 'sda_old'});

    expect(request.uri.queryParameters['version'], 'am-sda-1975');
    expect(request.body['category'], 'APP_BUG');
  });

  test('every report type is one the inbox accepts', () {
    expect(
      ReportType.values.map((type) => type.apiValue),
      ['LYRICS', 'SHEET_MUSIC', 'AUDIO', 'APP_BUG', 'SUGGESTION', 'OTHER'],
    );
    for (final type in ReportType.values) {
      final request = _build(
        BugReportPayload(title: 't', description: 'd', type: type)
            .queuedDiagnostics,
      );
      expect(request.body['category'], type.apiValue);
    }
  });
}
