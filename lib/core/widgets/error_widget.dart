// lib/core/widgets/error_widget.dart
import 'package:flutter/material.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/widgets/app_background.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';

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
      backgroundColor: context.appColors.primaryBackground,
      body: Container(
        decoration: appBackgroundDecoration(context),
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
                      Text(
                        'ይቅርታ! የሆነ ችግር ተከስቷል',
                        style: TextStyle(
                          color: context.appColors.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSansEthiopic',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        style: TextStyle(
                          color: context.appColors.secondaryText,
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
                            backgroundColor: context.appColors.accent,
                            foregroundColor: context.appColors.primaryText,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: const Text(
                            'እንደገና ይሞክሩ',
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
