// lib/core/widgets/empty_state_widget.dart
import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/widgets/app_text_scope.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';

/// Reusable empty state widget with icon, title, and message
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final double iconSize;

  /// Left unset, the palette's accent is used.
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.iconSize = 64,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = FontSizeScope.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: GlassContainer(
          borderRadius: 16.0,
          blurSigma: 12.0,
          opacity: context.appColors.glassOpacity,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: iconColor ?? context.appColors.accent,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  color: context.appColors.primaryText,
                  fontSize: fontSize * 1.1,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'NotoSansEthiopic',
                ),
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: TextStyle(
                    color: context.appColors.secondaryText,
                    fontSize: fontSize * 0.9,
                    fontFamily: 'NotoSansEthiopic',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable error state widget
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = FontSizeScope.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: GlassContainer(
          borderRadius: 16.0,
          blurSigma: 12.0,
          opacity: context.appColors.glassOpacity,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: context.appColors.accent,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color: context.appColors.primaryText,
                  fontSize: fontSize,
                  fontFamily: 'NotoSansEthiopic',
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appColors.accent,
                    foregroundColor: context.appColors.primaryText,
                  ),
                  child: const Text('እንደገና ይሞክሩ'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
