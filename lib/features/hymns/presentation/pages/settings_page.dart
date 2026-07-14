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
import 'package:amharic_hymnal_app/core/utils/responsive_layout.dart';
import 'package:amharic_hymnal_app/core/widgets/main_page_title_bar.dart';
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
  static final Uri _contributionUri =
      Uri.parse('https://github.com/Nawey99/amharic_hymnal_app');

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
    final compactLandscape = ResponsiveLayout.isCompactLandscape(context);
    final itemGap = compactLandscape ? 8.0 : 12.0;
    final sectionGap = compactLandscape ? 14.0 : 24.0;

    return Container(
      decoration: _buildBackgroundDecoration(bgService),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              const MainPageTitleBar(title: 'ቅንብር'),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    compactLandscape ? 6 : 16,
                    16,
                    compactLandscape ? 10 : 16,
                  ),
                  children: [
                    _buildSectionTitle(
                        AppLocalizations.of(context)?.contentSection ??
                            'Content'),
                    SettingsDropdownTile(
                      title: AppLocalizations.of(context)?.languageLabel ??
                          'Language',
                      description:
                          AppLocalizations.of(context)?.languageDescription ??
                              'Select the language for hymns',
                      value: _selectedLanguage,
                      items: [
                        DropdownMenuItem(
                          value: 'am',
                          child: Text(
                              AppLocalizations.of(context)?.amharicLanguage ??
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
                        if (value != null && value != _selectedLanguage) {
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
                    SizedBox(height: itemGap),
                    SettingsDropdownTile(
                      title: AppLocalizations.of(context)?.versionLabel ??
                          'Version',
                      description:
                          AppLocalizations.of(context)?.versionDescription ??
                              'Select hymnal version',
                      value: _selectedVersion,
                      items: [
                        DropdownMenuItem(
                          value: HymnalVersions.sdaNew,
                          child: Text(
                            HymnalVersions.newHymnal.label,
                          ),
                        ),
                        DropdownMenuItem(
                          value: HymnalVersions.sdaOld,
                          child: Text(
                            HymnalVersions.oldHymnal.label,
                          ),
                        ),
                        DropdownMenuItem(
                          value: HymnalVersions.hagerigna,
                          child: Text(
                            HymnalVersions.hagerignaSongs.label,
                          ),
                        ),
                      ],
                      onChanged: (value) async {
                        if (value != null && value != _selectedVersion) {
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
                    SizedBox(height: sectionGap),
                    _buildSectionTitle(
                        AppLocalizations.of(context)?.displaySection ??
                            'Display'),
                    SettingsSliderTile(
                      title: AppLocalizations.of(context)?.fontSizeLabel ??
                          'Font Size',
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
                    SizedBox(height: itemGap),
                    SettingsSwitchTile(
                      title:
                          AppLocalizations.of(context)?.backgroundImageLabel ??
                              'Background Image',
                      description: AppLocalizations.of(context)
                              ?.backgroundImageDescription ??
                          'Show background image in hymn view',
                      value: _backgroundImageEnabled,
                      onChanged: (value) async {
                        final repo = sl<SettingsRepository>();
                        await repo.setBackgroundImageEnabled(value);

                        await BackgroundImageService().setEnabled(value);

                        setState(() => _backgroundImageEnabled = value);
                      },
                    ),
                    SizedBox(height: sectionGap),
                    _buildSectionTitle(
                        AppLocalizations.of(context)?.generalSection ??
                            'General'),
                    SettingsSwitchTile(
                      title: AppLocalizations.of(context)?.keepScreenOnLabel ??
                          'Keep Screen On',
                      description: AppLocalizations.of(context)
                              ?.keepScreenOnDescription ??
                          'Prevent screen from turning off',
                      value: _keepScreenOn,
                      onChanged: (value) async {
                        final repo = sl<SettingsRepository>();
                        await repo.setKeepScreenOn(value);

                        await ScreenService.updateKeepScreenOn(value);

                        setState(() => _keepScreenOn = value);
                      },
                    ),
                    SizedBox(height: sectionGap),
                    _buildSectionTitle('ስለ መተግበሪያው'),
                    SettingsTile(
                      icon: Icons.code,
                      title: AppLocalizations.of(context)
                              ?.developmentContributionLabel ??
                          'ልማት እና አስተዋፅዖ',
                      description: AppLocalizations.of(context)
                              ?.developmentContributionDescription ??
                          'የምንጭ ኮድ ይመልከቱ እና ይሳተፉ',
                      onTap: _openContributionLink,
                    ),
                    SizedBox(height: itemGap),
                    SettingsTile(
                      icon: Icons.favorite,
                      title:
                          AppLocalizations.of(context)?.donateLabel ?? 'ይለግሱ',
                      description:
                          AppLocalizations.of(context)?.donateDescription ??
                              'የዚህን መተግበሪያ ልማት ድጋፍ ያድርጉ',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DonatePage()),
                        );
                      },
                    ),
                    SizedBox(height: itemGap),
                    SettingsTile(
                      icon: Icons.bug_report,
                      title:
                          AppLocalizations.of(context)?.reportBug ?? 'ስህተት ላክ',
                      description: 'ችግር ወይም የማሻሻያ ሐሳብ ያሳውቁ',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ReportBugPage()),
                        );
                      },
                    ),
                  ],
                ),
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

  Future<void> _openContributionLink() async {
    final opened = await launchUrl(
      _contributionUri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('የGitHub ገጽ መክፈት አልተቻለም'),
        ),
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    final compactLandscape = ResponsiveLayout.isCompactLandscape(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: compactLandscape ? 7 : 12,
        top: compactLandscape ? 3 : 8,
      ),
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
