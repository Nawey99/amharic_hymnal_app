import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/utils/responsive_layout.dart';

class MainPageTitleBar extends StatelessWidget {
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
                ? Colors.white.withValues(alpha: 0.14)
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
            : Row(
                children: [
                  SizedBox(
                    width: sideWidth,
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
                    width: sideWidth,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions,
                      ),
                    ),
                  ),
                ],
              ),
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
            fontFamily: 'NotoSansEthiopic',
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}
