import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';

class MainPageTitleBar extends StatelessWidget {
  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final double sideWidth;

  const MainPageTitleBar({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
    this.sideWidth = 96,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: GlassContainer(
        borderRadius: 16.0,
        blurSigma: 12.0,
        opacity: 0.15,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: leading == null
            ? Row(
                children: [
                  Expanded(child: _TitleText(title)),
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
                  Expanded(child: _TitleText(title)),
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

  const _TitleText(this.title);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 23,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansEthiopic',
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}
