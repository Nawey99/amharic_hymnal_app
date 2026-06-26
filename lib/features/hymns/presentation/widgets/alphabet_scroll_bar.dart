// lib/features/hymns/presentation/widgets/alphabet_scroll_bar.dart
import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/utils/amharic_utils.dart';

class AlphabetScrollBar extends StatelessWidget {
  final List<String> letters;
  final Function(String) onLetterSelected;
  final double bottomPadding;

  const AlphabetScrollBar({
    super.key,
    required this.letters,
    required this.onLetterSelected,
    this.bottomPadding = 0,
  });

  static List<String> visibleLetters(List<String> letters) {
    final groupedLetters = AmharicUtils.groupLettersByPrimary(letters);
    final lettersToShow = <String>[];
    final primaryLettersList = AmharicUtils.primaryLetters;

    for (final primaryLetter in primaryLettersList) {
      if (groupedLetters.containsKey(primaryLetter)) {
        lettersToShow.add(primaryLetter);
        final groupChildren = groupedLetters[primaryLetter]!;
        final allGroupLetters = AmharicUtils.getGroupLetters(primaryLetter);
        for (final childLetter in allGroupLetters) {
          if (childLetter != primaryLetter &&
              groupChildren.contains(childLetter)) {
            lettersToShow.add(childLetter);
          }
        }
      }
    }
    return lettersToShow;
  }

  @override
  Widget build(BuildContext context) {
    final lettersToShow = visibleLetters(letters);
    final primaryLettersList = AmharicUtils.primaryLetters;

    return Positioned(
      right: 0,
      top: 0,
      bottom: bottomPadding,
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final itemHeight = lettersToShow.isEmpty
                ? 18.0
                : (availableHeight / lettersToShow.length)
                    .clamp(12.0, 22.0)
                    .toDouble();

            return Container(
              width: 32,
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: lettersToShow.map((letter) {
                  final isPrimary = primaryLettersList.contains(letter);

                  return GestureDetector(
                    onTap: () {
                      onLetterSelected(letter);
                    },
                    child: SizedBox(
                      height: itemHeight,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
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
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
