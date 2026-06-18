// lib/features/hymns/presentation/widgets/hymn_list_item.dart
import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/core/utils/category_image_generator.dart';
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

    // Step 1: Simplify and Rewrite the Widget Structure
    // Step 5: Fix GlassCard Interaction - Use Material for better rendering
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: GlassCard(
          margin: const EdgeInsets.only(bottom: 8),
          borderRadius: 16.0,
          onTap: null, // Disable GlassCard onTap since Material handles it
          child: Container(
            constraints: const BoxConstraints(
              // Allow enough room for Amharic title plus optional English title.
              minHeight: 80,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                // Step 2: Fix Number Badge Visibility - Use explicit green with full opacity
                _buildNumberBadge(context, hymn, fontSize),
                const SizedBox(
                    width:
                        16), // Increased spacing to make number feel secondary
                // Category image - inserted after number badge and before title
                if (hymn.category != null && hymn.category!.isNotEmpty) ...[
                  CategoryImageGenerator.buildCategoryImage(hymn.category!,
                      size: 40),
                  const SizedBox(width: 12), // Spacing after image
                ],
                // Step 3: Fix Title Text Visibility - Use explicit white color
                // Shows both Amharic (primary) and English (secondary) titles
                Expanded(
                  child: _buildTitleSection(context, hymn, fontSize),
                ),
                const SizedBox(width: 8),
                // Chevron icon
                Icon(
                  Icons.chevron_right,
                  color: Colors.white
                      .withValues(alpha: 0.5), // Explicit white with opacity
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Step 2: Fix Number Badge Visibility
  /// Use explicit green color with full opacity and Material for better rendering
  /// Reduced size and opacity to feel secondary
  Widget _buildNumberBadge(BuildContext context, Hymn hymn, double fontSize) {
    // Get text scale factor for font scaling support
    final textScaler = MediaQuery.of(context).textScaler;
    final textScaleFactor = textScaler.scale(1.0);
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color:
              Colors.green.withValues(alpha: 0.3), // Explicit green background
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.8), // Explicit green border
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            hymn.displayNumber > 0 ? '${hymn.displayNumber}' : '-',
            style: TextStyle(
              color: Colors.green
                  .withValues(alpha: 0.8), // Reduced opacity to feel secondary
              fontSize: (fontSize *
                  0.7 *
                  textScaleFactor.clamp(
                      0.8, 1.5)), // Reduced from 0.85 to 0.7 with scaling
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoSansEthiopic',
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build title section with Amharic (primary) and English (secondary) titles
  ///
  /// Layout:
  /// - Amharic title: bold (w700), larger font, better spacing
  /// - English title: regular (w400), smaller font, reduced opacity (70%)
  /// - Clear hierarchy with size difference and spacing
  Widget _buildTitleSection(BuildContext context, Hymn hymn, double fontSize) {
    // Get Amharic title
    String amharicTitle = hymn.displayTitle.trim();
    if (amharicTitle.isEmpty) {
      amharicTitle =
          hymn.displayNumber > 0 ? 'መዝሙር ${hymn.displayNumber}' : 'No Title';
    }

    // Get English title
    final englishTitle = hymn.englishTitleOld?.trim();

    // Get text scale factor for font scaling support
    final textScaler = MediaQuery.of(context).textScaler;
    final textScaleFactor = textScaler.scale(1.0);
    final baseFontSize = (fontSize < 16) ? 16.0 : fontSize;
    final scaledFontSize = baseFontSize * textScaleFactor.clamp(0.8, 1.5);

    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Amharic title (primary) - improved typography
          Text(
            amharicTitle,
            style: TextStyle(
              color: Colors.white, // Explicit white color
              fontSize: scaledFontSize,
              fontWeight: FontWeight.w700, // Improved font weight
              fontFamily: 'NotoSansEthiopic',
              height: 1.15,
              letterSpacing: 0,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.9),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
                Shadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 2,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
          ),
          // English title (secondary, smaller, reduced opacity) - improved spacing
          if (englishTitle != null && englishTitle.isNotEmpty) ...[
            SizedBox(height: 2 * textScaleFactor.clamp(0.8, 1.5)),
            Text(
              englishTitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), // 70% opacity
                fontSize: (12.0 *
                    textScaleFactor.clamp(
                        0.8, 1.5)), // Smaller font with scaling
                fontWeight: FontWeight.w400, // Regular weight
                fontFamily: 'NotoSansEthiopic',
                height: 1.1,
                letterSpacing: 0,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
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
