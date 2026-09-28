import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/theme/app_theme.dart';
import 'package:amharic_hymnal_app/core/widgets/font_size_preview.dart';
import 'package:amharic_hymnal_app/core/widgets/settings_tiles.dart';

/// The sample under the slider is only worth having if it is the truth:
/// what it shows has to be what the hymn page will show.
void main() {
  Future<void> pumpPreview(WidgetTester tester, double size,
      {bool compact = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: FontSizePreview(fontSize: size, compact: compact),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  TextStyle shownStyle(WidgetTester tester) =>
      tester.widget<Text>(find.byType(Text).first).style!;

  testWidgets('the sample is set exactly as the hymn page sets its words',
      (tester) async {
    for (final size in [12.0, 20.0, 30.0]) {
      await pumpPreview(tester, size);
      final style = shownStyle(tester);
      final lyrics = AppTheme.lyricsTextStyle(
        color: style.color!,
        fontSize: size,
      );

      expect(style.fontSize, size);
      expect(style.height, lyrics.height, reason: 'line height at $size');
      expect(style.letterSpacing, lyrics.letterSpacing,
          reason: 'letter spacing at $size');
      expect(style.fontFamily, 'NotoSansEthiopic');
    }
  });

  testWidgets('the chosen size is absolute, as it is on the hymn page',
      (tester) async {
    await pumpPreview(tester, 20);
    // The size was seeded from the phone's text size once; scaling it by
    // that again would show the reader something they will never see.
    expect(
      tester.widget<Text>(find.byType(Text).first).textScaler,
      TextScaler.noScaling,
    );
  });

  testWidgets('the box is the same height at every size', (tester) async {
    await pumpPreview(tester, 12);
    final small = tester.getSize(find.byType(FontSizePreview));
    await pumpPreview(tester, 30);
    final large = tester.getSize(find.byType(FontSizePreview));

    // A box that grows would carry the slider out from under the finger
    // that is dragging it.
    expect(small.height, large.height);
  });

  testWidgets('two lines standing, one lying down', (tester) async {
    await pumpPreview(tester, 20);
    expect(tester.widget<Text>(find.byType(Text).first).maxLines, 2);

    await pumpPreview(tester, 20, compact: true);
    expect(tester.widget<Text>(find.byType(Text).first).maxLines, 1);
  });

  group('the slider it sits under', () {
    Future<double?> pumpSlider(
      WidgetTester tester, {
      required void Function(double) onChanged,
    }) async {
      double? shownInPreview;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SettingsSliderTile(
              title: 'Font Size',
              value: 12,
              min: 12,
              max: 30,
              divisions: 18,
              highlight: '12',
              previewBuilder: (context, value) {
                shownInPreview = value;
                return FontSizePreview(fontSize: value);
              },
              onChanged: onChanged,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return shownInPreview;
    }

    testWidgets('follows the finger, and saves once it is lifted',
        (tester) async {
      final saved = <double>[];
      await pumpSlider(tester, onChanged: saved.add);

      final slider = find.byType(Slider);
      final start = tester.getCenter(slider);
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();

      // The sample has moved with the finger...
      expect(find.byType(FontSizePreview), findsOneWidget);
      final duringDrag =
          tester.widget<FontSizePreview>(find.byType(FontSizePreview)).fontSize;
      expect(duringDrag, greaterThan(12));
      // ...but nothing has been written yet.
      expect(saved, isEmpty);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(saved, hasLength(1), reason: 'one save for one gesture');
      expect(saved.single, duringDrag);
    });

    testWidgets('lands on whole points', (tester) async {
      final saved = <double>[];
      await pumpSlider(tester, onChanged: saved.add);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Slider)),
      );
      await gesture.moveBy(const Offset(37, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(saved.single, saved.single.roundToDouble());
    });
  });
}
