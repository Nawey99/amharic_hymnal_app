import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/utils/constants.dart';
import 'package:amharic_hymnal_app/core/services/settings_service.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';

void main() {
  test('keep screen on setting persists through SettingsService', () async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();

    expect(SettingsService.getKeepScreenOn(), isFalse);
    expect(await SettingsService.setKeepScreenOn(true), isTrue);
    expect(SettingsService.getKeepScreenOn(), isTrue);
    expect(await SettingsService.setKeepScreenOn(false), isTrue);
    expect(SettingsService.getKeepScreenOn(), isFalse);
  });

  group('the hymn text size on a fresh install', () {
    test('starts from the text size set on the phone', () async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.init(systemTextScale: 1.3);

      expect(SettingsService.getFontSize(), closeTo(26, 0.01));
    });

    test('follows a smaller phone text size too', () async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.init(systemTextScale: 0.85);

      expect(SettingsService.getFontSize(), closeTo(17, 0.01));
    });

    test('stays within the range the slider offers', () async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.init(systemTextScale: 2.5);
      expect(SettingsService.getFontSize(), AppConstants.maxFontSize);

      SharedPreferences.setMockInitialValues({});
      await SettingsService.init(systemTextScale: 0.1);
      expect(SettingsService.getFontSize(), AppConstants.minFontSize);
    });

    test('a reader who has chosen a size keeps it', () async {
      SharedPreferences.setMockInitialValues({'font_size': 15.0});
      await SettingsService.init(systemTextScale: 1.6);

      expect(SettingsService.getFontSize(), 15);
    });
  });

  group('favourites are kept by song ID', () {
    test('the same number in two books is two favourites', () async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.init();

      await SettingsService.toggleFavoriteSong('am-sda-2004-0001');
      expect(SettingsService.isFavoriteSong('am-sda-1975-0001'), isFalse);
      await SettingsService.toggleFavoriteSong('am-sda-1975-0001');

      expect(SettingsService.getFavoriteSongIds(),
          ['am-sda-1975-0001', 'am-sda-2004-0001']);
    });

    test('toggling twice removes it', () async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.init();

      await SettingsService.toggleFavoriteSong('am-sda-2004-0132');
      await SettingsService.toggleFavoriteSong('am-sda-2004-0132');

      expect(SettingsService.getFavoriteSongIds(), isEmpty);
    });

    test('per-book favourites from an older version become song IDs', () async {
      SharedPreferences.setMockInitialValues({
        'favorite_hymns_by_version': [
          'sda_new:132',
          'sda_old:7',
          'sda_1960:165',
          'hagerigna:12',
          'not a key',
        ],
      });
      await SettingsService.init();

      expect(SettingsService.getFavoriteSongIds(), [
        'am-hagerigna-0012',
        'am-sda-1961-0165',
        'am-sda-1975-0007',
        'am-sda-2004-0132',
      ]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('favorite_hymns_by_version'), isNull);
    });

    test('the oldest number-only list moves into the selected book', () async {
      SharedPreferences.setMockInitialValues({
        'favorite_hymns': ['7', '9'],
        'selected_version': HymnalVersions.sdaOld,
      });
      await SettingsService.init();

      expect(SettingsService.getFavoriteSongIds(),
          ['am-sda-1975-0007', 'am-sda-1975-0009']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('favorite_hymns'), isNull);
    });

    test('migrating twice changes nothing', () async {
      SharedPreferences.setMockInitialValues({
        'favorite_hymns_by_version': ['sda_new:5'],
      });
      await SettingsService.init();
      await SettingsService.init();

      expect(SettingsService.getFavoriteSongIds(), ['am-sda-2004-0005']);
    });

    test('favourites already kept by ID are merged, not replaced', () async {
      SharedPreferences.setMockInitialValues({
        'favorite_song_ids': ['am-sda-2004-0001'],
        'favorite_hymns_by_version': ['sda_new:2'],
      });
      await SettingsService.init();

      expect(SettingsService.getFavoriteSongIds(),
          ['am-sda-2004-0001', 'am-sda-2004-0002']);
    });
  });

  test('unfinished downloads are remembered until they end', () async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();

    await SettingsService.setDownloadUnfinished('sda_new', 'audio', true);
    await SettingsService.setDownloadUnfinished('sda_old', 'sheet_music', true);
    expect(SettingsService.getUnfinishedDownloads(),
        [('sda_new', 'audio'), ('sda_old', 'sheet_music')]);

    await SettingsService.setDownloadUnfinished('sda_new', 'audio', false);
    expect(
        SettingsService.getUnfinishedDownloads(), [('sda_old', 'sheet_music')]);
  });
}
