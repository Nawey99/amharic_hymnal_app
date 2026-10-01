// lib/features/hymns/presentation/widgets/hymn_list_item.dart
import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/theme/app_fonts.dart';
import 'package:amharic_hymnal_app/core/widgets/app_text_scope.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/core/utils/responsive_layout.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

class HymnListItem extends StatelessWidget {
  final Hymn hymn;
  final VoidCallback onTap;
  final String? sortType; // Optional sort type to adjust height

  const HymnListItem({
    super.key,
    required this.hymn,
    required this.onTap,
    this.sortType,
  });

  /// The space every item leaves below itself, before the next one. A list
  /// takes it off its end padding so the last item stops where a list with
  /// separators would.
  static double bottomGap(BuildContext context) =>
      ResponsiveLayout.isCompactLandscape(context) ? 6 : 10;

  @override
  Widget build(BuildContext context) {
    final fontSize = FontSizeScope.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final backgroundImageEnabled = BackgroundImageService().isEnabled;
    final compactLandscape = ResponsiveLayout.isCompactLandscape(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: GlassContainer(
          margin: EdgeInsets.only(bottom: bottomGap(context)),
          borderRadius: 12.0,
          // One blur per row is one layer per row, on every frame of a
          // scroll. The frost behind a panel this opaque was never
          // visible anyway.
          blur: false,
          opacity: backgroundImageEnabled ? 0.22 : 0.62,
          color: context.appColors.surface,
          border: Border.all(
            color: backgroundImageEnabled
                ? context.appColors.veil.withValues(alpha: 0.3)
                : context.appColors.accent.withValues(alpha: 0.16),
            width: 1.2,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compactHorizontalPadding(textScale),
            vertical: compactLandscape ? 6 : 10,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360 || textScale > 1.2;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  _buildNumberBadge(context, hymn, fontSize),
                  SizedBox(width: compact ? 10 : 12),
                  Expanded(
                    child: _buildTitleSection(
                      context,
                      hymn,
                      fontSize,
                      compactLandscape,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: context.appColors.secondaryText,
                    size: 20,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  double compactHorizontalPadding(double textScale) {
    return textScale > 1.2 ? 10 : 12;
  }

  Widget _buildNumberBadge(BuildContext context, Hymn hymn, double fontSize) {
    final textScaler = MediaQuery.of(context).textScaler;
    final textScaleFactor = textScaler.scale(1.0);
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 38,
        child: Text(
          hymn.displayNumber > 0 ? '${hymn.displayNumber}' : '-',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.appColors.accent,
            fontSize: (fontSize * 0.72 * textScaleFactor.clamp(0.8, 1.25)),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(
    BuildContext context,
    Hymn hymn,
    double fontSize,
    bool compactLandscape,
  ) {
    String amharicTitle = hymn.displayTitle.trim();
    if (amharicTitle.isEmpty) {
      amharicTitle =
          hymn.displayNumber > 0 ? 'መዝሙር ${hymn.displayNumber}' : 'No Title';
    }

    final textScaler = MediaQuery.of(context).textScaler;
    final textScaleFactor = textScaler.scale(1.0);
    final englishTitle = hymn.displayEnglishTitle;
    final hasEnglishTitle = englishTitle.isNotEmpty;
    // Wide enough for the setting to show in the list, still bounded so a
    // row keeps its shape.
    final scaledFontSize =
        (fontSize * 0.85).clamp(14.0, 22.0) * textScaleFactor.clamp(0.8, 1.25);

    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            amharicTitle,
            style: TextStyle(
              color: context.appColors.primaryText,
              fontSize: scaledFontSize,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: 0,
            ),
            maxLines: hasEnglishTitle ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
          ),
          if (hasEnglishTitle) ...[
            SizedBox(height: compactLandscape ? 1 : 3),
            Text(
              englishTitle,
              // English reads in the serif face whichever language the
              // interface is set to: it is the hymn's English name, not a
              // piece of the interface.
              style: TextStyle(
                color: context.appColors.secondaryText,
                fontSize: 12.0 * textScaleFactor.clamp(0.8, 1.2),
                fontWeight: FontWeight.w400,
                height: 1.1,
                letterSpacing: 0,
                fontFamily: AppFonts.serif,
                fontFamilyFallback: AppFonts.ethiopicFallback,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
            ),
          ],
        ],
      ),
    );
  }
}
