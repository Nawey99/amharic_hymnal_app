// lib/features/hymns/presentation/pages/donate_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          child: ListView(
            padding: const EdgeInsets.all(16),
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
                'Coming soon',
                Icons.payment,
                _DonationAction.paypal,
              ),
              const SizedBox(height: 12),
              _buildDonateOption(
                context,
                'National Bank',
                'Bank transfer details',
                Icons.account_balance,
                _DonationAction.bank,
              ),
            ],
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
    _DonationAction action,
  ) {
    return GlassContainer(
      borderRadius: 16.0,
      blurSigma: 12.0,
      opacity: 0.12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: () async {
          if (action == _DonationAction.paypal) {
            await showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('PayPal'),
                content: const Text('PayPal donations are coming soon.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NationalBankDonationPage(),
            ),
          );
        },
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

enum _DonationAction { paypal, bank }

class NationalBankDonationPage extends StatelessWidget {
  const NationalBankDonationPage({super.key});

  static const _fields = [
    ('Bank', 'National Bank of Ethiopia'),
    ('Account Name', 'Wudase App Support'),
    ('Account Number', 'To be provided'),
    ('Branch', 'To be provided'),
  ];

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
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('National Bank'),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const GlassContainer(
                    borderRadius: 16,
                    blurSigma: 12,
                    opacity: 0.12,
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Bank transfer details are prepared here so they can be enabled when the official account is ready.',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final field in _fields) ...[
                    _BankField(label: field.$1, value: field.$2),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BankField extends StatelessWidget {
  final String label;
  final String value;

  const _BankField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 14,
      blurSigma: 12,
      opacity: 0.12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy, color: AppColors.accentGreen),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label copied')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
