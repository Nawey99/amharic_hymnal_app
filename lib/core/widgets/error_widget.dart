// lib/core/widgets/error_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';

bool _hasBackgroundImage() {
  try {
    rootBundle.load('assets/images/background.jpg');
    return true;
  } catch (_) {
    return false;
  }
}

/// Custom error widget for better error display
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          image: _hasBackgroundImage()
              ? DecorationImage(
                  image: const AssetImage('assets/images/background.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.8),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: GlassCard(
                borderRadius: 16.0,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Oops! Something went wrong',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSansEthiopic',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 16,
                          fontFamily: 'NotoSansEthiopic',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (onRetry != null) ...[
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: onRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGreen,
                            foregroundColor: AppColors.primaryText,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(
                              fontFamily: 'NotoSansEthiopic',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
