// lib/features/hymns/presentation/pages/feedback_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _feedbackType = 'bug';

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.pleaseEnterFeedback ??
              'Please enter your feedback'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // In a real app, you would send this to a backend
    // For now, we'll show a success message
    final feedback = '''
Feedback Type: $_feedbackType
Email: ${_emailController.text}
Feedback: ${_feedbackController.text}
''';

    // Copy to clipboard as a fallback
    await Clipboard.setData(ClipboardData(text: feedback));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.feedbackCopied ??
              'Feedback copied to clipboard. Thank you!'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

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
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'Feedback',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontFamily: 'NotoSansEthiopic',
                ),
              ),
              iconTheme: const IconThemeData(color: AppColors.primaryText),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Feedback type selector
                    const Text(
                      'Feedback Type',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoSansEthiopic',
                      ),
                    ),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text(
                              'Bug Report',
                              style: TextStyle(color: AppColors.primaryText),
                            ),
                            value: 'bug',
                            groupValue: _feedbackType,
                            onChanged: (value) {
                              setState(() => _feedbackType = value!);
                            },
                            activeColor: AppColors.accentGreen,
                          ),
                          RadioListTile<String>(
                            title: const Text(
                              'Feature Request',
                              style: TextStyle(color: AppColors.primaryText),
                            ),
                            value: 'feature',
                            groupValue: _feedbackType,
                            onChanged: (value) {
                              setState(() => _feedbackType = value!);
                            },
                            activeColor: AppColors.accentGreen,
                          ),
                          RadioListTile<String>(
                            title: const Text(
                              'General Feedback',
                              style: TextStyle(color: AppColors.primaryText),
                            ),
                            value: 'general',
                            groupValue: _feedbackType,
                            onChanged: (value) {
                              setState(() => _feedbackType = value!);
                            },
                            activeColor: AppColors.accentGreen,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Email (optional)
                    const Text(
                      'Email (Optional)',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoSansEthiopic',
                      ),
                    ),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppColors.primaryText),
                        decoration: const InputDecoration(
                          hintText: 'your.email@example.com',
                          hintStyle: TextStyle(color: AppColors.tertiaryText),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Feedback text
                    const Text(
                      'Your Feedback',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoSansEthiopic',
                      ),
                    ),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: TextField(
                        controller: _feedbackController,
                        maxLines: 8,
                        style: const TextStyle(color: AppColors.primaryText),
                        decoration: const InputDecoration(
                          hintText:
                              'Describe your feedback, bug, or feature request...',
                          hintStyle: TextStyle(color: AppColors.tertiaryText),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        onPressed: _submitFeedback,
                        child: const Text(
                          'Submit Feedback',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NotoSansEthiopic',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
