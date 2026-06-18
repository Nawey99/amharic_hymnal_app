import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/features/settings/data/repositories/bug_report_repository_impl.dart';
import 'package:amharic_hymnal_app/features/settings/domain/repositories/bug_report_repository.dart';

void main() {
  const payload = BugReportPayload(
    title: 'Search crash',
    description: 'Searching by number crashes the app.',
    contactEmail: 'tester@example.com',
    diagnostics: {'selected_version': 'sda_new'},
  );

  test('returns submitted when backend submission succeeds', () async {
    var queued = false;
    final repository = BugReportRepositoryImpl(
      submitter: (_) async => true,
      queuer: (_) async {
        queued = true;
        return true;
      },
    );

    final result = await repository.submit(payload);

    expect(result.submitted, isTrue);
    expect(result.queued, isFalse);
    expect(queued, isFalse);
  });

  test('queues report when backend submission fails', () async {
    final calls = <String>[];
    final repository = BugReportRepositoryImpl(
      submitter: (_) async {
        calls.add('submit');
        return false;
      },
      queuer: (_) async {
        calls.add('queue');
        return true;
      },
    );

    final result = await repository.submit(payload);

    expect(result.submitted, isFalse);
    expect(result.queued, isTrue);
    expect(result.message, contains('queued'));
    expect(calls, ['submit', 'queue']);
  });

  test('queues report when backend submission throws', () async {
    final repository = BugReportRepositoryImpl(
      submitter: (_) async => throw StateError('offline'),
      queuer: (_) async => true,
    );

    final result = await repository.submit(payload);

    expect(result.submitted, isFalse);
    expect(result.queued, isTrue);
  });
}
