// Host side of integration_test/perf/performance_test.dart: writes the frame
// timeline summary and the measured timings to build/perf/, and fails the
// run if index scrolling misses the frame budget.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() {
  return integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) return;
      final timeline = driver.Timeline.fromJson(
        data['index_scroll_timeline'] as Map<String, dynamic>,
      );
      final summary = driver.TimelineSummary.summarize(timeline);
      await summary.writeTimelineToFile(
        'index_scroll',
        destinationDirectory: 'build/perf',
        pretty: true,
      );

      final json = summary.summaryJson;
      final timings = {
        'startup_to_index_ms': data['startup_to_index_ms'],
        'search_ms': data['search_ms'],
        'search_engine_avg_ms': data['search_engine_avg_ms'],
        'hymns_in_book': data['hymns_in_book'],
        'index_scroll_90th_percentile_frame_build_ms':
            json['90th_percentile_frame_build_time_millis'],
        'index_scroll_missed_frame_build_budget':
            json['missed_frame_build_budget_count'],
      };
      await File('build/perf/timings.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(timings),
      );
      stdout.writeln(timings);

      final p90 =
          (json['90th_percentile_frame_build_time_millis'] as num?) ?? 0;
      if (p90 > 16) {
        stderr.writeln('Index scrolling: 90th percentile frame build '
            '${p90.toStringAsFixed(1)} ms exceeds the 16 ms budget.');
        exitCode = 1;
      }
    },
  );
}
