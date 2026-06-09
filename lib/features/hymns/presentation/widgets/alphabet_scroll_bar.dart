// lib/features/hymns/presentation/widgets/alphabet_scroll_bar.dart
import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/utils/amharic_utils.dart';

class AlphabetScrollBar extends StatelessWidget {
  final List<String> letters;
  final Function(String) onLetterSelected;

  const AlphabetScrollBar({
    super.key,
    required this.letters,
    required this.onLetterSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Group letters by primary letter
    final groupedLetters = AmharicUtils.groupLettersByPrimary(letters);

    // Build list of letters to show in scrollbar
    // Only show letters that actually have hymns (not dimmed, just don't show inactive ones)
    final List<String> lettersToShow = [];
    final primaryLettersList = AmharicUtils.primaryLetters;

    for (final primaryLetter in primaryLettersList) {
      // Only show primary letter if it has hymns
      if (groupedLetters.containsKey(primaryLetter)) {
        lettersToShow.add(primaryLetter);

        // Show all children letters that appear in hymns
        final groupChildren = groupedLetters[primaryLetter]!;
        final allGroupLetters = AmharicUtils.getGroupLetters(primaryLetter);

        // Add children letters that appear in hymns (excluding the primary which we already added)
        for (final childLetter in allGroupLetters) {
          if (childLetter != primaryLetter &&
              groupChildren.contains(childLetter)) {
            lettersToShow.add(childLetter);
          }
        }
      }
    }

    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            final localPosition = box.globalToLocal(details.globalPosition);
            final index =
                (localPosition.dy / box.size.height * lettersToShow.length)
                    .floor();
            if (index >= 0 && index < lettersToShow.length) {
              final letter = lettersToShow[index];
              onLetterSelected(letter);
            }
          }
        },
        child: Container(
          width: 32,
          // Add clear spacing between scrollbar and song list to prevent overlap
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: lettersToShow.map((letter) {
                final isPrimary = primaryLettersList.contains(letter);

                return GestureDetector(
                  onTap: () {
                    onLetterSelected(letter);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: isPrimary ? 2 : 1,
                    ),
                    child: Text(
                      letter,
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: isPrimary ? 12 : 10,
                        fontWeight:
                            isPrimary ? FontWeight.bold : FontWeight.w500,
                        fontFamily: 'NotoSansEthiopic',
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
