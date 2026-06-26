import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/services/history_service.dart';

void main() {
  test('history stores version-aware entries and moves duplicates to top',
      () async {
    HistoryService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await HistoryService.init();

    await HistoryService.addToHistory(1, version: HymnalVersions.sdaNew);
    await HistoryService.addToHistory(1, version: HymnalVersions.sdaOld);
    await HistoryService.addToHistory(2, version: HymnalVersions.sdaNew);
    await HistoryService.addToHistory(1, version: HymnalVersions.sdaNew);

    final entries = HistoryService.getHistoryEntries();

    expect(entries.map((entry) => entry.storageValue), [
      '${HymnalVersions.sdaNew}:1',
      '${HymnalVersions.sdaNew}:2',
      '${HymnalVersions.sdaOld}:1',
    ]);
  });

  test('legacy number-only history is read as new SDA hymnal', () async {
    HistoryService.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'hymn_history': ['7'],
    });
    await HistoryService.init();

    final entries = HistoryService.getHistoryEntries();

    expect(entries.single.version, HymnalVersions.sdaNew);
    expect(entries.single.hymnNumber, 7);
  });
}
