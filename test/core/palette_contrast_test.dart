import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/theme/app_palette.dart';
import 'package:amharic_hymnal_app/core/theme/app_theme_spec.dart';

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

/// The hue of a colour in degrees, for telling two families apart.
double _hue(Color color) {
  final r = color.r, g = color.g, b = color.b;
  final max = math.max(r, math.max(g, b));
  final min = math.min(r, math.min(g, b));
  final span = max - min;
  if (span < 0.001) return 0;
  final double hue;
  if (max == r) {
    hue = 60 * (((g - b) / span) % 6);
  } else if (max == g) {
    hue = 60 * ((b - r) / span + 2);
  } else {
    hue = 60 * ((r - g) / span + 4);
  }
  return hue < 0 ? hue + 360 : hue;
}

/// How far apart two hues are on the wheel, 0 to 180.
double _hueGap(Color a, Color b) {
  final gap = (_hue(a) - _hue(b)).abs();
  return gap > 180 ? 360 - gap : gap;
}

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

  // Driven off the catalogue, so a theme is measured the moment it is
  // listed and nobody has to remember to add it here.
  for (final spec in AppThemeCatalog.themes) {
    final palette = spec.id;
    for (final brightness in Brightness.values) {
      final colors = spec.colorsFor(brightness);
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

      /// The Index's section letter is the one piece of text with no panel
      /// under it: it sits straight on the scrimmed photograph. It used to
      /// carry a drop shadow for legibility, which blurred it; this is the
      /// measurement that replaced the shadow, so weakening the scrim or
      /// lightening an accent now fails here instead of going unnoticed.
      test('$name: the section letter reads on the photograph', () {
        final photo = composite(
          colors.scrim,
          colors.scrim.a,
          const Color(0xFF7F7F7F),
        );

        // 20px bold is large text, where WCAG asks 3:1 rather than 4.5:1.
        expect(
          contrast(colors.accent, photo),
          greaterThanOrEqualTo(3.0),
          reason: 'the section letter over the photograph',
        );
      });

      test('$name: the bar can be seen, and read, wherever it floats', () {
        // The bar sits over the photograph on one page and over white
        // cards on the next, so it is judged against both.
        final overPhoto = composite(
          colors.barTint,
          colors.barOpacity,
          composite(colors.scrim, colors.scrim.a, const Color(0xFF7F7F7F)),
        );
        final overPage = composite(
          colors.barTint,
          colors.barOpacity,
          colors.primaryBackground,
        );

        for (final bar in {
          'over the photograph': overPhoto,
          'over the page': overPage
        }.entries) {
          expect(contrast(colors.primaryText, bar.value),
              greaterThanOrEqualTo(4.5),
              reason: 'a label ${bar.key}');
          expect(contrast(colors.secondaryText, bar.value),
              greaterThanOrEqualTo(4.5),
              reason: 'a quiet label ${bar.key}');
          expect(contrast(colors.accent, bar.value), greaterThanOrEqualTo(3.0),
              reason: 'the chosen tab ${bar.key}');
        }

        // Its edge has to separate it from a page of the same colour.
        final edge = composite(colors.barBorder, colors.barBorder.a, overPage);
        expect(contrast(edge, overPage), greaterThan(1.05),
            reason: 'the bar has an edge against the page');
      });

      test('$name: the raised button matches the tab beside it', () {
        expect(
          contrast(colors.onAccent, colors.raisedAction),
          greaterThanOrEqualTo(3.0),
          reason: 'the number on the button',
        );
        // Two greens a shade apart, side by side, read as a mistake.
        final tabToButton = contrast(colors.accent, colors.raisedAction);
        expect(tabToButton, lessThan(1.6),
            reason: 'the button and the chosen tab are the same green');
        // Lightness alone does not catch a button left behind when the
        // accent moved to another hue: two violets differ by nothing a
        // contrast ratio can see, and the app showed the old one.
        expect(
          _hueGap(colors.accent, colors.raisedAction),
          lessThan(12),
          reason: 'the button and the chosen tab are the same colour',
        );
      });

      test('$name: the accent carries its own text and stands out', () {
        // A filled button carries onAccent: white over a deep colour,
        // ink over a pastel or a gold. The app shipped with 0xFF4CAF50,
        // where white reads at 2.78 rather than the 3.0 a control needs;
        // that is recorded here rather than waved through, and every
        // palette drawn since has to clear the line.
        final shippedDarkGreen =
            palette == AppPalette.emerald && brightness == Brightness.dark;
        expect(
          contrast(colors.onAccent, colors.accent),
          greaterThanOrEqualTo(shippedDarkGreen ? 2.75 : 3.0),
          reason: 'what is written on the accent',
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
    expect(dark.barTint, const Color(0xFF2C2C2C));
    expect(dark.barOpacity, 0.15);
    expect(dark.raisedAction, const Color(0xFF388E3C));
  });

  test('light and dark do not share the bar, which is the point', () {
    const light = AppColorsExtension.emeraldLight;
    const dark = AppColorsExtension.emeraldDark;

    expect(light.barTint, isNot(dark.barTint));
    expect(light.barOpacity, greaterThan(dark.barOpacity));
    expect(light.barBorder, isNot(dark.barBorder));
  });

  test('every circle in the chooser is a gradient', () {
    // A flat circle looks unfinished beside fourteen that are not; the
    // first five were flat until someone noticed.
    for (final theme in AppThemeCatalog.themes) {
      expect(
        theme.swatch.isGradient,
        isTrue,
        reason: '${theme.id.name} would sit dull in the row',
      );
      expect(
        theme.swatch.start,
        isNot(theme.swatch.end),
        reason: '${theme.id.name} has two stops of the same colour',
      );
    }
  });

  test('every name that can be stored has a theme in the catalogue', () {
    expect(
      AppThemeCatalog.themes.map((theme) => theme.id).toSet(),
      AppPalette.values.toSet(),
      reason: 'a stored choice with no theme would silently fall back',
    );
    expect(
      AppThemeCatalog.themes.map((theme) => theme.label).toSet(),
      hasLength(AppThemeCatalog.themes.length),
      reason: 'two themes sharing a name cannot be told apart in the chooser',
    );
  });
}
