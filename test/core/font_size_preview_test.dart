import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/theme/app_theme.dart';
import 'package:amharic_hymnal_app/core/widgets/font_size_preview.dart';
import 'package:amharic_hymnal_app/core/widgets/settings_tiles.dart';

/// The sample under the slider is only worth having if it is the truth:
/// what it shows has to be what the hymn page will show.
void main() {
  Future<void> pumpPreview(WidgetTester tester, double size) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: FontSizePreview(fontSize: size),
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

  /// The box used to be fixed at the height of the largest setting, which
  /// left forty-five points of nothing under a twelve point line. The
  /// reason given was that a growing box would carry the slider out from
  /// under the dragging finger; the last test here shows it does not.
  testWidgets('the box follows the words', (tester) async {
    await pumpPreview(tester, 12);
    final small = tester.getSize(find.byType(FontSizePreview));
    await pumpPreview(tester, 40);
    final large = tester.getSize(find.byType(FontSizePreview));

    expect(large.height, greaterThan(small.height),
        reason: 'a bigger choice should look bigger');
    // Not so tight that the smallest setting reads as a scrap.
    expect(small.height, greaterThanOrEqualTo(44));
  });

  testWidgets('the line sits in the middle, not against the top',
      (tester) async {
    await pumpPreview(tester, 12);

    final box = tester.getRect(find.byType(FontSizePreview));
    final line = tester.getRect(find.text('አምላካችን አመስግኑ'));
    final above = line.top - box.top;
    final below = box.bottom - line.bottom;

    expect(above, closeTo(below, 1.0),
        reason: 'the room left over is shared, not pooled underneath');
  });

  testWidgets('one line of the hymn, whichever way the phone is held',
      (tester) async {
    await pumpPreview(tester, 20);
    expect(tester.widget<Text>(find.byType(Text).first).maxLines, 1);
    expect(find.text('አምላካችን አመስግኑ'), findsOneWidget);
  });

  /// What the fixed height was really there to protect, tested directly.
  testWidgets('growing the box does not move the slider', (tester) async {
    Future<double> sliderYAt(double size) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SettingsSliderTile(
              title: 'Font Size',
              value: size,
              min: 12,
              max: 40,
              divisions: 28,
              highlight: size.toStringAsFixed(0),
              previewBuilder: (context, value) =>
                  FontSizePreview(fontSize: value),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getTopLeft(find.byType(Slider)).dy;
    }

    // The preview is laid out below the slider, so nothing it does can
    // reach back up and move it.
    expect(await sliderYAt(12), await sliderYAt(40));
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
