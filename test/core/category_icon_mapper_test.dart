import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/constants/hymn_categories.dart';
import 'package:amharic_hymnal_app/core/utils/category_icon_mapper.dart';

void main() {
  test('every canonical category has a dedicated icon', () {
    for (final category in HymnCategories.all) {
      expect(
        CategoryIconMapper.iconFor(category.nameAmharic),
        isNot(CategoryIconMapper.fallbackIcon),
        reason: '${category.nameAmharic} should not use the fallback icon',
      );
    }
  });

  test('previously generic categories use matching semantic icons', () {
    const expectedIcons = <String, IconData>{
      'ስግደት': Icons.church_outlined,
      'መነቃቃት': Icons.notifications_active_outlined,
      'ንሥሐ': Icons.replay_rounded,
      'የክርስቲያን ኑሮ': Icons.directions_walk_rounded,
      'ራስን ቀድሶ መስጠት': Icons.volunteer_activism_outlined,
      'ሕዝብ': Icons.groups_rounded,
      'ታማኝነት': Icons.verified_outlined,
      'ደስታ': Icons.sentiment_very_satisfied_outlined,
      'መድህን': Icons.health_and_safety_outlined,
      'የክርስቲያን ተጋድሎ': Icons.shield_outlined,
      'ተፈጥሮ': Icons.park_outlined,
      'መታመን': Icons.anchor_outlined,
      'ቁርባን': Icons.redeem_outlined,
    };

    for (final entry in expectedIcons.entries) {
      expect(CategoryIconMapper.iconFor(entry.key), entry.value);
    }
  });

  test('alternate repentance spelling keeps the repentance icon', () {
    expect(CategoryIconMapper.iconFor('ንስሐ'), Icons.replay_rounded);
    expect(CategoryIconMapper.iconFor(' ንሥሐ '), Icons.replay_rounded);
  });
}
