// lib/features/hymns/presentation/pages/support_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  Future<void> _copyToClipboard(
      BuildContext context, String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '$label ${AppLocalizations.of(context)?.copiedToClipboard ?? 'copied to clipboard'}'),
          backgroundColor: AppColors.accentGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Support',
          style: TextStyle(color: AppColors.primaryText),
        ),
      ),
      body: ListenableBuilder(
        listenable: BackgroundImageService(),
        builder: (context, _) {
          final bgService = BackgroundImageService();
          final settingsRepository = sl<SettingsRepository>();
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
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Spiritual text
                  GlassCard(
                    borderRadius: 16.0,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: AppColors.accentGreen,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'እንደ እግዚአብሔር ፈቃድ ይህ መተግበሪያ ነጻ ነው። ነገር ግን እንደ እርዳታ እና ድጋፍ ከፈለጉ እባክዎን ከዚህ በታች ያሉትን መለያዎች ይጠቀሙ።',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: settingsRepository.getFontSize(),
                            fontFamily: 'NotoSansEthiopic',
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'As God wills, this app is free. But if you would like to help and support, please use the accounts below.',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: settingsRepository.getFontSize() * 0.9,
                            fontFamily: 'NotoSansEthiopic',
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Wise account
                  GlassCard(
                    borderRadius: 16.0,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet,
                                color: AppColors.accentGreen, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'Wise Account',
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize:
                                    settingsRepository.getFontSize() * 1.2,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'NotoSansEthiopic',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildAccountDetail(
                          context,
                          'Account Name',
                          'Adventist Hymnal Support',
                          Icons.person,
                        ),
                        const SizedBox(height: 12),
                        _buildAccountDetail(
                          context,
                          'Email',
                          'support@adventisthymnal.example.com',
                          Icons.email,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Commercial Bank of Ethiopia account
                  GlassCard(
                    borderRadius: 16.0,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance,
                                color: AppColors.accentGreen, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'Commercial Bank of Ethiopia',
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize:
                                    settingsRepository.getFontSize() * 1.2,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'NotoSansEthiopic',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildAccountDetail(
                          context,
                          'Account Number',
                          '1234567890123',
                          Icons.numbers,
                        ),
                        const SizedBox(height: 12),
                        _buildAccountDetail(
                          context,
                          'Account Name',
                          'Adventist Hymnal Support',
                          Icons.person,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountDetail(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final settingsRepository = sl<SettingsRepository>();
    return InkWell(
      onTap: () => _copyToClipboard(context, value, label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.divider.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondaryText, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: settingsRepository.getFontSize() * 0.85,
                      fontFamily: 'NotoSansEthiopic',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: settingsRepository.getFontSize(),
                      fontWeight: FontWeight.w500,
                      fontFamily: 'NotoSansEthiopic',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.copy,
              color: AppColors.accentGreen,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
