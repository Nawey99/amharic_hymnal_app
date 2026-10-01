import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('favorites are stored per hymnal version', () async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();

    await SettingsService.setSelectedVersion(HymnalVersions.sdaNew);
    await SettingsService.toggleFavorite(1);

    await SettingsService.setSelectedVersion(HymnalVersions.sdaOld);
    expect(SettingsService.isFavorite(1), isFalse);
    await SettingsService.toggleFavorite(1);

    expect(SettingsService.getFavoriteHymnKeys(), contains('sda_new:1'));
    expect(SettingsService.getFavoriteHymnKeys(), contains('sda_old:1'));
  });

  test('legacy favorites migrate into selected version', () async {
    SharedPreferences.setMockInitialValues({
      'favorite_hymns': ['7'],
      'selected_version': HymnalVersions.sdaNew,
    });
    await SettingsService.init();

    expect(SettingsService.getFavoriteHymns(), [7]);
    expect(SettingsService.getFavoriteHymnKeys(), contains('sda_new:7'));
  });

  test('a favourite in one book never appears in a book with none', () async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
    await SettingsService.setSelectedVersion(HymnalVersions.sdaNew);
    await SettingsService.toggleFavorite(1);

    await SettingsService.setSelectedVersion(HymnalVersions.sdaOld);

    expect(SettingsService.getFavoriteHymns(), isEmpty);
    expect(SettingsService.isFavorite(1), isFalse);
  });

  test('old-format favourites survive a toggle before they are read', () async {
    SharedPreferences.setMockInitialValues({
      'favorite_hymns': ['7'],
      'selected_version': HymnalVersions.sdaNew,
    });
    await SettingsService.init();

    await SettingsService.toggleFavorite(9);

    expect(SettingsService.getFavoriteHymns(), unorderedEquals([7, 9]));
  });
}
