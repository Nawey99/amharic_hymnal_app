// Performance on a real phone, in profile mode:
//
//   flutter drive --profile \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/perf/performance_test.dart
//
// Budgets (docs/test-plan.md, Layer H) are checked here; the frame timeline
// summaries are written to build/perf/ by the driver for comparison between
// releases. Uses the live hymnal API, so the phone needs a connection for the
// first run (later runs use the stored copy).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:amharic_hymnal_app/core/services/search_engine.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/index_page.dart';
import 'package:amharic_hymnal_app/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('start-up, index scrolling and search stay within budget',
      (tester) async {
    final startup = Stopwatch()..start();
    app.main();
    // Wait for onboarding or the main screen in short steps (pumpAndSettle's
    // argument is the step length, not a timeout).
    final ready = find.byWidgetPredicate(
      (widget) =>
          widget is Text && (widget.data == 'ዝለል' || widget.data == 'ቁጥር'),
    );
    for (var i = 0; i < 300 && ready.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    if (find.text('ዝለል').evaluate().isNotEmpty) {
      await tester.tap(find.text('ዝለል'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('ማውጫ').last);
    await tester.pumpAndSettle();
    expect(find.byType(IndexPage), findsOneWidget);
    startup.stop();
    binding.reportData = {'startup_to_index_ms': startup.elapsedMilliseconds};

    // Index scrolling: fling through the whole book.
    final list = find.byType(Scrollable).first;
    await binding.traceAction(
      () async {
        for (var i = 0; i < 6; i++) {
          await tester.fling(list, const Offset(0, -1500), 4000);
          await tester.pumpAndSettle();
        }
        for (var i = 0; i < 6; i++) {
          await tester.fling(list, const Offset(0, 1500), 4000);
          await tester.pumpAndSettle();
        }
      },
      reportKey: 'index_scroll_timeline',
    );

    // Search engine alone, on this phone, over the loaded book.
    final state = tester.element(find.byType(IndexPage)).read<HymnsBloc>().state
        as HymnsLoaded;
    final engine = SearchEngine();
    const queries = ['ኢየሱስ', 'ፍቅር', 'ምስጋና', '12', 'ጌታ'];
    final engineWatch = Stopwatch()..start();
    for (var round = 0; round < 4; round++) {
      for (final query in queries) {
        engine.search(hymns: state.hymns, query: query);
      }
    }
    engineWatch.stop();
    final engineMs = engineWatch.elapsedMilliseconds / (4 * queries.length);

    // Search as a person sees it: typing to settled results (includes the
    // 350 ms typing debounce and the list animation).
    await tester.tap(find.byIcon(Icons.search).first);
    await tester.pumpAndSettle();
    final search = Stopwatch()..start();
    await tester.enterText(find.byType(TextField).first, 'ኢየሱስ');
    await tester.pumpAndSettle();
    search.stop();

    binding.reportData!
      ..['search_ms'] = search.elapsedMilliseconds
      ..['search_engine_avg_ms'] = engineMs
      ..['hymns_in_book'] = state.hymns.length;

    expect(engineMs, lessThan(50),
        reason: 'search over a full book should take under 50 ms');
    expect(search.elapsedMilliseconds, lessThan(350 + 500),
        reason: 'results should settle within 500 ms after the debounce');
    expect(startup.elapsedMilliseconds, lessThan(10000),
        reason: 'first launch (including download) should stay under 10 s');
  });
}
