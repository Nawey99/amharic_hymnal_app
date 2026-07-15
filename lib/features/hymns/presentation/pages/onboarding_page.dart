// lib/features/hymns/presentation/pages/onboarding_page.dart
import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
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

  static const List<OnboardingStep> _steps = OnboardingContent.steps;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    try {
      final settingsRepository = sl<SettingsRepository>();
      await settingsRepository.setOnboardingCompleted(true);
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
        final bgService = BackgroundImageService();
        return Container(
          decoration: BoxDecoration(
            image: bgService.isEnabled
                ? DecorationImage(
                    image: const AssetImage('assets/images/background.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.82),
                      BlendMode.darken,
                    ),
                  )
                : null,
            color: bgService.isEnabled ? null : AppColors.primaryBackground,
          ),
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
          const Expanded(
            child: Text(
              'ውዳሴ',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFamily: 'NotoSansEthiopic',
              ),
            ),
          ),
          TextButton(
            onPressed: _completeOnboarding,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryText,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text(
              'ዝለል',
              style: TextStyle(
                fontFamily: 'NotoSansEthiopic',
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
                opacity: 0.16,
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
                          color: AppColors.accentGreen,
                          size: compact ? 25 : 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            step.title,
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: compact ? 19 : 22,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'NotoSansEthiopic',
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
                        color: AppColors.secondaryText,
                        fontSize: compact ? 13.3 : 15,
                        fontFamily: 'NotoSansEthiopic',
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
        color: AppColors.accentGreen.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.accentGreen.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          item,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansEthiopic',
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
                backgroundColor: AppColors.accentGreen,
                foregroundColor: AppColors.primaryText,
                padding: EdgeInsets.symmetric(vertical: compact ? 13 : 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Text(
                  _currentPage < _steps.length - 1 ? 'ቀጣይ' : 'ጀምር',
                  key: ValueKey(_currentPage == _steps.length - 1),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'NotoSansEthiopic',
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
        color: isActive ? AppColors.accentGreen : AppColors.secondaryText,
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
        color: AppColors.primaryBackground.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'NotoSansEthiopic',
                ),
              ),
            ),
            Icon(actionIcon,
                color: AppColors.primaryText, size: compact ? 16 : 18),
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
                label: 'ምድብ',
                active: selectedTab == 'ምድብ'),
            _NavHint(
                icon: Icons.list_alt_rounded,
                label: 'ማውጫ',
                active: selectedTab == 'ማውጫ'),
            _NavHint(
                icon: Icons.numbers_rounded,
                label: 'ቁጥር',
                active: selectedTab == 'ቁጥር'),
            _NavHint(
                icon: Icons.favorite_rounded,
                label: 'ተወዳጅ',
                active: selectedTab == 'ተወዳጅ'),
            _NavHint(
                icon: Icons.settings_rounded,
                label: 'ቅንብር',
                active: selectedTab == 'ቅንብር'),
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
      title: 'ውዳሴ',
      actionIcon: Icons.search_rounded,
      selectedTab: 'ቁጥር',
      compact: compact,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MiniCard(
            icon: Icons.numbers_rounded,
            title: 'በቁጥር መክፈት',
            subtitle: 'ቁጥር ያስገቡ እና ክፈት ይንኩ',
            compact: compact,
          ),
          SizedBox(height: compact ? 6 : 8),
          _MiniCard(
            icon: Icons.search_rounded,
            title: 'ፈልግ',
            subtitle: 'በርዕስ ወይም በግጥም',
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
      title: 'ውዳሴ',
      actionIcon: Icons.history_rounded,
      selectedTab: 'ቁጥር',
      compact: compact,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: compact ? 38 : 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 14),
                Text('#',
                    style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w800)),
                SizedBox(width: 16),
                Text('125',
                    style: TextStyle(
                        color: AppColors.primaryText,
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
              color: AppColors.accentGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ክፈት',
              style: TextStyle(
                color: AppColors.primaryText,
                fontFamily: 'NotoSansEthiopic',
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
      title: 'ማውጫ',
      actionIcon: Icons.sort_rounded,
      selectedTab: 'ማውጫ',
      compact: compact,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SongRow(
                  number: '1',
                  title: 'አምላካችን',
                  subtitle: 'Praise God',
                  compact: compact,
                ),
                SizedBox(height: compact ? 5 : 7),
                _SongRow(
                  number: '40',
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
      title: 'ምድቦች',
      actionIcon: Icons.category_rounded,
      selectedTab: 'ምድብ',
      compact: compact,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CategoryRow(
            icon: Icons.volunteer_activism,
            label: 'ምስጋና',
            compact: compact,
          ),
          SizedBox(height: compact ? 5 : 7),
          _CategoryRow(
            icon: Icons.self_improvement,
            label: 'ጸሎት',
            compact: compact,
          ),
          SizedBox(height: compact ? 5 : 7),
          _CategoryRow(
            icon: Icons.favorite,
            label: 'ጋብቻ',
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
      selectedTab: 'ቁጥር',
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'አምላካችን',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFamily: 'NotoSansEthiopic',
            ),
          ),
          const Text(
            'Praise God, From Whom All Blessings Flow',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.secondaryText, fontSize: 10),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(
                  child:
                      _MediaBox(icon: Icons.play_arrow_rounded, label: 'ድምፅ')),
              SizedBox(width: 8),
              _MediaBox(icon: Icons.library_music_rounded, label: 'ኖታ'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'አምላካችን አመስግኑ\nምስጋና ለእርሱ ይሁን\n...',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 12,
                    fontFamily: 'NotoSansEthiopic',
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
      title: 'ቅንብር',
      actionIcon: Icons.settings_rounded,
      selectedTab: 'ቅንብር',
      compact: compact,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SettingRow(
            icon: Icons.library_books_rounded,
            label: 'የመዝሙር ስብስብ',
            compact: compact,
          ),
          SizedBox(height: compact ? 5 : 7),
          _SettingRow(
            icon: Icons.format_size_rounded,
            label: 'የፊደል መጠን',
            compact: compact,
          ),
          SizedBox(height: compact ? 5 : 7),
          _SettingRow(
            icon: Icons.bug_report_rounded,
            label: 'ስህተት ሪፖርት',
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
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.accentGreen.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.touch_app_rounded,
                color: AppColors.accentGreen, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: compact ? 12.5 : 13.5,
                  fontFamily: 'NotoSansEthiopic',
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
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accentGreen, size: compact ? 20 : 23),
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
                      color: AppColors.primaryText,
                      fontSize: compact ? 12.5 : 14,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'NotoSansEthiopic',
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: compact ? 10 : 11,
                      fontFamily: 'NotoSansEthiopic',
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
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                  color: AppColors.accentGreen,
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
                      color: AppColors.primaryText,
                      fontSize: compact ? 11.3 : 12.5,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'NotoSansEthiopic',
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: compact ? 9.5 : 10.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.secondaryText,
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
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 7 : 9,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accentGreen, size: compact ? 19 : 22),
            SizedBox(width: compact ? 8 : 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: compact ? 12.5 : 14,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'NotoSansEthiopic',
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.secondaryText,
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
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.accentGreen, size: 18),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFamily: 'NotoSansEthiopic',
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
        style: const TextStyle(
          color: AppColors.accentGreen,
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
    final color = active ? AppColors.accentGreen : AppColors.primaryText;
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
            fontFamily: 'NotoSansEthiopic',
          ),
        ),
      ],
    );
  }
}
