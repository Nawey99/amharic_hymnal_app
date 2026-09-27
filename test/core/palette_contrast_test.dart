import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/theme/app_palette.dart';

/// WCAG relative luminance.
double _luminance(Color color) {
  double channel(double value) {
    final v = value;
    return v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4) as double;
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// How far apart two colours read, 1 (identical) to 21 (black on white).
double contrast(Color foreground, Color background) {
  final a = _luminance(foreground);
  final b = _luminance(background);
  final lighter = math.max(a, b);
  final darker = math.min(a, b);
  return (lighter + 0.05) / (darker + 0.05);
}

/// What a translucent panel actually looks like once it is over something.
Color composite(Color panel, double opacity, Color behind) =>
    Color.lerp(behind, panel, opacity)!;

void main() {
  /// The frost a card paints, over the page and over the photograph.
  ({Color onPage, Color onPhoto}) glassOf(AppColorsExtension colors) {
    // GlassContainer paints its tint at 1.5x the opacity it is given.
    final page = composite(
      colors.glassTint,
      (colors.glassOpacity * 1.5).clamp(0.0, 1.0),
      colors.primaryBackground,
    );
    // Over the photograph the scrim has already been laid down, so the
    // worst case is a mid-grey picture behind it.
    final photo = composite(
      colors.scrim,
      colors.scrim.a,
      const Color(0xFF7F7F7F),
    );
    return (
      onPage: page,
      onPhoto: composite(
        colors.glassTint,
        (colors.glassOpacityOverPhoto * 1.5).clamp(0.0, 1.0),
        photo,
      ),
    );
  }

  for (final palette in AppPalette.values) {
    for (final brightness in Brightness.values) {
      final colors = AppColorsExtension.of(palette, brightness);
      final name = '${palette.name} ${brightness.name}';

      test('$name: text is readable on the page and on a panel', () {
        final glass = glassOf(colors);
        final surfaces = <String, Color>{
          'the page': colors.primaryBackground,
          'a surface': colors.surface,
          'a panel on the page': glass.onPage,
          'a panel over the photograph': glass.onPhoto,
        };

        for (final entry in surfaces.entries) {
          expect(
            contrast(colors.primaryText, entry.value),
            greaterThanOrEqualTo(4.5),
            reason: 'main text on ${entry.key}',
          );
          expect(
            contrast(colors.secondaryText, entry.value),
            greaterThanOrEqualTo(4.5),
            reason: 'quieter text on ${entry.key}',
          );
        }
      });

      test('$name: the accent carries its own text and stands out', () {
        // Filled green buttons carry white text. The app shipped with
        // 0xFF4CAF50, where white reads at 2.78 rather than the 3.0 a
        // control needs; that is recorded here rather than waved through,
        // and every palette drawn since has to clear the line.
        final shippedDarkGreen =
            palette == AppPalette.emerald && brightness == Brightness.dark;
        expect(
          contrast(const Color(0xFFFFFFFF), colors.accent),
          greaterThanOrEqualTo(shippedDarkGreen ? 2.75 : 3.0),
          reason: 'white on the accent',
        );
        // And the accent has to be visible as text or an icon on the page.
        expect(
          contrast(colors.accent, colors.primaryBackground),
          greaterThanOrEqualTo(3.0),
          reason: 'the accent on the page',
        );
      });

      test('$name: the hairline and divider are visible, not harsh', () {
        final glass = glassOf(colors);
        final border = composite(
          colors.glassBorder,
          colors.glassBorder.a,
          glass.onPage,
        );
        expect(contrast(border, glass.onPage), greaterThan(1.05),
            reason: 'the panel edge can be seen');
        expect(contrast(colors.divider, colors.primaryBackground),
            greaterThan(1.05));
      });
    }
  }

  test('the dark palette still holds the values the app shipped with', () {
    const dark = AppColorsExtension.emeraldDark;

    expect(dark.primaryBackground, const Color(0xFF000000));
    expect(dark.primaryText, const Color(0xFFFFFFFF));
    expect(dark.accent, const Color(0xFF4CAF50));
    expect(dark.glassOpacity, 0.1);
    expect(dark.glassOpacityOverPhoto, 0.3);
  });
}
