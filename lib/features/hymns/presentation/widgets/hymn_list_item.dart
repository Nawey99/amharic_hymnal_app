// lib/features/hymns/presentation/widgets/hymn_list_item.dart
import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: GlassContainer(
          margin: const EdgeInsets.only(bottom: 10),
          borderRadius: 12.0,
          blurSigma: 12.0,
          opacity: 0.22,
          padding: EdgeInsets.symmetric(
            horizontal: compactHorizontalPadding(textScale),
            vertical: 10,
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
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.secondaryText,
                    size: 22,
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
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.accentGreen.withValues(alpha: 0.35),
          ),
        ),
        child: Center(
          child: Text(
            hymn.displayNumber > 0 ? '${hymn.displayNumber}' : '-',
            style: TextStyle(
              color: AppColors.accentGreen,
              fontSize: (fontSize * 0.72 * textScaleFactor.clamp(0.8, 1.35)),
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoSansEthiopic',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(
    BuildContext context,
    Hymn hymn,
    double fontSize,
  ) {
    String amharicTitle = hymn.displayTitle.trim();
    if (amharicTitle.isEmpty) {
      amharicTitle =
          hymn.displayNumber > 0 ? 'መዝሙር ${hymn.displayNumber}' : 'No Title';
    }

    final textScaler = MediaQuery.of(context).textScaler;
    final textScaleFactor = textScaler.scale(1.0);
    final scaledFontSize =
        (fontSize * 0.85).clamp(16.0, 18.0) * textScaleFactor.clamp(0.8, 1.25);

    return Material(
      color: Colors.transparent,
      child: Text(
        amharicTitle,
        style: TextStyle(
          color: AppColors.primaryText,
          fontSize: scaledFontSize,
          fontWeight: FontWeight.w700,
          fontFamily: 'NotoSansEthiopic',
          height: 1.25,
          letterSpacing: 0,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.start,
      ),
    );
  }
}
