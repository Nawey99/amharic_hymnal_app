import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/features/settings/domain/repositories/bug_report_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:amharic_hymnal_app/core/services/bug_report_queue_service.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/settings/presentation/pages/report_bug_page.dart';

import '../../helpers/test_app.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _field(int index) => find.byType(TextFormField).at(index);

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'ውዳሴ',
      packageName: 'com.nawey99.wudase',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    Hymn? hymn,
    BugReportRepository? repository,
  }) async {
    await setUpTestApp();
    // Opened on top of another screen, as in the app: from a hymn, the page
    // closes itself once the report is handled.
    await pumpInApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ReportBugPage(hymn: hymn, repository: repository),
              ),
            ),
            child: const Text('open report'),
          ),
        ),
      ),
      size: const Size(412, 1400),
    );
    await tester.tap(find.text('open report'));
    await _settle(tester);
  }

  Future<void> send(WidgetTester tester, {bool waitForResult = true}) async {
    await tester.ensureVisible(find.text('ሪፖርት ላክ'));
    await tester.tap(find.text('ሪፖርት ላክ'));
    // The request and the secure-storage queue run on real async I/O (the
    // test binding answers HTTP with 400), so wait for the page to finish.
    for (var i = 0; waitForResult && i < 50; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(SnackBar).evaluate().isNotEmpty) break;
    }
    await _settle(tester);
  }

  group('validation', () {
    testWidgets('an empty form names each missing field', (tester) async {
      await pumpPage(tester);

      await send(tester, waitForResult: false);

      expect(find.text('እባክዎ ርዕስ ያስገቡ'), findsOneWidget);
      expect(find.text('እባክዎ መግለጫ ያስገቡ'), findsOneWidget);
    });

    testWidgets('too-short title and description are refused', (tester) async {
      await pumpPage(tester);

      await tester.enterText(_field(0), 'ab');
      await tester.enterText(_field(2), 'short');
      await send(tester, waitForResult: false);

      expect(find.text('ርዕሱ ቢያንስ 3 ፊደላት መሆን አለበት'), findsOneWidget);
      expect(find.text('መግለጫው ቢያንስ 10 ፊደላት መሆን አለበት'), findsOneWidget);
    });

    testWidgets('a malformed email is refused, an empty one is fine',
        (tester) async {
      await pumpPage(tester);

      await tester.enterText(_field(1), 'not-an-email');
      await send(tester, waitForResult: false);
      expect(find.text('ትክክለኛ ኢሜይል ያስገቡ'), findsOneWidget);

      await tester.enterText(_field(1), '');
      await send(tester, waitForResult: false);
      expect(find.text('ትክክለኛ ኢሜይል ያስገቡ'), findsNothing);
    });
  });

  group('report type', () {
    testWidgets('from Settings it defaults to an app problem', (tester) async {
      await pumpPage(tester);

      final chip = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('report_type_appBug')),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('from a hymn it defaults to a lyrics problem', (tester) async {
      await pumpPage(
        tester,
        hymn: const Hymn(id: 'am-sda-2004-0132', number: 132, title: 't'),
      );

      final chip = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('report_type_lyrics')),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('choosing a type selects only that one', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byKey(const ValueKey('report_type_audio')));
      await tester.pump();

      final selected = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .where((chip) => chip.selected)
          .toList();
      expect(selected, hasLength(1));
      expect(selected.single.key, const ValueKey('report_type_audio'));
    });
  });

  testWidgets(
      'a report the server does not accept is kept on the phone with its '
      'type and hymn', (tester) async {
    await pumpPage(
      tester,
      hymn: const Hymn(id: 'am-sda-1975-0130', number: 130, title: 't'),
    );
    await tester.tap(find.byKey(const ValueKey('report_type_sheetMusic')));
    await tester.enterText(_field(0), 'የተሳሳተ ገጽ');
    await tester.enterText(_field(2), 'ገጹ የሌላ መዝሙር ነው ብዬ አስባለሁ።');

    await send(tester);

    expect(find.text('ሪፖርቱ ተቀምጧል። ኢንተርኔት ሲኖር ይላካል።'), findsOneWidget);
    expect(find.byType(ReportBugPage), findsNothing,
        reason: 'back on the hymn once the report is safe');
    final queued = await tester.runAsync(
      () => BugReportQueueService.instance.getQueuedReports(),
    );
    final report = queued!.last;
    expect(report['title'], 'የተሳሳተ ገጽ');
    final diagnostics = report['diagnostics'] as Map;
    expect(diagnostics['reportCategory'], 'SHEET_MUSIC');
    expect(diagnostics['songId'], 'am-sda-1975-0130');
    expect(diagnostics['screen'], 'hymn');
  });

  testWidgets('a report the server accepts shows "sent" and clears the form',
      (tester) async {
    final repository = _AcceptingRepository();
    await pumpPage(tester, repository: repository);

    await tester.enterText(_field(0), 'የተሳሳተ ገጽ');
    await tester.enterText(_field(2), 'ገጹ የሌላ መዝሙር ነው ብዬ አስባለሁ።');
    await send(tester);

    expect(find.text('ተልኳል'), findsOneWidget);
    expect(repository.sent.single.title, 'የተሳሳተ ገጽ');
    expect(repository.sent.single.screen, 'settings');
    expect(tester.widget<TextFormField>(_field(0)).controller?.text ?? '',
        isEmpty);
  });
}

/// A report inbox that accepts everything, as the server does when online.
class _AcceptingRepository implements BugReportRepository {
  final List<BugReportPayload> sent = [];

  @override
  Future<BugReportSubmissionResult> submit(BugReportPayload payload) async {
    sent.add(payload);
    return const BugReportSubmissionResult(
      submitted: true,
      queued: false,
      message: 'ተልኳል',
    );
  }
}
