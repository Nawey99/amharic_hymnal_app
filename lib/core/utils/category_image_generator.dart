// lib/core/utils/category_image_generator.dart
import 'package:flutter/material.dart';

/// Utility for generating dynamic category images based on category name
///
/// Uses category name hash to determine consistent color/gradient for each category.
/// Generates simple colored containers with icons or text as placeholders.
class CategoryImageGenerator {
  // Cache for generated images to avoid rebuilding
  static final Map<String, Widget> _imageCache = {};

  /// Generate a category image widget based on category name
  ///
  /// Uses hash of category name to generate consistent colors.
  /// Returns a colored container with an icon or category initial.
  static Widget buildCategoryImage(String category, {double size = 40}) {
    // Check cache first
    final cacheKey = '${category}_$size';
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey]!;
    }

    // Generate color based on category name hash
    final color = _getCategoryColor(category);

    // Get category icon or initial
    final icon = _getCategoryIcon(category);
    final initial = _getCategoryInitial(category);

    final image = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: icon != null
          ? Icon(
              icon,
              color: Colors.white,
              size: size * 0.6,
            )
          : Center(
              child: Text(
                initial,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansEthiopic',
                ),
              ),
            ),
    );

    // Cache the generated image
    _imageCache[cacheKey] = image;
    return image;
  }

  /// Get color for category based on name hash
  static Color _getCategoryColor(String category) {
    // Generate consistent color from category name hash
    final hash = category.hashCode;
    final hue = (hash.abs() % 360).toDouble();

    // Use HSL color space for vibrant colors
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor();
  }

  /// Get icon for category if available
  static IconData? _getCategoryIcon(String category) {
    final lowerCategory = category.toLowerCase();

    // Map common category names to icons
    final iconMap = {
      'praise': Icons.music_note,
      'worship': Icons.favorite,
      'prayer': Icons.volunteer_activism,
      'thanksgiving': Icons.celebration,
      'adoration': Icons.star,
      'devotion': Icons.book,
      'meditation': Icons.self_improvement,
      'communion': Icons.restaurant,
      'baptism': Icons.water_drop,
      'marriage': Icons.favorite_border,
      'funeral': Icons.church,
      'christmas': Icons.card_giftcard,
      'easter': Icons.celebration_outlined,
      'holy week': Icons.church,
      'pentecost': Icons.local_fire_department,
      'advent': Icons.calendar_today,
    };

    // Check for partial matches
    for (final entry in iconMap.entries) {
      if (lowerCategory.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Get first letter/character of category for display
  static String _getCategoryInitial(String category) {
    if (category.isEmpty) return '?';
    // Return first character (works for both Amharic and English)
    return category[0].toUpperCase();
  }

  /// Clear image cache (useful for testing or memory management)
  static void clearCache() {
    _imageCache.clear();
  }
}
