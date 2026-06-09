// lib/core/widgets/background_image_wrapper.dart
import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';

/// Wrapper widget that provides background image support consistently across pages
class BackgroundImageWrapper extends StatelessWidget {
  final Widget child;

  const BackgroundImageWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BackgroundImageService(),
      builder: (context, _) {
        final bgService = BackgroundImageService();
        return Container(
          decoration: BoxDecoration(
            image: bgService.isEnabled
                ? DecorationImage(
                    image: const AssetImage('assets/images/background.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.8),
                      BlendMode.darken,
                    ),
                  )
                : null,
            color: bgService.isEnabled ? null : AppColors.primaryBackground,
          ),
          child: child,
        );
      },
    );
  }
}

