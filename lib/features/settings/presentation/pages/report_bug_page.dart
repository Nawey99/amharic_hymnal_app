// lib/features/settings/presentation/pages/report_bug_page.dart
import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/features/settings/data/repositories/bug_report_repository_impl.dart';
import 'package:amharic_hymnal_app/features/settings/domain/repositories/bug_report_repository.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

class ReportBugPage extends StatefulWidget {
  const ReportBugPage({super.key});

  @override
  State<ReportBugPage> createState() => _ReportBugPageState();
}

class _ReportBugPageState extends State<ReportBugPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final BugReportRepository _bugReportRepository = BugReportRepositoryImpl();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submitBugReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final contactEmail = _contactController.text.trim();
    final settingsRepository = sl<SettingsRepository>();
    final diagnostics = {
      'selected_language': settingsRepository.getSelectedLanguage(),
      'selected_version': settingsRepository.getSelectedVersion(),
      'font_size': settingsRepository.getFontSize(),
      'background_image_enabled':
          settingsRepository.getBackgroundImageEnabled(),
      'keep_screen_on': settingsRepository.getKeepScreenOn(),
    };

    try {
      final result = await _bugReportRepository.submit(
        BugReportPayload(
          title: title,
          description: description,
          contactEmail: contactEmail.isEmpty ? null : contactEmail,
          diagnostics: diagnostics,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor:
                result.isSuccess ? AppColors.accentGreen : Colors.red,
            duration: Duration(seconds: result.submitted ? 2 : 3),
          ),
        );
      }
      if (result.isSuccess) {
        _titleController.clear();
        _descriptionController.clear();
        _contactController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit bug report. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BackgroundImageService(),
      builder: (context, _) => _buildPageContent(context),
    );
  }

  Widget _buildPageContent(BuildContext context) {
    final bgService = BackgroundImageService();
    final settingsRepository = sl<SettingsRepository>();

    return Container(
      decoration: _buildBackgroundDecoration(bgService),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)?.reportBug ?? 'Report Bug',
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassContainer(
                  borderRadius: 16,
                  blurSigma: 12,
                  opacity: 0.12,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Title',
                        style: TextStyle(
                          fontSize: settingsRepository.getFontSize() * 0.9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Semantics(
                        label: 'Bug report title',
                        textField: true,
                        hint: 'Enter bug title',
                        child: TextFormField(
                          controller: _titleController,
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: settingsRepository.getFontSize(),
                            fontFamily: 'NotoSansEthiopic',
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter bug title...',
                            hintStyle: TextStyle(
                              color: AppColors.tertiaryText,
                              fontSize: settingsRepository.getFontSize() * 0.9,
                            ),
                            filled: true,
                            fillColor: AppColors.surface.withValues(alpha: 0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.divider,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.divider,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.accentGreen,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            if (value.trim().length < 3) {
                              return 'Title must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassContainer(
                  borderRadius: 16,
                  blurSigma: 12,
                  opacity: 0.12,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Email (Optional)',
                        style: TextStyle(
                          fontSize: settingsRepository.getFontSize() * 0.9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _contactController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: settingsRepository.getFontSize(),
                          fontFamily: 'NotoSansEthiopic',
                        ),
                        decoration: InputDecoration(
                          hintText: 'you@example.com',
                          hintStyle: TextStyle(
                            color: AppColors.tertiaryText,
                            fontSize: settingsRepository.getFontSize() * 0.9,
                          ),
                          filled: true,
                          fillColor: AppColors.surface.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.divider,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.divider,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.accentGreen,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return null;
                          final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email);
                          return isValid ? null : 'Enter a valid email';
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassContainer(
                  borderRadius: 16,
                  blurSigma: 12,
                  opacity: 0.12,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: settingsRepository.getFontSize() * 0.9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Semantics(
                        label: 'Bug report description',
                        textField: true,
                        hint: 'Describe the bug in detail',
                        child: TextFormField(
                          controller: _descriptionController,
                          maxLines: 8,
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: settingsRepository.getFontSize(),
                            fontFamily: 'NotoSansEthiopic',
                          ),
                          decoration: InputDecoration(
                            hintText: 'Describe the bug in detail...',
                            hintStyle: TextStyle(
                              color: AppColors.tertiaryText,
                              fontSize: settingsRepository.getFontSize() * 0.9,
                            ),
                            filled: true,
                            fillColor: AppColors.surface.withValues(alpha: 0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.divider,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.divider,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.accentGreen,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a description';
                            }
                            if (value.trim().length < 10) {
                              return 'Description must be at least 10 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  label: 'Submit bug report',
                  button: true,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitBugReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        minimumSize: const Size(0, 48), // Minimum tap target
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Submit Bug Report',
                              style: TextStyle(
                                fontSize: settingsRepository.getFontSize(),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'NotoSansEthiopic',
                              ),
                            ),
                    ),
                  ),
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
              image: const AssetImage('assets/images/background.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.7),
                BlendMode.darken,
              ),
            )
          : null,
      color: bgService.isEnabled ? null : AppColors.primaryBackground,
    );
  }
}
