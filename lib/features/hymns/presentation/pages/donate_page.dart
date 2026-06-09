// lib/features/hymns/presentation/pages/donate_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';

class DonatePage extends StatelessWidget {
  const DonatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BackgroundImageService(),
      builder: (context, _) => _buildPageContent(context),
    );
  }

  Widget _buildPageContent(BuildContext context) {
    final bgService = BackgroundImageService();
    return Container(
      decoration: _buildBackgroundDecoration(bgService),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)?.donateTitle ?? 'Donate'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const GlassContainer(
                  borderRadius: 16.0,
                  blurSigma: 12.0,
                  opacity: 0.12,
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: AppColors.accentGreen,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Support This App',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Your support helps us continue developing and improving this app. Thank you for your generosity!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildDonateOption(
                  context,
                  'PayPal',
                  'Donate via PayPal',
                  Icons.payment,
                  'https://paypal.me/example',
                ),
                const SizedBox(height: 12),
                _buildDonateOption(
                  context,
                  'Bank Transfer',
                  'Direct bank transfer',
                  Icons.account_balance,
                  null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration(BackgroundImageService bgService) {
    return BoxDecoration(
      image: bgService.isEnabled
          ? DecorationImage(
              image: _getBackgroundImage(),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.8),
                BlendMode.darken,
              ),
            )
          : null,
      color: bgService.isEnabled ? null : AppColors.primaryBackground,
    );
  }

  AssetImage _getBackgroundImage() {
    return const AssetImage('assets/images/background.jpg');
  }

  Widget _buildDonateOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String? url,
  ) {
    return GlassContainer(
      borderRadius: 16.0,
      blurSigma: 12.0,
      opacity: 0.12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: url != null
            ? () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            : null,
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.accentGreen,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (url != null)
              const Icon(
                Icons.chevron_right,
                color: AppColors.secondaryText,
              ),
          ],
        ),
      ),
    );
  }
}
