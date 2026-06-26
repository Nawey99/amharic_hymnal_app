// lib/features/hymns/presentation/widgets/alphabet_scroll_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/utils/index_section_utils.dart';

class IndexedFastScroller extends StatefulWidget {
  final List<String> labels;
  final ValueChanged<String> onLabelSelected;
  final double bottomPadding;
  final double topPadding;
  final String? activeLabel;

  const IndexedFastScroller({
    super.key,
    required this.labels,
    required this.onLabelSelected,
    this.bottomPadding = 0,
    this.topPadding = 0,
    this.activeLabel,
  });

  @override
  State<IndexedFastScroller> createState() => _IndexedFastScrollerState();
}

class _IndexedFastScrollerState extends State<IndexedFastScroller> {
  String? _bubbleLabel;

  void _selectFromGlobalPosition(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || widget.labels.isEmpty) return;

    final local = box.globalToLocal(globalPosition);
    final index = (local.dy / box.size.height * widget.labels.length)
        .floor()
        .clamp(0, widget.labels.length - 1);
    final label = widget.labels[index];
    if (_bubbleLabel != label) {
      HapticFeedback.selectionClick();
      setState(() => _bubbleLabel = label);
    }
    widget.onLabelSelected(label);
  }

  void _hideBubble() {
    if (_bubbleLabel != null) {
      setState(() => _bubbleLabel = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.labels.isEmpty) return const SizedBox.shrink();

    return Positioned(
      right: 0,
      top: widget.topPadding,
      bottom: widget.bottomPadding,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerRight,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _selectFromGlobalPosition(
              details.globalPosition,
            ),
            onVerticalDragStart: (details) => _selectFromGlobalPosition(
              details.globalPosition,
            ),
            onVerticalDragUpdate: (details) => _selectFromGlobalPosition(
              details.globalPosition,
            ),
            onVerticalDragEnd: (_) => _hideBubble(),
            onVerticalDragCancel: _hideBubble,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const verticalPadding = 5.0;
                final usableHeight =
                    (constraints.maxHeight - (verticalPadding * 2))
                        .clamp(0.0, constraints.maxHeight)
                        .toDouble();
                final itemHeight = (usableHeight / widget.labels.length)
                    .clamp(8.0, 18.0)
                    .toDouble();
                return Container(
                  width: 34,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    vertical: verticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.labels.map((label) {
                      final isActive =
                          widget.activeLabel == label || _bubbleLabel == label;
                      return SizedBox(
                        height: itemHeight,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              style: TextStyle(
                                color: isActive
                                    ? AppColors.accentGreen
                                    : AppColors.primaryText,
                                fontSize: isActive ? 13 : 11,
                                fontWeight: isActive
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontFamily: 'NotoSansEthiopic',
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
          if (_bubbleLabel != null)
            Positioned(
              right: 58,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Center(
                      child: Text(
                        _bubbleLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'NotoSansEthiopic',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AmharicFastScroller extends StatelessWidget {
  final List<String> availableLabels;
  final ValueChanged<String> onLetterSelected;
  final double bottomPadding;
  final String? activeLabel;

  const AmharicFastScroller({
    super.key,
    required this.availableLabels,
    required this.onLetterSelected,
    this.bottomPadding = 0,
    this.activeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final labels = visibleLetters(availableLabels);
    return IndexedFastScroller(
      labels: labels,
      activeLabel: activeLabel,
      bottomPadding: bottomPadding,
      onLabelSelected: onLetterSelected,
    );
  }
}

class NumericFastScroller extends StatelessWidget {
  final List<String> availableLabels;
  final ValueChanged<String> onNumberSelected;
  final double bottomPadding;

  const NumericFastScroller({
    super.key,
    required this.availableLabels,
    required this.onNumberSelected,
    this.bottomPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    final available = availableLabels.toSet();
    final labels =
        numericIndexOrder.where((label) => available.contains(label)).toList();
    return IndexedFastScroller(
      labels: labels,
      bottomPadding: bottomPadding,
      onLabelSelected: onNumberSelected,
    );
  }
}

class AlphabetScrollBar extends AmharicFastScroller {
  const AlphabetScrollBar({
    super.key,
    required super.availableLabels,
    required super.onLetterSelected,
    super.bottomPadding,
    super.activeLabel,
  });

  static List<String> visibleLetters(List<String> letters) {
    final available = letters.toSet();
    return amharicFidelIndexOrder
        .where((letter) => available.contains(letter))
        .toList();
  }
}

List<String> visibleLetters(List<String> letters) {
  return AlphabetScrollBar.visibleLetters(letters);
}
