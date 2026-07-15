// lib/features/hymns/presentation/widgets/hymn_list_item.dart
import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/utils/responsive_layout.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

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

  @override
  Widget build(BuildContext context) {
    final settingsRepository = sl<SettingsRepository>();
    final fontSize = settingsRepository.getFontSize();
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final backgroundImageEnabled = BackgroundImageService().isEnabled;
    final compactLandscape = ResponsiveLayout.isCompactLandscape(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: GlassContainer(
          margin: EdgeInsets.only(bottom: compactLandscape ? 6 : 10),
          borderRadius: 12.0,
          blurSigma: 12.0,
          opacity: backgroundImageEnabled ? 0.22 : 0.62,
          color: AppColors.surface,
          border: Border.all(
            color: backgroundImageEnabled
                ? Colors.white.withValues(alpha: 0.3)
                : AppColors.accentGreen.withValues(alpha: 0.16),
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
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.secondaryText,
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
            color: AppColors.accentGreen,
            fontSize: (fontSize * 0.72 * textScaleFactor.clamp(0.8, 1.25)),
            fontWeight: FontWeight.w800,
            fontFamily: 'NotoSansEthiopic',
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
    final scaledFontSize =
        (fontSize * 0.85).clamp(16.0, 18.0) * textScaleFactor.clamp(0.8, 1.25);

    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            amharicTitle,
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: scaledFontSize,
              fontWeight: FontWeight.w700,
              fontFamily: 'NotoSansEthiopic',
              height: 1.2,
              letterSpacing: 0,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            maxLines: hasEnglishTitle ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
          ),
          if (hasEnglishTitle) ...[
            SizedBox(height: compactLandscape ? 1 : 3),
            Text(
              englishTitle,
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12.0 * textScaleFactor.clamp(0.8, 1.2),
                fontWeight: FontWeight.w400,
                height: 1.1,
                letterSpacing: 0,
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
