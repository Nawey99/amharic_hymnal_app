import 'package:flutter/material.dart';

class CategoryIconMapper {
  static IconData iconFor(String categoryName) {
    if (categoryName.contains('ምስጋና')) return Icons.volunteer_activism;
    if (categoryName.contains('አምልኮ')) return Icons.church;
    if (categoryName.contains('ጸሎት')) return Icons.self_improvement;
    if (categoryName.contains('ጋብቻ')) return Icons.favorite;
    if (categoryName.contains('ልጆች')) return Icons.child_care;
    if (categoryName.contains('ትንሣኤ')) return Icons.wb_sunny_outlined;
    if (categoryName.contains('ሞት') || categoryName.contains('ሐዘን')) {
      return Icons.spa_outlined;
    }
    if (categoryName.contains('ሰንበት')) return Icons.event_available;
    if (categoryName.contains('መድኃኒት') || categoryName.contains('መዳን')) {
      return Icons.health_and_safety_outlined;
    }
    if (categoryName.contains('መስቀል')) return Icons.add;
    if (categoryName.contains('ሰላም')) return Icons.handshake_outlined;
    if (categoryName.contains('ተስፋ')) return Icons.light_mode_outlined;
    if (categoryName.contains('ሰማይ')) return Icons.home_work_outlined;
    if (categoryName.contains('ወጣቶች')) return Icons.groups_2_outlined;
    if (categoryName.contains('ሥራ')) return Icons.work_outline;
    if (categoryName.contains('ቃል')) return Icons.menu_book_outlined;
    if (categoryName.contains('መመለስ') || categoryName.contains('ንስሐ')) {
      return Icons.refresh;
    }
    if (categoryName.contains('ልደት')) return Icons.star_outline;
    if (categoryName.contains('ዳግም')) return Icons.cloud_outlined;
    if (categoryName.contains('ፍርድ')) return Icons.balance_outlined;
    if (categoryName.contains('ውጊያ')) return Icons.shield_outlined;
    if (categoryName.contains('መሰናበቻ')) return Icons.waving_hand_outlined;
    if (categoryName.contains('ፍቅር')) return Icons.favorite_border;
    return Icons.library_music_outlined;
  }
}
