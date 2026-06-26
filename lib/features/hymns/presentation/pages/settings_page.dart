// lib/features/hymns/presentation/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/services/font_size_service.dart';
import 'package:amharic_hymnal_app/core/services/screen_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/settings_tiles.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/donate_page.dart';
import 'package:amharic_hymnal_app/features/settings/presentation/pages/report_bug_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'am';
  String _selectedVersion = HymnalVersions.sdaNew;
  double _fontSize = 20.0;
  bool _backgroundImageEnabled = true;
  bool _keepScreenOn = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final settingsRepository = sl<SettingsRepository>();

    // Get font size - SettingsService.getFontSize() now clamps automatically
    // But add extra safety by clamping again here
    var fontSize = settingsRepository.getFontSize();
    var clampedFontSize = fontSize.clamp(12.0, 30.0);

    // CRITICAL: If font size was out of range, fix it IMMEDIATELY before setting state
    if ((fontSize - clampedFontSize).abs() > 0.01 ||
        fontSize > 30.0 ||
        fontSize < 12.0) {
      // Fix the stored value synchronously if possible, or asynchronously
      clampedFontSize = fontSize.clamp(12.0, 30.0);
      // Update stored value immediately to fix the corruption
      await settingsRepository.setFontSize(clampedFontSize);
      await FontSizeService().setFontSize(clampedFontSize);
      // Update local variable to use clamped value
      fontSize = clampedFontSize;
    } else {
      // Even if in range, sync with FontSizeService to ensure consistency
      await FontSizeService().setFontSize(clampedFontSize);
    }

    // Final safety check - ensure clampedFontSize is definitely in range
    clampedFontSize = fontSize.clamp(12.0, 30.0);

    if (mounted) {
      setState(() {
        _selectedLanguage = settingsRepository.getSelectedLanguage();
        _selectedVersion = settingsRepository.getSelectedVersion();
        // ALWAYS use clamped value to prevent slider assertion errors
        _fontSize = clampedFontSize;
        _backgroundImageEnabled =
            settingsRepository.getBackgroundImageEnabled();
        _keepScreenOn = settingsRepository.getKeepScreenOn();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to both BackgroundImageService and FontSizeService for real-time updates
    return ListenableBuilder(
      listenable: BackgroundImageService(),
      builder: (context, _) {
        // Also listen to FontSizeService for font size updates
        return ListenableBuilder(
          listenable: FontSizeService(),
          builder: (context, _) {
            // Sync font size from service to ensure it's always in valid range
            final fontSizeService = FontSizeService();
            // FontSizeService.getFontSize() already clamps, but add extra safety
            final currentFontSize =
                fontSizeService.getFontSize().clamp(12.0, 30.0);
            // Update state if font size changed (will be clamped)
            if ((currentFontSize - _fontSize).abs() > 0.01) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    // Always clamp to prevent any possibility of out-of-range value
                    _fontSize = currentFontSize.clamp(12.0, 30.0);
                  });
                }
              });
            }
            return _buildPageContent(context);
          },
        );
      },
    );
  }

  Widget _buildPageContent(BuildContext context) {
    final bgService = BackgroundImageService();

    return Container(
      decoration: _buildBackgroundDecoration(bgService),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)?.settingsTitle ?? 'ቅንብር'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle(
                  AppLocalizations.of(context)?.contentSection ?? 'Content'),
              SettingsDropdownTile(
                title:
                    AppLocalizations.of(context)?.languageLabel ?? 'Language',
                description:
                    AppLocalizations.of(context)?.languageDescription ??
                        'Select the language for hymns',
                value: _selectedLanguage,
                items: [
                  DropdownMenuItem(
                    value: 'am',
                    child: Text(AppLocalizations.of(context)?.amharicLanguage ??
                        'Amharic'),
                  ),
                  // Future languages can be added here
                  // DropdownMenuItem(
                  //   value: 'en',
                  //   child: Text(AppLocalizations.of(context)?.englishLanguage ??
                  //       'English'),
                  // ),
                ],
                onChanged: (value) async {
                  if (value != null) {
                    final repo = sl<SettingsRepository>();
                    final bloc = context.read<HymnsBloc>();
                    await repo.setSelectedLanguage(value);

                    if (!mounted) return;
                    setState(() => _selectedLanguage = value);

                    if (mounted) {
                      bloc.add(
                        ChangeLanguage(
                          _selectedLanguage,
                          _selectedVersion,
                          repo.getSortType(),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              SettingsDropdownTile(
                title: AppLocalizations.of(context)?.versionLabel ?? 'Version',
                description: AppLocalizations.of(context)?.versionDescription ??
                    'Select hymnal version',
                value: _selectedVersion,
                items: [
                  const DropdownMenuItem(
                    value: HymnalVersions.sdaNew,
                    child: Text('አዲስ የአድቬንቲስት መዝሙር'),
                  ),
                  const DropdownMenuItem(
                    value: HymnalVersions.sdaOld,
                    child: Text('ቀድሞ የአድቬንቲስት መዝሙር'),
                  ),
                  DropdownMenuItem(
                    value: HymnalVersions.hagerigna,
                    child: Text(
                        AppLocalizations.of(context)?.hagerigna ?? 'Hagerigna'),
                  ),
                ],
                onChanged: (value) async {
                  if (value != null) {
                    final repo = sl<SettingsRepository>();
                    final bloc = context.read<HymnsBloc>();
                    await repo.setSelectedVersion(value);

                    if (!mounted) return;
                    setState(() => _selectedVersion = value);

                    if (mounted) {
                      bloc.add(
                        ChangeVersion(
                          _selectedLanguage,
                          _selectedVersion,
                          repo.getSortType(),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(
                  AppLocalizations.of(context)?.displaySection ?? 'Display'),
              SettingsSliderTile(
                title:
                    AppLocalizations.of(context)?.fontSizeLabel ?? 'Font Size',
                // Ensure value is clamped before passing - SettingsSliderTile also clamps as extra safety
                value: _fontSize.clamp(12.0, 30.0),
                min: 12,
                max: 30,
                highlight: _fontSize.clamp(12.0, 30.0).toStringAsFixed(0),
                onChanged: (value) async {
                  // Clamp value to valid range before any operations
                  final clampedValue = value.clamp(12.0, 30.0);
                  // Update repository first (it also clamps internally)
                  final repo = sl<SettingsRepository>();
                  await repo.setFontSize(clampedValue);
                  // Notify FontSizeService for real-time updates (it also clamps internally)
                  await FontSizeService().setFontSize(clampedValue);
                  // Update state with clamped value
                  if (mounted) {
                    setState(() {
                      _fontSize = clampedValue.clamp(12.0, 30.0);
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              SettingsSwitchTile(
                title: AppLocalizations.of(context)?.backgroundImageLabel ??
                    'Background Image',
                description:
                    AppLocalizations.of(context)?.backgroundImageDescription ??
                        'Show background image in hymn view',
                value: _backgroundImageEnabled,
                onChanged: (value) async {
                  final repo = sl<SettingsRepository>();
                  await repo.setBackgroundImageEnabled(value);

                  await BackgroundImageService().setEnabled(value);

                  setState(() => _backgroundImageEnabled = value);
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(
                  AppLocalizations.of(context)?.generalSection ?? 'General'),
              SettingsSwitchTile(
                title: AppLocalizations.of(context)?.keepScreenOnLabel ??
                    'Keep Screen On',
                description:
                    AppLocalizations.of(context)?.keepScreenOnDescription ??
                        'Prevent screen from turning off',
                value: _keepScreenOn,
                onChanged: (value) async {
                  final repo = sl<SettingsRepository>();
                  await repo.setKeepScreenOn(value);

                  await ScreenService.updateKeepScreenOn(value);

                  setState(() => _keepScreenOn = value);
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('ስለ መተግበሪያው'),
              SettingsTile(
                icon: Icons.code,
                title: AppLocalizations.of(context)
                        ?.developmentContributionLabel ??
                    'ልማት እና አስተዋፅዖ',
                description: AppLocalizations.of(context)
                        ?.developmentContributionDescription ??
                    'የምንጭ ኮድ ይመልከቱ እና ይሳተፉ',
                onTap: () async {
                  final uri = Uri.parse(
                      'https://github.com/Nawey99/amharic_hymnal_app');

                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('የGitHub ገጽ መክፈት አልተቻለም'),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              SettingsTile(
                icon: Icons.favorite,
                title: AppLocalizations.of(context)?.donateLabel ?? 'ይለግሱ',
                description: AppLocalizations.of(context)?.donateDescription ??
                    'የዚህን መተግበሪያ ልማት ድጋፍ ያድርጉ',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DonatePage()),
                  );
                },
              ),
              const SizedBox(height: 12),
              SettingsTile(
                icon: Icons.bug_report,
                title: AppLocalizations.of(context)?.reportBug ?? 'ስህተት ላክ',
                description: 'ችግር ወይም የማሻሻያ ሐሳብ ያሳውቁ',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportBugPage()),
                  );
                },
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
              image: const AssetImage('assets/images/background.jpg'),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText,
        ),
      ),
    );
  }
}
