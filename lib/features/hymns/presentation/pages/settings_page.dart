// lib/features/hymns/presentation/pages/settings_page.dart

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:amharic_hymnal_app/core/widgets/app_background.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/services/font_size_service.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_version_service.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart';
import 'package:amharic_hymnal_app/core/services/screen_service.dart';
import 'package:amharic_hymnal_app/core/utils/nav_bar_constants.dart';
import 'package:amharic_hymnal_app/core/utils/responsive_layout.dart';
import 'package:amharic_hymnal_app/core/widgets/app_version_footer.dart';
import 'package:amharic_hymnal_app/core/widgets/font_size_preview.dart';
import 'package:amharic_hymnal_app/core/widgets/main_page_title_bar.dart';
import 'package:amharic_hymnal_app/core/widgets/settings_tiles.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/donate_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/appearance_settings.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/language_settings.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/offline_download_flow.dart';
import 'package:amharic_hymnal_app/features/settings/presentation/pages/report_bug_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  /// Where the privacy policy lives. The store listing points at the same
  /// page, so the two can never say different things.
  static final Uri privacyUri =
      Uri.parse('https://nawey99.github.io/amharic_hymnal_app/privacy.html');

  /// The donation page is held back until there is an account number to
  /// show: a page that says "to be added later" is worse than no page.
  /// One line here brings it back.
  static const bool donationsReady = false;

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
  bool _scrolledUnderTitle = false;
  bool _contributionUnlocked =
      sl<SettingsRepository>().isContributionUnlocked();
  late final HymnalVersionService _versionService;

  @override
  void initState() {
    super.initState();
    _versionService = sl<HymnalVersionService>();
    _versionService.addListener(_handleVersionCatalogChanged);
    unawaited(_versionService.refresh());
    _loadSettings();
  }

  @override
  void dispose() {
    _versionService.removeListener(_handleVersionCatalogChanged);
    super.dispose();
  }

  void _handleVersionCatalogChanged() {
    if (mounted) setState(() {});
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
    final compactLandscape = ResponsiveLayout.isCompactLandscape(context);
    final itemGap = compactLandscape ? 8.0 : 12.0;
    final sectionGap = compactLandscape ? 14.0 : 24.0;
    // The SafeArea below takes the system navigation inset, so it is left
    // out here to count it once.
    final bottomPadding = NavBarConstants.getBottomPadding(context) -
        MediaQuery.paddingOf(context).bottom;
    final availableVersions = [..._versionService.versions];
    if (!availableVersions.any((version) => version.id == _selectedVersion)) {
      availableVersions.add(HymnalVersions.byId(_selectedVersion));
    }

    return Container(
      decoration: appBackgroundDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              MainPageTitleBar(
                title: AppLocalizations.of(context)?.settingsTitle ?? 'ቅንብሮች',
                showDivider: _scrolledUnderTitle,
              ),
              Expanded(
                child: NotificationListener<ScrollUpdateNotification>(
                  onNotification: _handleScroll,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      compactLandscape ? 6 : 16,
                      16,
                      bottomPadding,
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
                        items: availableVersions
                            .map(
                              (version) => DropdownMenuItem(
                                value: version.id,
                                child: Text(version.label),
                              ),
                            )
                            .toList(growable: false),
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
                      const LanguageSettings(),
                      SizedBox(height: itemGap),
                      const AppearanceSettings(),
                      SizedBox(height: itemGap),
                      SettingsSliderTile(
                        title: AppLocalizations.of(context)?.fontSizeLabel ??
                            'Font Size',
                        // Ensure value is clamped before passing - SettingsSliderTile also clamps as extra safety
                        value: _fontSize.clamp(12.0, 30.0),
                        min: 12,
                        max: 30,
                        // Whole points: two readers on "17" should have
                        // the same text.
                        divisions: 18,
                        highlight:
                            _fontSize.clamp(12.0, 30.0).toStringAsFixed(0),
                        previewBuilder: (context, value) =>
                            FontSizePreview(fontSize: value),
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
                        title: AppLocalizations.of(context)
                                ?.backgroundImageLabel ??
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
                        title:
                            AppLocalizations.of(context)?.keepScreenOnLabel ??
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
                      if (!kIsWeb) ...[
                        SizedBox(height: itemGap),
                        OfflineDownloadTile(
                          mediaType: MediaType.sheetMusic,
                          version: _selectedVersion,
                        ),
                        SizedBox(height: itemGap),
                        OfflineDownloadTile(
                          mediaType: MediaType.audio,
                          version: _selectedVersion,
                        ),
                      ],
                      SizedBox(height: sectionGap),
                      _buildSectionTitle(
                          AppLocalizations.of(context)?.aboutSection ??
                              'ስለ መተግበሪያው'),
                      // For contributors only: shown after tapping the
                      // version at the foot of the page, so nobody leaves
                      // for GitHub by accident.
                      if (_contributionUnlocked) ...[
                        SettingsTile(
                          key: const ValueKey('contribution-tile'),
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
                      ],
                      if (SettingsPage.donationsReady) ...[
                        SettingsTile(
                          key: const ValueKey('donate-tile'),
                          icon: Icons.favorite,
                          title: AppLocalizations.of(context)?.donateLabel ??
                              'ይለግሱ',
                          description:
                              AppLocalizations.of(context)?.donateDescription ??
                                  'የዚህን መተግበሪያ ልማት ድጋፍ ያድርጉ',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const DonatePage()),
                            );
                          },
                        ),
                        SizedBox(height: itemGap),
                      ],
                      SettingsTile(
                        key: const ValueKey('privacy-tile'),
                        icon: Icons.privacy_tip_outlined,
                        title:
                            AppLocalizations.of(context)?.privacyPolicyLabel ??
                                'የግላዊነት ፖሊሲ',
                        description: AppLocalizations.of(context)
                                ?.privacyPolicyDescription ??
                            'መተግበሪያው ስለ መረጃዎ ምን እንደሚያደርግ',
                        onTap: _openPrivacyPolicy,
                      ),
                      SizedBox(height: itemGap),
                      SettingsTile(
                        key: const ValueKey('report-bug-tile'),
                        icon: Icons.bug_report,
                        title: AppLocalizations.of(context)?.reportBug ??
                            'የስህተት ጥቆማ',
                        description: AppLocalizations.of(context)
                                ?.reportBugDescription ??
                            'ችግር ወይም የማሻሻያ ሐሳብ ያሳውቁ',
                        onTap: () {
                          // Over the whole app: the floating navigation bar
                          // would otherwise cover the form's send button.
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => const ReportBugPage(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: sectionGap),
                      AppVersionFooter(
                        unlocked: _contributionUnlocked,
                        onUnlock: () => _setContributionUnlocked(true),
                        onHide: () => _setContributionUnlocked(false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _handleScroll(ScrollUpdateNotification notification) {
    if (notification.depth != 0) return false;
    final scrolled = notification.metrics.pixels > 0;
    if (scrolled != _scrolledUnderTitle) {
      setState(() => _scrolledUnderTitle = scrolled);
    }
    return false;
  }

  Future<void> _setContributionUnlocked(bool value) async {
    setState(() => _contributionUnlocked = value);
    await sl<SettingsRepository>().setContributionUnlocked(value);
  }

  Future<void> _openContributionLink() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: Text(
          AppLocalizations.of(context)?.openGitHubTitle ?? 'GitHub ይከፈት?',
          style: TextStyle(color: context.appColors.primaryText),
        ),
        content: Text(
          AppLocalizations.of(context)?.openGitHubBody ??
              'የመተግበሪያው ምንጭ ኮድ ከመተግበሪያው ውጭ በአሳሽ ይከፈታል።',
          style: TextStyle(color: context.appColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'ይቅር'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)?.open ?? 'ክፈት'),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;

    final opened = await launchUrl(
      _contributionUri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.gitHubOpenFailed ??
              'የGitHub ገጽ መክፈት አልተቻለም'),
        ),
      );
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final opened = await launchUrl(
      SettingsPage.privacyUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)?.privacyPolicyOpenFailed ??
                    'የግላዊነት ፖሊሲውን መክፈት አልተቻለም')),
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
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: context.appColors.primaryText,
        ),
      ),
    );
  }
}
