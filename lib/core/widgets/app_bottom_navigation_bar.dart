import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
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
    final primaryDiameter = compactLandscape ? 46.0 : (compact ? 54.0 : 58.0);
    final primarySlotWidth = compactLandscape ? 58.0 : (compact ? 68.0 : 74.0);
    final primaryIndex = destinations.indexWhere(
      (destination) => destination.id == primaryDestinationId,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compactLandscape ? 6 : 10),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(
          bottom: compactLandscape ? 4 : NavBarConstants.navBarBottomMargin,
        ),
        child: SizedBox(
          key: const ValueKey('app-bottom-navigation-bar'),
          height: surfaceHeight + raisedExtent,
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
                    color: AppColors.secondaryBackground.withValues(
                      alpha: 0.98,
                    ),
                    borderRadius: BorderRadius.circular(
                      compactLandscape ? 18 : 24,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.17),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.46),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: raisedExtent,
                left: 4,
                right: 4,
                bottom: 0,
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
              onTap: () => onDestinationSelected(index),
            ),
          ),
      ],
    );
  }
}

class _NavigationDestinationButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accentGreen.withValues(alpha: 0.13)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? AppColors.accentGreen.withValues(alpha: 0.36)
                      : Colors.transparent,
                  width: 0.8,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    color: selected
                        ? AppColors.accentGreen
                        : AppColors.secondaryText,
                    size: selected ? (compact ? 24 : 26) : (compact ? 21 : 23),
                  ),
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      style: TextStyle(
                        color: selected
                            ? AppColors.accentGreen
                            : AppColors.primaryText,
                        fontSize: compact ? 9.5 : 10.5,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w500,
                        fontFamily: 'NotoSansEthiopic',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryNavigationAction extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
          child: InkResponse(
            key: ValueKey('bottom-nav-${destination.id}'),
            onTap: onTap,
            radius: (diameter / 2) + 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: selected ? 1 : 0.96,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: Material(
                    color: selected
                        ? AppColors.accentGreenLight
                        : AppColors.accentGreen,
                    elevation: selected ? 10 : 7,
                    shadowColor: AppColors.accentGreen.withValues(alpha: 0.5),
                    shape: CircleBorder(
                      side: BorderSide(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.72)
                            : AppColors.accentGreenLight.withValues(alpha: 0.7),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    style: TextStyle(
                      color: selected
                          ? AppColors.accentGreenLight
                          : AppColors.primaryText,
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'NotoSansEthiopic',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
