import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/utils/nav_bar_constants.dart';
import 'package:amharic_hymnal_app/core/utils/responsive_layout.dart';

@immutable
class AppNavigationDestination {
  final String id;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const AppNavigationDestination({
    required this.id,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class AppBottomNavigationBar extends StatelessWidget {
  /// The same gap on every side between the bar's edge and a tab.
  static const double _tabInset = 5;

  /// The bar keeps one height, so its small labels follow the phone's text
  /// size only this far; past it a label would grow out of the bar. The
  /// labels are also spoken in full by a screen reader and shown on a long
  /// press, and every tab carries a large icon.
  static const double maxLabelTextScale = 1.3;

  final List<AppNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final String primaryDestinationId;

  const AppBottomNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.primaryDestinationId = 'number',
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compactLandscape = ResponsiveLayout.isCompactLandscape(context);
    final compact = compactLandscape || size.width < 375 || textScale > 1.25;
    final surfaceHeight = compactLandscape
        ? NavBarConstants.compactSurfaceHeight
        : NavBarConstants.surfaceHeight;
    final raisedExtent = compactLandscape
        ? NavBarConstants.compactRaisedExtent
        : NavBarConstants.raisedExtent;
    final primaryDiameter = compactLandscape ? 50.0 : (compact ? 58.0 : 62.0);
    final primarySlotWidth = compactLandscape ? 62.0 : (compact ? 72.0 : 78.0);
    final horizontalInset = compactLandscape ? 8.0 : 12.0;
    final bottomMargin =
        compactLandscape ? 4.0 : NavBarConstants.navBarBottomMargin;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final controlsHeight = surfaceHeight + raisedExtent;
    final innerRadius = surfaceHeight / 2;
    final outerRadius = compactLandscape ? 24.0 : 32.0;
    final primaryIndex = destinations.indexWhere(
      (destination) => destination.id == primaryDestinationId,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(
          textScale.clamp(1.0, maxLabelTextScale),
        ),
      ),
      child: SizedBox(
        key: const ValueKey('app-bottom-navigation-bar'),
        height: controlsHeight + bottomMargin + bottomInset,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              child: _ProgressiveNavigationBackdrop(
                topRadius: outerRadius,
              ),
            ),
            Positioned(
              top: 0,
              left: horizontalInset,
              right: horizontalInset,
              height: controlsHeight,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: raisedExtent,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(innerRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(innerRadius),
                        child: BackdropFilter(
                          key: const ValueKey('navigation-inner-glass'),
                          filter: ImageFilter.blur(
                            sigmaX: 4,
                            sigmaY: 4,
                            tileMode: TileMode.clamp,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: context.appColors.surface.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(innerRadius),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.24),
                                width: 0.9,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: raisedExtent + _tabInset,
                    left: _tabInset,
                    right: _tabInset,
                    bottom: _tabInset,
                    child: LayoutBuilder(
                      builder: (context, constraints) => Stack(
                        children: [
                          _buildIndicator(
                            context,
                            constraints.biggest,
                            primaryIndex: primaryIndex,
                            primarySlotWidth: primarySlotWidth,
                          ),
                          Positioned.fill(
                            child: primaryIndex < 0
                                ? _buildDestinationRow(
                                    context,
                                    start: 0,
                                    end: destinations.length,
                                    compact: compact,
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: _buildDestinationRow(
                                          context,
                                          start: 0,
                                          end: primaryIndex,
                                          compact: compact,
                                        ),
                                      ),
                                      SizedBox(width: primarySlotWidth),
                                      Expanded(
                                        child: _buildDestinationRow(
                                          context,
                                          start: primaryIndex + 1,
                                          end: destinations.length,
                                          compact: compact,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (primaryIndex >= 0)
                    _PrimaryNavigationAction(
                      destination: destinations[primaryIndex],
                      selected: selectedIndex == primaryIndex,
                      diameter: primaryDiameter,
                      compact: compact,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onDestinationSelected(primaryIndex);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The highlight behind the selected tab. It slides between tabs and is
  /// inset by [_tabInset] on every side, so its round ends follow the bar's.
  /// It fades into the centre slot when the raised number action is chosen.
  Widget _buildIndicator(
    BuildContext context,
    Size area, {
    required int primaryIndex,
    required double primarySlotWidth,
  }) {
    final count = destinations.length;
    final sideWidth =
        primaryIndex < 0 ? area.width : (area.width - primarySlotWidth) / 2;
    var left = sideWidth;
    var width = primaryIndex < 0 ? 0.0 : primarySlotWidth;
    final visible = selectedIndex >= 0 &&
        selectedIndex < count &&
        selectedIndex != primaryIndex;

    if (visible) {
      if (primaryIndex < 0) {
        width = area.width / count;
        left = selectedIndex * width;
      } else if (selectedIndex < primaryIndex) {
        width = sideWidth / primaryIndex;
        left = selectedIndex * width;
      } else {
        width = sideWidth / (count - primaryIndex - 1);
        left = sideWidth +
            primarySlotWidth +
            (selectedIndex - primaryIndex - 1) * width;
      }
    }

    return AnimatedPositioned(
      key: const ValueKey('bottom-nav-indicator'),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      left: left,
      width: width,
      top: 0,
      bottom: 0,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            color: context.appColors.accent.withValues(alpha: 0.14),
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationRow(
    BuildContext context, {
    required int start,
    required int end,
    required bool compact,
  }) {
    if (start >= end) return const SizedBox.expand();

    return Row(
      children: [
        for (var index = start; index < end; index++)
          Expanded(
            child: _NavigationDestinationButton(
              destination: destinations[index],
              selected: selectedIndex == index,
              compact: compact,
              onTap: () {
                HapticFeedback.selectionClick();
                onDestinationSelected(index);
              },
            ),
          ),
      ],
    );
  }
}

class _ProgressiveNavigationBackdrop extends StatelessWidget {
  final double topRadius;

  const _ProgressiveNavigationBackdrop({required this.topRadius});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ShaderMask(
            key: const ValueKey('navigation-outer-fade'),
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.16),
                Colors.black.withValues(alpha: 0.62),
                Colors.black,
              ],
              stops: const [0, 0.5, 1],
            ).createShader(bounds),
            child: BackdropFilter(
              key: const ValueKey('navigation-outer-glass'),
              filter: ImageFilter.blur(
                sigmaX: 13,
                sigmaY: 13,
                tileMode: TileMode.clamp,
              ),
              child: ColoredBox(
                color:
                    context.appColors.primaryBackground.withValues(alpha: 0.04),
              ),
            ),
          ),
          DecoratedBox(
            key: const ValueKey('navigation-outer-scrim'),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.appColors.primaryBackground.withValues(alpha: 0.02),
                  context.appColors.primaryBackground.withValues(alpha: 0.18),
                  context.appColors.primaryBackground.withValues(alpha: 0.38),
                ],
                stops: const [0, 0.52, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationDestinationButton extends StatefulWidget {
  final AppNavigationDestination destination;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _NavigationDestinationButton({
    required this.destination,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_NavigationDestinationButton> createState() =>
      _NavigationDestinationButtonState();
}

class _NavigationDestinationButtonState
    extends State<_NavigationDestinationButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final destination = widget.destination;
    final selected = widget.selected;
    final compact = widget.compact;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: Tooltip(
        message: destination.label,
        excludeFromSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('bottom-nav-${destination.id}'),
            onTap: widget.onTap,
            onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
            // Same shape as the sliding indicator, so the ripple never
            // spills past the bar's rounded ends.
            customBorder: const StadiumBorder(),
            splashColor: context.appColors.accent.withValues(alpha: 0.16),
            highlightColor: context.appColors.accent.withValues(alpha: 0.08),
            child: AnimatedScale(
              scale: _pressed ? 0.94 : 1,
              duration: const Duration(milliseconds: 110),
              curve: Curves.easeOut,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // A fixed icon size scaled up when selected, so the
                    // label below never jumps.
                    AnimatedScale(
                      scale: selected ? 1.1 : 1,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        selected ? destination.selectedIcon : destination.icon,
                        color: selected
                            ? context.appColors.accent
                            : context.appColors.secondaryText,
                        size: compact ? 21 : 23,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        style: TextStyle(
                          color: selected
                              ? context.appColors.accent
                              : context.appColors.primaryText,
                          fontSize: compact ? 9.5 : 10.5,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w500,
                          fontFamily: 'NotoSansEthiopic',
                        ),
                        child: Text(destination.label, maxLines: 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryNavigationAction extends StatefulWidget {
  final AppNavigationDestination destination;
  final bool selected;
  final double diameter;
  final bool compact;
  final VoidCallback onTap;

  const _PrimaryNavigationAction({
    required this.destination,
    required this.selected,
    required this.diameter,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_PrimaryNavigationAction> createState() =>
      _PrimaryNavigationActionState();
}

class _PrimaryNavigationActionState extends State<_PrimaryNavigationAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final destination = widget.destination;
    final selected = widget.selected;
    final diameter = widget.diameter;
    final compact = widget.compact;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          key: ValueKey('bottom-nav-${destination.id}'),
          onTap: widget.onTap,
          onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
          radius: (diameter / 2) + 8,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: _pressed ? 0.92 : (selected ? 1 : 0.96),
                duration: Duration(milliseconds: _pressed ? 90 : 180),
                curve: Curves.easeOut,
                child: Material(
                  color: context.appColors.accentDark,
                  elevation: selected ? 10 : 7,
                  shadowColor:
                      context.appColors.accentDark.withValues(alpha: 0.34),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox.square(
                    dimension: diameter,
                    child: Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      color: Colors.white,
                      size: compact ? 28 : 31,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    style: TextStyle(
                      color: selected
                          ? context.appColors.accent
                          : context.appColors.primaryText,
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'NotoSansEthiopic',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
