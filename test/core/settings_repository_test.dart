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
      expect(repository.getFavoriteHymns(), isEmpty);
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

    test('is clamped to 12..30 when saved', () async {
      await repository.setFontSize(99);
      expect(repository.getFontSize(), 30);
      await repository.setFontSize(1);
      expect(repository.getFontSize(), 12);
    });

    test('an out-of-range saved value is repaired on start', () async {
      await start({AppConstants.keyFontSize: 55.0});

      expect(repository.getFontSize(), 30);
      final saved = await SharedPreferences.getInstance();
      expect(saved.getDouble(AppConstants.keyFontSize), 30);
    });
  });

  group('favorites', () {
    setUp(() => start());

    test('toggle on and off in the selected book', () async {
      await repository.setSelectedVersion(HymnalVersions.sdaNew);

      await repository.toggleFavorite(12);
      expect(repository.isFavorite(12), isTrue);
      expect(repository.getFavoriteHymns(), [12]);

      await repository.toggleFavorite(12);
      expect(repository.isFavorite(12), isFalse);
      expect(repository.getFavoriteHymns(), isEmpty);
    });

    test('are kept separately for each book', () async {
      await repository.setSelectedVersion(HymnalVersions.sdaNew);
      await repository.toggleFavorite(5);
      await repository.setSelectedVersion(HymnalVersions.hagerigna);
      await repository.toggleFavorite(7);

      expect(repository.getFavoriteHymns(), [7]);
      expect(repository.isFavorite(5), isFalse);
      expect(repository.isFavorite(5, version: HymnalVersions.sdaNew), isTrue);

      await repository.setSelectedVersion(HymnalVersions.sdaNew);
      expect(repository.getFavoriteHymns(), [5]);
    });

    test('can be toggled for a book other than the selected one', () async {
      await repository.setSelectedVersion(HymnalVersions.sdaNew);
      await repository.toggleFavorite(9, version: HymnalVersions.sdaOld);

      expect(repository.isFavorite(9), isFalse);
      expect(repository.isFavorite(9, version: HymnalVersions.sdaOld), isTrue);
      expect(repository.getFavoriteHymnKeys(), contains('sda_old:9'));
    });

    test('survive a restart', () async {
      await repository.toggleFavorite(3);
      await restart();
      expect(repository.isFavorite(3), isTrue);
    });

    test('setting the list replaces only the selected book', () async {
      await repository.setSelectedVersion(HymnalVersions.hagerigna);
      await repository.toggleFavorite(1);
      await repository.setSelectedVersion(HymnalVersions.sdaNew);

      await repository.setFavoriteHymns([2, 4]);

      expect(repository.getFavoriteHymns()..sort(), [2, 4]);
      expect(
          repository.isFavorite(1, version: HymnalVersions.hagerigna), isTrue);
    });
  });
}
