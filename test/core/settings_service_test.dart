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
}
