import 'package:flutter/material.dart';

abstract final class CategoryIconMapper {
  static const IconData fallbackIcon = Icons.library_music_outlined;

  // Material icons are vector font glyphs, so these add no image assets to the
  // app and are tree-shaken in release builds.
  static const Map<String, IconData> _canonicalIcons = {
    'ምስጋና': Icons.celebration_outlined,
    'ስግደት': Icons.church_outlined,
    'መነቃቃት': Icons.notifications_active_outlined,
    'ንሥሐ': Icons.replay_rounded,
    'ጸሎት': Icons.self_improvement,
    'የክርስቲያን ኑሮ': Icons.directions_walk_rounded,
    'ራስን ቀድሶ መስጠት': Icons.volunteer_activism_outlined,
    'ሥራ': Icons.work_outline,
    'ሕዝብ': Icons.groups_rounded,
    'ታማኝነት': Icons.verified_outlined,
    'ተስፋ': Icons.light_mode_outlined,
    'ደስታ': Icons.sentiment_very_satisfied_outlined,
    'ሰላም': Icons.handshake_outlined,
    'ፍቅር': Icons.favorite_border,
    'መድህን': Icons.health_and_safety_outlined,
    'መስቀል': Icons.add_rounded,
    'ሰንበት': Icons.weekend_outlined,
    'የእግዚአብሔር ቃል': Icons.menu_book_outlined,
    'የክርስቲያን ተጋድሎ': Icons.shield_outlined,
    'ፍርድ': Icons.balance_outlined,
    'ዳግም ምፅአት': Icons.cloud_outlined,
    'የሰማይ ቤት': Icons.home_outlined,
    'ወጣቶች': Icons.groups_2_outlined,
    'ተፈጥሮ': Icons.park_outlined,
    'የልጆች መዝሙር': Icons.child_care_outlined,
    'ጋብቻ': Icons.diversity_1_outlined,
    'ልደት': Icons.star_outline,
    'መታመን': Icons.anchor_outlined,
    'ቁርባን': Icons.redeem_outlined,
    'ትንሣኤ': Icons.arrow_upward_rounded,
    'መሰናበቻ': Icons.local_florist_outlined,
  };

  static const Map<String, IconData> _legacyKeywordIcons = {
    'አምልኮ': Icons.church_outlined,
    'ንስሐ': Icons.replay_rounded,
    'መመለስ': Icons.replay_rounded,
    'መድኃኒት': Icons.health_and_safety_outlined,
    'መዳን': Icons.health_and_safety_outlined,
    'ውጊያ': Icons.shield_outlined,
    'ሰማይ': Icons.home_outlined,
    'ሞት': Icons.local_florist_outlined,
    'ሐዘን': Icons.local_florist_outlined,
  };

  static IconData iconFor(String categoryName) {
    final normalizedName = categoryName.trim();
    final exactIcon = _canonicalIcons[normalizedName];
    if (exactIcon != null) return exactIcon;

    for (final entry in _canonicalIcons.entries) {
      if (normalizedName.contains(entry.key)) return entry.value;
    }
    for (final entry in _legacyKeywordIcons.entries) {
      if (normalizedName.contains(entry.key)) return entry.value;
    }
    return fallbackIcon;
  }
}
