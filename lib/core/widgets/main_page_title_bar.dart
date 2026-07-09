import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';

class MainPageTitleBar extends StatelessWidget {
  static const double _actionSlotWidth = 48.0;
  static const int _reservedActionSlots = 2;
  static const TextStyle titleStyle = TextStyle(
    color: AppColors.primaryText,
    fontSize: 23,
    fontWeight: FontWeight.w700,
    fontFamily: 'NotoSansEthiopic',
    height: 1.2,
    letterSpacing: 0,
  );

  final String title;
  final List<Widget> actions;

  const MainPageTitleBar({
    super.key,
    required this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    const reservedActionsWidth = _actionSlotWidth * _reservedActionSlots;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: GlassContainer(
        borderRadius: 16.0,
        blurSigma: 12.0,
        opacity: 0.15,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            const SizedBox(width: reservedActionsWidth),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: reservedActionsWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions.take(_reservedActionSlots).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
