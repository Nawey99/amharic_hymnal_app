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
  // verbatim: the opening of the first hymn, shown as the book sets it
  static const _sample = 'አምላካችን አመስግኑ';

  /// Room above and below the line.
  static const double _padding = 8;

  /// The shortest the box is allowed to be.
  ///
  /// At the smallest setting the line is barely 23 points tall, and a box
  /// that shrank to fit it would read as a scrap rather than a sample.
  static const double _minimumHeight = 44;

  /// How tall the box is for a line set at [fontSize].
  ///
  /// It follows the words. This used to be fixed at the height of the
  /// largest setting, on the grounds that a growing box would carry the
  /// slider out from under the reader's finger -- which it cannot: the
  /// box is laid out below the slider, so its height was measured and
  /// found to move the slider by zero. What the fixed height did instead
  /// was leave 45 points of nothing under a 12 point line.
  static double heightFor({required double fontSize}) {
    final line = fontSize * AppTheme.getLineHeight(fontSize);
    final wanted = line + _padding * 2;
    return wanted < _minimumHeight ? _minimumHeight : wanted;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      height: heightFor(fontSize: fontSize),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: _padding),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.glassBorder),
      ),
      child: ClipRect(
        child: Align(
          // Whatever room is left over is shared above and below, rather
          // than pooling underneath a line pinned to the top.
          alignment: Alignment.centerLeft,
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
