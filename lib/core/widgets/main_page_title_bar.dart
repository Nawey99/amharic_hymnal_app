import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';

class MainPageTitleBar extends StatelessWidget {
  final String title;
  final List<Widget> actions;

  const MainPageTitleBar({
    super.key,
    required this.title,
    this.actions = const [],
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
        child: Row(
          children: [
            Expanded(
              child: Center(
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
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}
