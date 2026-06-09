// lib/core/widgets/empty_state_widget.dart
import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

/// Reusable empty state widget with icon, title, and message
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final double iconSize;
  final Color iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.iconSize = 64,
    this.iconColor = AppColors.accentGreen,
  });

  @override
  Widget build(BuildContext context) {
    final settingsRepository = sl<SettingsRepository>();
    final fontSize = settingsRepository.getFontSize();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: GlassContainer(
          borderRadius: 16.0,
          blurSigma: 12.0,
          opacity: 0.15,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: iconColor,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.primaryText,
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
                    color: AppColors.secondaryText,
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
    final settingsRepository = sl<SettingsRepository>();
    final fontSize = settingsRepository.getFontSize();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: GlassContainer(
          borderRadius: 16.0,
          blurSigma: 12.0,
          opacity: 0.15,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.accentGreen,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color: AppColors.primaryText,
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
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: AppColors.primaryText,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

