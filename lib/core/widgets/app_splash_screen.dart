import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors.dart';

class AppSplashScreen extends StatelessWidget {
  final String message;

  const AppSplashScreen({
    super.key,
    this.message = 'መዝሙሮችን በማዘጋጀት ላይ...',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryBackground,
              AppColors.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.accentGreen.withValues(alpha: 0.38),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/images/favicon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              color: AppColors.accentGreen,
                              size: 48,
                            ),
                            Positioned(
                              right: 19,
                              bottom: 19,
                              child: Icon(
                                Icons.music_note_rounded,
                                color: AppColors.primaryText,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ውዳሴ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'NotoSansEthiopic',
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'የአማርኛ አድቬንቲስት መዝሙር',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'NotoSansEthiopic',
                    ),
                  ),
                  const SizedBox(height: 28),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                      fontFamily: 'NotoSansEthiopic',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
