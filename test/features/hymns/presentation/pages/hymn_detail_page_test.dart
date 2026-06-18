// test/features/hymns/presentation/pages/hymn_detail_page_test.dart
// Note: This test file requires mock generation. Run:
// flutter pub run build_runner build
// to generate mocks before running tests.

import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/core/services/font_size_service.dart';
import 'package:amharic_hymnal_app/core/utils/constants.dart';

void main() {
  group('HymnDetailPage Widget Tests', () {
    late Hymn testHymn;

    setUp(() {
      // Initialize FontSizeService for tests
      FontSizeService().initialize(AppConstants.defaultFontSize);

      // Create a test hymn
      testHymn = const Hymn(
        id: 'sda-1',
        number: 1,
        title: 'Test Hymn Title',
        newHymnalTitle: 'Test Hymn Title',
        newHymnalLyrics:
            'Test lyrics line 1\nTest lyrics line 2\nTest lyrics line 3',
        isFavorite: false,
      );
    });

    // Note: Full widget tests require proper BLoC mocking
    // See test/widget_tests/favorite_toggle_test.dart for working example
    // To enable these tests, generate mocks with:
    // flutter pub run build_runner build

    testWidgets('Hymn entity creation works', (WidgetTester tester) async {
      expect(testHymn.displayTitle, 'Test Hymn Title');
      expect(testHymn.displayNumber, 1);
      expect(testHymn.displayLyrics, contains('Test lyrics'));
    });

    testWidgets('Font size service initialization works',
        (WidgetTester tester) async {
      final fontSizeService = FontSizeService();
      fontSizeService.initialize(20.0);
      expect(fontSizeService.getFontSize(), 20.0);
    });
  });
}
