import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/utils/responsive_layout.dart';

class MainPageTitleBar extends StatelessWidget {
  /// Room the title keeps before the sides give way. The title scales down
  /// to fit (FittedBox); 24 is what it already had on a 360-wide phone, so
  /// screens that size and up look as before and only narrower ones change.
  static const double _minTitleWidth = 24;

  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final double sideWidth;

  /// Shows a hairline under the bar, for when content has scrolled beneath
  /// it, so cut-off content has an edge to sit against.
  final bool showDivider;

  const MainPageTitleBar({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
    this.sideWidth = 96,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final compactLandscape = ResponsiveLayout.isCompactLandscape(context);
    return AnimatedContainer(
      key: const ValueKey('title-bar-divider'),
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: showDivider
                ? context.appColors.veil.withValues(alpha: 0.14)
                : Colors.transparent,
            width: 0.5,
          ),
        ),
      ),
      child: _buildBar(compactLandscape),
    );
  }

  Widget _buildBar(bool compactLandscape) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        compactLandscape ? 2 : 8,
        16,
        compactLandscape ? 2 : 8,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compactLandscape ? 8 : 12,
          vertical: compactLandscape ? 2 : 6,
        ),
        child: leading == null
            ? Row(
                children: [
                  Expanded(
                    child: _TitleText(
                      title,
                      compact: compactLandscape,
                    ),
                  ),
                  ...actions,
                ],
              )
            : LayoutBuilder(builder: (context, constraints) {
                // Each side gets [sideWidth] when there is room, and the
                // title always keeps [_minTitleWidth]. On a narrow phone two
                // 140 dp sides are wider than the bar itself; there the
                // sides give way (the History label ellipsizes) rather than
                // the row overflowing.
                final side = math.min(
                  sideWidth,
                  math.max(0.0, (constraints.maxWidth - _minTitleWidth) / 2),
                );
                return Row(
                  children: [
                    SizedBox(
                      width: side,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: leading,
                      ),
                    ),
                    Expanded(
                      child: _TitleText(
                        title,
                        compact: compactLandscape,
                      ),
                    ),
                    SizedBox(
                      width: side,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions,
                        ),
                      ),
                    ),
                  ],
                );
              }),
      ),
    );
  }
}

class _TitleText extends StatelessWidget {
  final String title;
  final bool compact;

  const _TitleText(this.title, {required this.compact});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          title,
          style: TextStyle(
            color: context.appColors.primaryText,
            fontSize: compact ? 21 : 23,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}
