// lib/features/hymns/presentation/pages/onboarding_page.dart
import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/widgets/app_background.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/models/onboarding_content.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/main_navigation_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  /// Rebuilt with the page, so switching language switches these too.
  List<OnboardingStep> get _steps =>
      OnboardingContent.stepsFor(AppLocalizations.of(context));

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    try {
      final settingsRepository = sl<SettingsRepository>();
      await settingsRepository.setOnboardingCompleted(true);
      // Asked once the edition has loaded; see maybeOfferOfflineDownloads.
      await settingsRepository.setOfflineDownloadOfferPending(true);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)?.errorOccurred ?? 'ስህተት'} ${e.toString()}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BackgroundImageService(),
      builder: (context, _) {
        return Container(
          decoration: appBackgroundDecoration(context),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 700;
                  return Column(
                    children: [
                      _buildTopBar(compact),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() => _currentPage = index);
                          },
                          itemCount: _steps.length,
                          itemBuilder: (context, index) {
                            return _buildPage(_steps[index], compact);
                          },
                        ),
                      ),
                      _buildFooter(compact),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(bool compact) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, compact ? 8 : 14, 16, compact ? 4 : 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              // verbatim: the app's own name, which is not translated
              'ውዳሴ',
              style: TextStyle(
                color: context.appColors.primaryText,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: _completeOnboarding,
            style: TextButton.styleFrom(
              foregroundColor: context.appColors.primaryText,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)?.onboardSkip ?? 'ዝለል',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingStep step, bool compact) {
    final horizontalPadding = compact ? 14.0 : 20.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            compact ? 4 : 10,
            horizontalPadding,
            12,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
            child: Center(
              child: GlassContainer(
                borderRadius: 18,
                blurSigma: 12,
                opacity: context.appColors.glassOpacity,
                padding: EdgeInsets.all(compact ? 14 : 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FeaturePreview(step: step, compact: compact),
                    SizedBox(height: compact ? 12 : 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          step.icon,
                          color: context.appColors.accent,
                          size: compact ? 25 : 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            step.title,
                            style: TextStyle(
                              color: context.appColors.primaryText,
                              fontSize: compact ? 19 : 22,
                              fontWeight: FontWeight.w800,
                              height: 1.22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 8 : 10),
                    Text(
                      step.description,
                      style: TextStyle(
                        color: context.appColors.secondaryText,
                        fontSize: compact ? 13.3 : 15,
                        height: 1.42,
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 10),
                    _AccessCallout(text: step.access, compact: compact),
                    SizedBox(height: compact ? 10 : 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: step.bullets.map(_buildChip).toList(),
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

  Widget _buildChip(String item) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: context.appColors.accent.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          item,
          style: TextStyle(
            color: context.appColors.primaryText,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool compact) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 4, 18, compact ? 14 : 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _steps.length,
              (index) => _buildIndicator(index == _currentPage),
            ),
          ),
          SizedBox(height: compact ? 12 : 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (_currentPage < _steps.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                  );
                } else {
                  _completeOnboarding();
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: context.appColors.accent,
                foregroundColor: context.appColors.primaryText,
                padding: EdgeInsets.symmetric(vertical: compact ? 13 : 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Text(
                  _currentPage < _steps.length - 1
                      ? (AppLocalizations.of(context)?.onboardNext ?? 'ቀጣይ')
                      : (AppLocalizations.of(context)?.onboardStart ?? 'ጀምር'),
                  key: ValueKey(_currentPage == _steps.length - 1),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: isActive ? 22 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: isActive
            ? context.appColors.accent
            : context.appColors.secondaryText,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _FeaturePreview extends StatelessWidget {
  final OnboardingStep step;
  final bool compact;

  const _FeaturePreview({
    required this.step,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final preview = MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 12),
        child: switch (step.preview) {
          OnboardingPreview.library => _LibraryPreview(compact: compact),
          OnboardingPreview.number => _NumberPreview(compact: compact),
          OnboardingPreview.indexList => _IndexPreview(compact: compact),
          OnboardingPreview.categories => _CategoriesPreview(compact: compact),
          OnboardingPreview.lyrics => _LyricsPreview(compact: compact),
          OnboardingPreview.settings => _SettingsPreview(compact: compact),
        },
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appColors.primaryBackground.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: context.appColors.veil.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: compact ? 1.05 : 1.2,
          child: preview,
        ),
      ),
    );
  }
}

class _PreviewScaffold extends StatelessWidget {
  final String title;
  final IconData actionIcon;
  final Widget child;
  final String selectedTab;
  final bool compact;

  const _PreviewScaffold({
    required this.title,
    required this.actionIcon,
    required this.child,
    required this.selectedTab,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.appColors.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(actionIcon,
                color: context.appColors.primaryText, size: compact ? 16 : 18),
          ],
        ),
        SizedBox(height: compact ? 5 : 10),
        Expanded(child: child),
        SizedBox(height: compact ? 4 : 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavHint(
                icon: Icons.category_rounded,
                label: AppLocalizations.of(context)?.navCategory ?? 'ምድብ',
                active: selectedTab == 'ምድብ'),
            _NavHint(
                icon: Icons.list_alt_rounded,
                label: AppLocalizations.of(context)?.navIndex ?? 'ማውጫ',
                active: selectedTab == 'ማውጫ'),
            _NavHint(
                icon: Icons.numbers_rounded,
                label: AppLocalizations.of(context)?.navNumber ?? 'ቁጥር',
                active: selectedTab == 'ቁጥር'),
            _NavHint(
                icon: Icons.favorite_rounded,
                label: AppLocalizations.of(context)?.navFavorites ?? 'ተወዳጅ',
                active: selectedTab == 'ተወዳጅ'),
            _NavHint(
                icon: Icons.settings_rounded,
                label: AppLocalizations.of(context)?.navSettings ?? 'ቅንብሮች',
                active: selectedTab == 'ቅንብሮች'),
          ],
        ),
      ],
    );
  }
}

class _LibraryPreview extends StatelessWidget {
  final bool compact;

  const _LibraryPreview({required this.compact});

  @override
  Widget build(BuildContext context) {
    return _PreviewScaffold(
      // verbatim: the app's own name, shown in the little mock screen
      title: 'ውዳሴ',
      actionIcon: Icons.search_rounded,
      selectedTab: AppLocalizations.of(context)?.navNumber ?? 'ቁጥር',
      compact: compact,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MiniCard(
            icon: Icons.numbers_rounded,
            title: AppLocalizations.of(context)?.onboardPreviewByNumber ??
                'በቁጥር መክፈት',
            subtitle:
                AppLocalizations.of(context)?.onboardPreviewByNumberHint ??
                    'ቁጥሩን አስገብተው “ክፈት”ን ይንኩ',
            compact: compact,
          ),
          SizedBox(height: compact ? 6 : 8),
          _MiniCard(
            icon: Icons.search_rounded,
            title: AppLocalizations.of(context)?.onboardPreviewSearch ??
                'በማውጫ መፈለግ',
            subtitle: AppLocalizations.of(context)?.onboardPreviewSearchHint ??
                'በርዕስ ወይም በግጥም ቃላት',
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _NumberPreview extends StatelessWidget {
  final bool compact;

  const _NumberPreview({required this.compact});

  @override
  Widget build(BuildContext context) {
    return _PreviewScaffold(
      // verbatim: the app's own name, shown in the little mock screen
      title: 'ውዳሴ',
      actionIcon: Icons.history_rounded,
      selectedTab: AppLocalizations.of(context)?.navNumber ?? 'ቁጥር',
      compact: compact,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: compact ? 38 : 44,
            decoration: BoxDecoration(
              color: context.appColors.veil.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: context.appColors.veil.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Text('#',
                    style: TextStyle(
                        color: context.appColors.primaryText,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 16),
                Text('125',
                    style: TextStyle(
                        color: context.appColors.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: compact ? 34 : 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.appColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              AppLocalizations.of(context)?.open ?? 'ክፈት',
              style: TextStyle(
                color: context.appColors.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndexPreview extends StatelessWidget {
  final bool compact;

  const _IndexPreview({required this.compact});

  @override
  Widget build(BuildContext context) {
    return _PreviewScaffold(
      title: AppLocalizations.of(context)?.navIndex ?? 'ማውጫ',
      actionIcon: Icons.sort_rounded,
      selectedTab: AppLocalizations.of(context)?.navIndex ?? 'ማውጫ',
      compact: compact,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SongRow(
                  number: '1',
                  // verbatim: a hymn title, shown as the book prints it
                  title: 'አምላካችን',
                  subtitle: 'Praise God',
                  compact: compact,
                ),
                SizedBox(height: compact ? 5 : 7),
                _SongRow(
                  number: '40',
                  // verbatim: a hymn title, shown as the book prints it
                  title: 'እንኳን ላምልክ',
                  subtitle: 'O Worship the King',
                  compact: compact,
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          const Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RailLabel('1-50'),
              _RailLabel('101+'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoriesPreview extends StatelessWidget {
  final bool compact;

  const _CategoriesPreview({required this.compact});

  @override
  Widget build(BuildContext context) {
    return _PreviewScaffold(
      title: AppLocalizations.of(context)?.categoriesTitle ?? 'ምድቦች',
      actionIcon: Icons.category_rounded,
      selectedTab: AppLocalizations.of(context)?.navCategory ?? 'ምድብ',
      compact: compact,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CategoryRow(
            icon: Icons.volunteer_activism,
            label:
                AppLocalizations.of(context)?.onboardCategoryBullet1 ?? 'ምስጋና',
            compact: compact,
          ),
          SizedBox(height: compact ? 5 : 7),
          _CategoryRow(
            icon: Icons.self_improvement,
            label:
                AppLocalizations.of(context)?.onboardCategoryBullet2 ?? 'ጸሎት',
            compact: compact,
          ),
          SizedBox(height: compact ? 5 : 7),
          _CategoryRow(
            icon: Icons.favorite,
            label:
                AppLocalizations.of(context)?.onboardCategoryBullet3 ?? 'ጋብቻ',
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _LyricsPreview extends StatelessWidget {
  final bool compact;

  const _LyricsPreview({required this.compact});

  @override
  Widget build(BuildContext context) {
    return _PreviewScaffold(
      title: '- 1 -',
      actionIcon: Icons.favorite_border_rounded,
      selectedTab: AppLocalizations.of(context)?.navNumber ?? 'ቁጥር',
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'አምላካችን',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appColors.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Praise God, From Whom All Blessings Flow',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                TextStyle(color: context.appColors.secondaryText, fontSize: 10),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _MediaBox(
                      icon: Icons.play_arrow_rounded,
                      label:
                          AppLocalizations.of(context)?.audioShort ?? 'ድምፅ')),
              const SizedBox(width: 8),
              _MediaBox(
                  icon: Icons.library_music_rounded,
                  label: AppLocalizations.of(context)?.sheetShort ?? 'ኖታ'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.appColors.veil.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  // verbatim: a hymn's opening lines, shown as the book prints them
                  'አምላካችን አመስግኑ\nምስጋና ለእርሱ ይሁን\n...',
                  style: TextStyle(
                    color: context.appColors.primaryText,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPreview extends StatelessWidget {
  final bool compact;

  const _SettingsPreview({required this.compact});

  @override
  Widget build(BuildContext context) {
    return _PreviewScaffold(
      title: AppLocalizations.of(context)?.navSettings ?? 'ቅንብሮች',
      actionIcon: Icons.settings_rounded,
      selectedTab: AppLocalizations.of(context)?.navSettings ?? 'ቅንብሮች',
      compact: compact,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SettingRow(
            icon: Icons.library_books_rounded,
            label: AppLocalizations.of(context)?.onboardSettingsBullet1 ??
                'የመዝሙር ስብስብ',
            compact: compact,
          ),
          SizedBox(height: compact ? 5 : 7),
          _SettingRow(
            icon: Icons.format_size_rounded,
            label: AppLocalizations.of(context)?.onboardSettingsBullet2 ??
                'የፊደል መጠን',
            compact: compact,
          ),
          SizedBox(height: compact ? 5 : 7),
          _SettingRow(
            icon: Icons.bug_report_rounded,
            label: AppLocalizations.of(context)?.reportBug ?? 'የስህተት ጥቆማ',
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _AccessCallout extends StatelessWidget {
  final String text;
  final bool compact;

  const _AccessCallout({
    required this.text,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appColors.shade.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: context.appColors.accent.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.touch_app_rounded,
                color: context.appColors.accent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: context.appColors.primaryText,
                  fontSize: compact ? 12.5 : 13.5,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  const _MiniCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appColors.veil.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: context.appColors.veil.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 10),
        child: Row(
          children: [
            Icon(icon,
                color: context.appColors.accent, size: compact ? 20 : 23),
            SizedBox(width: compact ? 8 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appColors.primaryText,
                      fontSize: compact ? 12.5 : 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appColors.secondaryText,
                      fontSize: compact ? 10 : 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongRow extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final bool compact;

  const _SongRow({
    required this.number,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appColors.veil.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: context.appColors.veil.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9,
          vertical: compact ? 5 : 7,
        ),
        child: Row(
          children: [
            SizedBox(
              width: compact ? 22 : 26,
              child: Text(
                number,
                style: TextStyle(
                  color: context.appColors.accent,
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appColors.primaryText,
                      fontSize: compact ? 11.3 : 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appColors.secondaryText,
                      fontSize: compact ? 9.5 : 10.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.appColors.secondaryText,
              size: compact ? 16 : 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool compact;

  const _CategoryRow({
    required this.icon,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appColors.veil.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 7 : 9,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: context.appColors.accent, size: compact ? 19 : 22),
            SizedBox(width: compact ? 8 : 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appColors.primaryText,
                  fontSize: compact ? 12.5 : 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.appColors.secondaryText,
              size: compact ? 16 : 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends _CategoryRow {
  const _SettingRow({
    required super.icon,
    required super.label,
    super.compact,
  });
}

class _MediaBox extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MediaBox({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appColors.veil.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: context.appColors.veil.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: context.appColors.accent, size: 18),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: context.appColors.primaryText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailLabel extends StatelessWidget {
  final String text;

  const _RailLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 3,
      child: Text(
        text,
        style: TextStyle(
          color: context.appColors.accent,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NavHint extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _NavHint({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        active ? context.appColors.accent : context.appColors.primaryText;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: active ? 16 : 14),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 7.5,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
