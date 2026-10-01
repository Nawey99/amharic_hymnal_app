import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/services/history_service.dart';
import 'package:amharic_hymnal_app/injection_container.dart' as di;

void main() {
  test('history is kept by song ID, most recent first, without repeats',
      () async {
    HistoryService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await HistoryService.init();

    await HistoryService.addToHistory('am-sda-2004-0001');
    await HistoryService.addToHistory('am-sda-1975-0001');
    await HistoryService.addToHistory('am-sda-2004-0002');
    await HistoryService.addToHistory('am-sda-2004-0001');

    expect(HistoryService.getHistoryEntries().map((e) => e.songId), [
      'am-sda-2004-0001',
      'am-sda-2004-0002',
      'am-sda-1975-0001',
    ]);
  });

  test('entries from older versions are read and rewritten as song IDs',
      () async {
    HistoryService.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'hymn_history': ['sda_old:130', '7', 'hagerigna:3', 'garbage key'],
    });
    await HistoryService.init();

    final ids = ['am-sda-1975-0130', 'am-sda-2004-0007', 'am-hagerigna-0003'];
    expect(HistoryService.getHistoryEntries().map((e) => e.songId), ids);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('hymn_history'), ids);
  });

  test('removing takes out only that song', () async {
    HistoryService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await HistoryService.init();
    await HistoryService.addToHistory('am-sda-2004-0001');
    await HistoryService.addToHistory('am-sda-1975-0001');

    await HistoryService.removeFromHistory('am-sda-2004-0001');

    expect(HistoryService.getHistoryEntries().map((e) => e.songId),
        ['am-sda-1975-0001']);
  });

  test('the number is read from the song ID', () {
    expect(const HistoryEntry('am-sda-2004-0132').hymnNumber, 132);
    expect(
        HymnalVersions.songId(HymnalVersions.sda1961, 5), 'am-sda-1961-0005');
  });

  // The History tab is built at start-up, before any hymn is opened. Opening
  // a hymn used to be the only thing that loaded history, so after every
  // restart the tab said there was none.
  test('start-up loads saved history before any hymn is opened', () async {
    HistoryService.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'hymn_history': ['sda_new:5', 'sda_new:12'],
    });

    await di.initDependencies();

    expect(
      HistoryService.getHistoryEntries().map((entry) => entry.hymnNumber),
      [5, 12],
    );
  });
}
