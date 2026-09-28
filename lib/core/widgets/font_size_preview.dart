import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/theme/app_theme.dart';

/// A line of a hymn, set exactly as the hymn page would set it.
class FontSizePreview extends StatelessWidget {
  /// The size being chosen, live while the slider moves.
  final double fontSize;

  const FontSizePreview({super.key, required this.fontSize});

  /// The opening of the first hymn: words a reader will recognise, so the
  /// sample reads as the book rather than as filler.
  static const _sample = 'አምላካችን አመስግኑ';

  /// Tall enough for the largest setting, so the box does not grow as the
  /// slider moves and carry the slider out from under the reader's finger.
  static double heightFor({required double maxFontSize}) {
    return maxFontSize * AppTheme.getLineHeight(maxFontSize) + 20;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      height: heightFor(maxFontSize: 30),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.glassBorder),
      ),
      child: ClipRect(
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            _sample,
            // The chosen size is absolute, as it is on the hymn page: it
            // was seeded from the phone's text size and must not be
            // scaled by it twice.
            textScaler: TextScaler.noScaling,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: AppTheme.lyricsTextStyle(
              color: colors.primaryText,
              fontSize: fontSize,
            ),
          ),
        ),
      ),
    );
  }
}
