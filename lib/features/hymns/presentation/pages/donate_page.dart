// lib/features/hymns/presentation/pages/donate_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/utils/nav_bar_constants.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
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
      decoration: _buildBackgroundDecoration(context, bgService),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)?.donateTitle ?? 'ይለግሱ'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              NavBarConstants.getBottomPadding(context),
            ),
            children: [
              GlassContainer(
                borderRadius: 16.0,
                blurSigma: 12.0,
                opacity: 0.12,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: context.appColors.accent,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'መተግበሪያውን ይደግፉ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: context.appColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ድጋፍዎ ይህን መተግበሪያ ለማሻሻል እና ለማስቀጠል ይረዳናል። ለድጋፍዎ እናመሰግናለን።',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: context.appColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildDonateOption(
                context,
                'PayPal',
                'በቅርቡ ይጀምራል',
                Icons.payment,
                _DonationAction.paypal,
              ),
              const SizedBox(height: 12),
              _buildDonateOption(
                context,
                'በባንክ ማስተላለፊያ',
                'የባንክ ማስተላለፊያ መረጃ',
                Icons.account_balance,
                _DonationAction.bank,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration(
    BuildContext context,
    BackgroundImageService bgService,
  ) {
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
      color: bgService.isEnabled ? null : context.appColors.primaryBackground,
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
                content: const Text('የPayPal ድጋፍ በቅርቡ ይጀምራል።'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('እሺ'),
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
              color: context.appColors.accent,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.appColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.appColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: context.appColors.secondaryText,
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
    ('ባንክ', 'የኢትዮጵያ ንግድ ባንክ'),
    ('የባንክ ሒሳብ ስም', 'Filowha Seventh Day Adventist Church'),
    ('የሒሳብ ቁጥር', 'በኋላ ይጨመራል'),
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
            color: bgService.isEnabled
                ? null
                : context.appColors.primaryBackground,
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('በባንክ ማስተላለፊያ'),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: SafeArea(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  NavBarConstants.getBottomPadding(context),
                ),
                children: [
                  GlassContainer(
                    borderRadius: 16,
                    blurSigma: 12,
                    opacity: 0.12,
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'ይህ ገጽ የባንክ ድጋፍ መረጃ ለማሳየት ተዘጋጅቷል። ትክክለኛው የባንክ ሒሳብ ቁጥር ሲዘጋጅ መረጃው ይሞላል።',
                      style: TextStyle(
                        color: context.appColors.secondaryText,
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
    final canCopy = label == 'የሒሳብ ቁጥር';
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
                  style: TextStyle(
                    color: context.appColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: context.appColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (canCopy)
            IconButton(
              tooltip: 'ቅዳ',
              icon: Icon(Icons.copy, color: context.appColors.accent),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('የሒሳብ ቁጥሩ ተቀድቷል')),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}
