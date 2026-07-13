// lib/features/hymns/presentation/widgets/alphabet_scroll_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/utils/index_section_utils.dart';

class IndexedFastScroller extends StatefulWidget {
  static const double verticalPadding = 6;
  static const double minReadableItemHeight = 18;
  static const double horizontalItemExtent = 44;
  static const double horizontalRailHeight = 54;

  final List<String> labels;
  final ValueChanged<String> onLabelSelected;
  final double bottomPadding;
  final double topPadding;
  final String? activeLabel;
  final bool? useHorizontalLayout;

  const IndexedFastScroller({
    super.key,
    required this.labels,
    required this.onLabelSelected,
    this.bottomPadding = 0,
    this.topPadding = 0,
    this.activeLabel,
    this.useHorizontalLayout,
  });

  static bool shouldUseHorizontalLayout({
    required int labelCount,
    required double availableHeight,
    double topPadding = 0,
    double bottomPadding = 0,
  }) {
    if (labelCount <= 0 || !availableHeight.isFinite) return false;

    final railHeight = availableHeight - topPadding - bottomPadding;
    final usableHeight = railHeight - (verticalPadding * 2);
    return usableHeight < labelCount * minReadableItemHeight;
  }

  @override
  State<IndexedFastScroller> createState() => _IndexedFastScrollerState();
}

class _IndexedFastScrollerState extends State<IndexedFastScroller> {
  static const double _horizontalMargin = 12;
  static const double _selectionBubbleSize = 54;

  final ScrollController _horizontalController = ScrollController();
  final GlobalKey _verticalRailKey = GlobalKey();
  final GlobalKey _horizontalRailKey = GlobalKey();

  String? _bubbleLabel;
  double? _bubbleTop;
  double? _bubbleLeft;
  Axis? _bubbleAxis;
  String? _lastInteractionLabel;
  bool _isPointerDown = false;
  bool? _wasHorizontalLayout;

  @override
  void initState() {
    super.initState();
    _scheduleActiveLabelVisibility();
  }

  @override
  void didUpdateWidget(covariant IndexedFastScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeLabel != widget.activeLabel ||
        oldWidget.labels != widget.labels) {
      _scheduleActiveLabelVisibility();
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  void _scheduleActiveLabelVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isPointerDown) return;
      _ensureActiveLabelVisible();
    });
  }

  void _ensureActiveLabelVisible() {
    if (!_horizontalController.hasClients) return;
    final activeLabel = widget.activeLabel;
    final index = activeLabel == null ? -1 : widget.labels.indexOf(activeLabel);
    if (index < 0) return;

    final position = _horizontalController.position;
    final centeredOffset = (index * IndexedFastScroller.horizontalItemExtent) -
        ((position.viewportDimension -
                IndexedFastScroller.horizontalItemExtent) /
            2);
    final target = centeredOffset
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((position.pixels - target).abs() < 1) return;

    _horizontalController.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  void _selectVerticalFromGlobalPosition(Offset globalPosition) {
    final railBox =
        _verticalRailKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (railBox == null ||
        overlayBox == null ||
        !railBox.hasSize ||
        !overlayBox.hasSize ||
        widget.labels.isEmpty) {
      return;
    }

    final local = railBox.globalToLocal(globalPosition);
    final railHeight = railBox.size.height;
    final clampedDy = local.dy.clamp(0.0, railHeight).toDouble();
    final index = (clampedDy / railHeight * widget.labels.length)
        .floor()
        .clamp(0, widget.labels.length - 1);
    final overlayPosition = overlayBox.globalToLocal(globalPosition);
    final maxBubbleTop =
        (overlayBox.size.height - widget.bottomPadding - _selectionBubbleSize)
            .clamp(widget.topPadding, double.infinity)
            .toDouble();
    final bubbleTop = (overlayPosition.dy - (_selectionBubbleSize / 2))
        .clamp(widget.topPadding, maxBubbleTop)
        .toDouble();

    _selectLabel(
      widget.labels[index],
      axis: Axis.vertical,
      bubbleTop: bubbleTop,
    );
  }

  void _selectHorizontalFromGlobalPosition(Offset globalPosition) {
    final railBox =
        _horizontalRailKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (railBox == null ||
        overlayBox == null ||
        !railBox.hasSize ||
        !overlayBox.hasSize ||
        widget.labels.isEmpty) {
      return;
    }

    final local = railBox.globalToLocal(globalPosition);
    final horizontalOffset =
        _horizontalController.hasClients ? _horizontalController.offset : 0.0;
    const contentPadding = 4.0;
    final contentX = local.dx + horizontalOffset - contentPadding;
    final index = (contentX / IndexedFastScroller.horizontalItemExtent)
        .floor()
        .clamp(0, widget.labels.length - 1);
    final overlayPosition = overlayBox.globalToLocal(globalPosition);
    final maxBubbleLeft = (overlayBox.size.width - _selectionBubbleSize - 8)
        .clamp(8.0, double.infinity);
    final bubbleLeft = (overlayPosition.dx - (_selectionBubbleSize / 2))
        .clamp(8.0, maxBubbleLeft)
        .toDouble();

    _selectLabel(
      widget.labels[index],
      axis: Axis.horizontal,
      bubbleLeft: bubbleLeft,
    );
  }

  void _selectLabel(
    String label, {
    required Axis axis,
    double? bubbleTop,
    double? bubbleLeft,
  }) {
    final labelChanged = _lastInteractionLabel != label;
    final bubbleChanged = _bubbleLabel != label ||
        _bubbleAxis != axis ||
        _bubbleTop != bubbleTop ||
        _bubbleLeft != bubbleLeft;

    if (labelChanged) {
      _lastInteractionLabel = label;
      HapticFeedback.selectionClick();
      widget.onLabelSelected(label);
    }
    if (bubbleChanged && mounted) {
      setState(() {
        _bubbleLabel = label;
        _bubbleAxis = axis;
        _bubbleTop = bubbleTop;
        _bubbleLeft = bubbleLeft;
      });
    }
  }

  void _startHorizontalInteraction(PointerEvent event) {
    _isPointerDown = true;
    _selectHorizontalFromGlobalPosition(event.position);
  }

  void _finishInteraction() {
    _isPointerDown = false;
    _lastInteractionLabel = null;
    if (_bubbleLabel != null && mounted) {
      setState(() {
        _bubbleLabel = null;
        _bubbleAxis = null;
        _bubbleTop = null;
        _bubbleLeft = null;
      });
    }
    _scheduleActiveLabelVisibility();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.labels.isEmpty) return const SizedBox.shrink();

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useHorizontalLayout = widget.useHorizontalLayout ??
              IndexedFastScroller.shouldUseHorizontalLayout(
                labelCount: widget.labels.length,
                availableHeight: constraints.maxHeight,
                topPadding: widget.topPadding,
                bottomPadding: widget.bottomPadding,
              );
          if (_wasHorizontalLayout != useHorizontalLayout) {
            _wasHorizontalLayout = useHorizontalLayout;
            if (useHorizontalLayout) {
              _scheduleActiveLabelVisibility();
            }
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (useHorizontalLayout)
                _buildHorizontalRail()
              else
                _buildVerticalRail(constraints.maxHeight),
              if (_bubbleLabel != null) _buildSelectionBubble(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVerticalRail(double availableHeight) {
    final railHeight =
        availableHeight - widget.topPadding - widget.bottomPadding;
    final usableHeight =
        (railHeight - (IndexedFastScroller.verticalPadding * 2))
            .clamp(0.0, railHeight)
            .toDouble();
    final itemHeight = (usableHeight / widget.labels.length)
        .clamp(
          IndexedFastScroller.minReadableItemHeight,
          22.0,
        )
        .toDouble();

    return Positioned(
      right: 0,
      top: widget.topPadding,
      bottom: widget.bottomPadding,
      child: GestureDetector(
        key: _verticalRailKey,
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          _isPointerDown = true;
          _selectVerticalFromGlobalPosition(details.globalPosition);
        },
        onTapUp: (_) => _finishInteraction(),
        onTapCancel: _finishInteraction,
        onVerticalDragStart: (details) {
          _isPointerDown = true;
          _selectVerticalFromGlobalPosition(details.globalPosition);
        },
        onVerticalDragUpdate: (details) =>
            _selectVerticalFromGlobalPosition(details.globalPosition),
        onVerticalDragEnd: (_) => _finishInteraction(),
        onVerticalDragCancel: _finishInteraction,
        child: KeyedSubtree(
          key: const ValueKey('alphabet-vertical-rail'),
          child: _buildVerticalRailSurface(itemHeight),
        ),
      ),
    );
  }

  Widget _buildVerticalRailSurface(double itemHeight) {
    return Container(
      width: 38,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(
        vertical: IndexedFastScroller.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.labels.map((label) {
          final isActive = widget.activeLabel == label || _bubbleLabel == label;
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
                    fontSize: isActive ? 14 : 12,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    fontFamily: 'NotoSansEthiopic',
                  ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildHorizontalRail() {
    return Positioned(
      left: _horizontalMargin,
      right: _horizontalMargin,
      bottom: widget.bottomPadding,
      height: IndexedFastScroller.horizontalRailHeight,
      child: Listener(
        key: _horizontalRailKey,
        behavior: HitTestBehavior.opaque,
        onPointerDown: _startHorizontalInteraction,
        onPointerMove: (event) =>
            _selectHorizontalFromGlobalPosition(event.position),
        onPointerUp: (_) => _finishInteraction(),
        onPointerCancel: (_) => _finishInteraction(),
        child: Container(
          key: const ValueKey('alphabet-horizontal-rail'),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = (widget.labels.length *
                        IndexedFastScroller.horizontalItemExtent) +
                    8;
                final canScroll = contentWidth > constraints.maxWidth;
                return Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: canScroll,
                  trackVisibility: false,
                  interactive: true,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  thickness: 3,
                  radius: const Radius.circular(2),
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(4, 2, 4, 5),
                    child: Row(
                      children: widget.labels
                          .map(_buildHorizontalLabel)
                          .toList(growable: false),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalLabel(String label) {
    final isActive = widget.activeLabel == label || _bubbleLabel == label;
    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      excludeSemantics: true,
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onLabelSelected(label);
      },
      child: SizedBox(
        width: IndexedFastScroller.horizontalItemExtent,
        height: 44,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.accentGreen.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.accentGreen : AppColors.primaryText,
                fontSize: isActive ? 17 : 15,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                fontFamily: 'NotoSansEthiopic',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBubble() {
    final isHorizontal = _bubbleAxis == Axis.horizontal;
    return Positioned(
      right: isHorizontal ? null : 58,
      top: isHorizontal ? null : _bubbleTop,
      left: isHorizontal ? _bubbleLeft : null,
      bottom: isHorizontal
          ? widget.bottomPadding + IndexedFastScroller.horizontalRailHeight + 10
          : null,
      child: IgnorePointer(
        child: DecoratedBox(
          key: const ValueKey('fast-scroller-selection-bubble'),
          decoration: BoxDecoration(
            color: AppColors.accentGreen,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.34),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SizedBox.square(
            dimension: _selectionBubbleSize,
            child: Center(
              child: Text(
                _bubbleLabel!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'NotoSansEthiopic',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AmharicFastScroller extends StatelessWidget {
  final List<String> availableLabels;
  final ValueChanged<String> onLetterSelected;
  final double bottomPadding;
  final String? activeLabel;
  final bool? useHorizontalLayout;

  const AmharicFastScroller({
    super.key,
    required this.availableLabels,
    required this.onLetterSelected,
    this.bottomPadding = 0,
    this.activeLabel,
    this.useHorizontalLayout,
  });

  @override
  Widget build(BuildContext context) {
    final labels = visibleLetters(availableLabels);
    return IndexedFastScroller(
      labels: labels,
      activeLabel: activeLabel,
      bottomPadding: bottomPadding,
      useHorizontalLayout: useHorizontalLayout,
      onLabelSelected: onLetterSelected,
    );
  }
}

class NumericFastScroller extends StatelessWidget {
  final List<String> availableLabels;
  final ValueChanged<String> onNumberSelected;
  final double bottomPadding;
  final bool? useHorizontalLayout;

  const NumericFastScroller({
    super.key,
    required this.availableLabels,
    required this.onNumberSelected,
    this.bottomPadding = 0,
    this.useHorizontalLayout,
  });

  @override
  Widget build(BuildContext context) {
    return IndexedFastScroller(
      labels: availableLabels,
      bottomPadding: bottomPadding,
      useHorizontalLayout: useHorizontalLayout,
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
    super.useHorizontalLayout,
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
