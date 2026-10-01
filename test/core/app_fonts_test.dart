import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/theme/app_fonts.dart';
import 'package:amharic_hymnal_app/core/theme/app_palette.dart';
import 'package:amharic_hymnal_app/core/theme/app_theme.dart';

/// Amharic is set in Noto Sans Ethiopic and English in Noto Serif, and the
/// choice is made in one place. These check the files are really there, that
/// the weights are real rather than smeared by the engine, and that text
/// lands in the face it should.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final pubspec = File('pubspec.yaml').readAsStringSync();

  group('the font files the app declares', () {
    test('every declared asset exists', () {
      final assets = RegExp(r'asset: (assets/fonts/[^\s]+\.ttf)')
          .allMatches(pubspec)
          .map((m) => m.group(1)!)
          .toList();

      expect(assets, isNotEmpty, reason: 'no fonts declared at all');
      for (final asset in assets) {
        expect(File(asset).existsSync(), isTrue, reason: 'missing $asset');
      }
    });

    /// A family with one file does not get lighter or heavier cuts, it gets
    /// a Regular the engine smears to fake them. That fake is what made the
    /// Ethiopic script look blurred.
    test('both families ship a real 400, 600 and 700', () {
      for (final family in [AppFonts.ethiopic, AppFonts.serif]) {
        for (final weight in [400, 600, 700]) {
          expect(
            pubspec,
            contains(RegExp('$family-\\w+\\.ttf\\s+weight: $weight')),
            reason: '$family is missing a declared weight $weight',
          );
        }
      }
    });
  });

  group('which face text is set in', () {
    /// The resolved style, as the engine will actually draw it, rather than
    /// what the widget was handed.
    String? familyOf(WidgetTester tester, String text) => tester
        .renderObject<RenderParagraph>(find.text(text))
        .text
        .style
        ?.fontFamily;

    FontWeight? weightOf(WidgetTester tester, String text) => tester
        .renderObject<RenderParagraph>(find.text(text))
        .text
        .style
        ?.fontWeight;

    Future<void> pumpIn(WidgetTester tester, Locale locale) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forPalette(
            AppPalette.emerald,
            Brightness.dark,
            uiLocale: locale,
          ),
          home: const Scaffold(
            body: Column(
              children: [
                Text('Settings'),
                Text('ቅንብሮች'),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('the interface is serif when the app is read in English',
        (tester) async {
      await pumpIn(tester, const Locale('en'));
      expect(familyOf(tester, 'Settings'), AppFonts.serif);
    });

    testWidgets('and Ethiopic when it is read in Amharic', (tester) async {
      await pumpIn(tester, const Locale('am'));
      expect(familyOf(tester, 'ቅንብሮች'), AppFonts.ethiopic);
    });

    /// Noto Serif carries no Ethiopic at all, so an Amharic word inside an
    /// English interface would be a row of empty boxes without this.
    testWidgets(
        'Amharic inside an English interface has a face to fall back'
        ' to', (tester) async {
      await pumpIn(tester, const Locale('en'));
      final style =
          tester.renderObject<RenderParagraph>(find.text('ቅንብሮች')).text.style;
      expect(style?.fontFamily, AppFonts.serif);
      expect(style?.fontFamilyFallback, contains(AppFonts.ethiopic));
    });

    testWidgets('ordinary text is semibold, not a smeared regular',
        (tester) async {
      await pumpIn(tester, const Locale('am'));
      expect(weightOf(tester, 'ቅንብሮች'), FontWeight.w600);
    });

    /// The hymns are Amharic whichever language the interface is in.
    test('the hymn words name the Ethiopic face themselves', () {
      final style = AppTheme.lyricsTextStyle(
        color: const Color(0xFFFFFFFF),
        fontSize: 20,
      );
      expect(style.fontFamily, AppFonts.ethiopic);
      expect(style.fontFamilyFallback, contains(AppFonts.serif));
      expect(style.fontWeight, FontWeight.w600);
    });
  });

  /// The face is chosen by the theme, from the app's language. A screen that
  /// names a font itself opts out of that and stays in the wrong one.
  test('no screen names a font family of its own', () {
    final allowed = {
      'lib/core/theme/app_fonts.dart',
      'lib/core/theme/app_theme.dart',
      // The two places an English hymn title is set, which is deliberate:
      // it is the hymn's name, not part of the interface.
      'lib/features/hymns/presentation/widgets/hymn_list_item.dart',
      'lib/features/hymns/presentation/widgets/music_player_widget.dart',
    };
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (allowed.contains(path)) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('fontFamily')) {
          offenders.add('$path:${i + 1}');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'the theme decides the face, from the app language. '
            'Found at: ${offenders.join(', ')}');
  });
}
