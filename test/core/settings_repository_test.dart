import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/data/repositories/settings_repository_impl.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/services/settings_service.dart';
import 'package:amharic_hymnal_app/core/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = SettingsRepositoryImpl();

  Future<void> start([Map<String, Object> prefs = const {}]) async {
    SharedPreferences.setMockInitialValues(prefs);
    await SettingsService.init();
  }

  /// Simulates an app restart: a fresh read of what was saved.
  Future<void> restart() async {
    final saved = await SharedPreferences.getInstance();
    final values = {
      for (final key in saved.getKeys()) key: saved.get(key)!,
    };
    await start(values);
  }

  group('defaults on a fresh install', () {
    setUp(() => start());

    test('Amharic, the 2004 book, sorted by number', () {
      expect(repository.getSelectedLanguage(), 'am');
      expect(repository.getSelectedVersion(), HymnalVersions.sdaNew);
      expect(repository.getSortType(), 'number');
    });

    test('font 20, screen may sleep, background image on', () {
      expect(repository.getFontSize(), AppConstants.defaultFontSize);
      expect(repository.getKeepScreenOn(), isFalse);
      expect(repository.getBackgroundImageEnabled(), isTrue);
    });

    test('onboarding not yet done and no favorites', () {
      expect(repository.isOnboardingCompleted(), isFalse);
      expect(repository.getFavoriteSongIds(), isEmpty);
    });
  });

  group('choices survive a restart', () {
    setUp(() => start());

    test('language, book and sort', () async {
      await repository.setSelectedLanguage('en');
      await repository.setSelectedVersion(HymnalVersions.hagerigna);
      await repository.setSortType('title');

      await restart();

      expect(repository.getSelectedLanguage(), 'en');
      expect(repository.getSelectedVersion(), HymnalVersions.hagerigna);
      expect(repository.getSortType(), 'title');
    });

    test('onboarding completion', () async {
      await repository.setOnboardingCompleted(true);
      await restart();
      expect(repository.isOnboardingCompleted(), isTrue);
    });

    test('keep screen on and background image', () async {
      await repository.setKeepScreenOn(true);
      await repository.setBackgroundImageEnabled(false);

      await restart();

      expect(repository.getKeepScreenOn(), isTrue);
      expect(repository.getBackgroundImageEnabled(), isFalse);
    });
  });

  group('book IDs', () {
    setUp(() => start());

    test('the legacy "hymnal" ID is saved as the 2004 book', () async {
      await repository.setSelectedVersion('hymnal');
      expect(repository.getSelectedVersion(), HymnalVersions.sdaNew);
    });

    test('an older saved "hymnal" choice reads as the 2004 book', () async {
      await start({AppConstants.keySelectedVersion: 'hymnal'});
      expect(repository.getSelectedVersion(), HymnalVersions.sdaNew);
    });

    test('a book added later by the API keeps its ID', () async {
      await repository.setSelectedVersion('sda_2019');
      expect(repository.getSelectedVersion(), 'sda_2019');
    });
  });

  group('font size', () {
    setUp(() => start());

    test('is clamped to the range the slider offers, when saved', () async {
      await repository.setFontSize(99);
      expect(repository.getFontSize(), AppConstants.maxFontSize);
      await repository.setFontSize(1);
      expect(repository.getFontSize(), AppConstants.minFontSize);
    });

    test('an out-of-range saved value is repaired on start', () async {
      await start({AppConstants.keyFontSize: 99.0});

      expect(repository.getFontSize(), AppConstants.maxFontSize);
      final saved = await SharedPreferences.getInstance();
      expect(
          saved.getDouble(AppConstants.keyFontSize), AppConstants.maxFontSize);
    });
  });

  group('favorites', () {
    setUp(() => start());

    test('toggle on and off by song ID', () async {
      await repository.toggleFavoriteSong('am-sda-2004-0012');
      expect(repository.isFavoriteSong('am-sda-2004-0012'), isTrue);
      expect(repository.getFavoriteSongIds(), ['am-sda-2004-0012']);

      await repository.toggleFavoriteSong('am-sda-2004-0012');
      expect(repository.isFavoriteSong('am-sda-2004-0012'), isFalse);
      expect(repository.getFavoriteSongIds(), isEmpty);
    });

    test('the same number in two books is two songs', () async {
      await repository.toggleFavoriteSong('am-sda-2004-0005');
      await repository.toggleFavoriteSong('am-hagerigna-0007');

      expect(repository.isFavoriteSong('am-hagerigna-0005'), isFalse);
      expect(repository.getFavoriteSongIds(),
          ['am-hagerigna-0007', 'am-sda-2004-0005']);
    });

    test('do not depend on the selected book', () async {
      await repository.setSelectedVersion(HymnalVersions.sdaNew);
      await repository.toggleFavoriteSong('am-sda-1975-0009');
      await repository.setSelectedVersion(HymnalVersions.hagerigna);

      expect(repository.isFavoriteSong('am-sda-1975-0009'), isTrue);
    });

    test('survive a restart', () async {
      await repository.toggleFavoriteSong('am-sda-2004-0003');
      await restart();
      expect(repository.isFavoriteSong('am-sda-2004-0003'), isTrue);
    });

    test('setting the list replaces it, dropping anything malformed', () async {
      await repository.toggleFavoriteSong('am-sda-2004-0001');

      await repository.setFavoriteSongIds(
          ['am-sda-2004-0002', 'am-sda-2004-0004', ' not an id ']);

      expect(repository.getFavoriteSongIds(),
          ['am-sda-2004-0002', 'am-sda-2004-0004']);
    });
  });
}
