// lib/core/widgets/loading_widget.dart
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

/// Loading widget for app initialization
class AppLoadingWidget extends StatelessWidget {
  final String? message;

  const AppLoadingWidget({
    super.key,
    this.message,
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
            child: GlassCard(
              borderRadius: 16.0,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentGreen,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        message!,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 16,
                          fontFamily: 'NotoSansEthiopic',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
