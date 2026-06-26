// lib/features/hymns/presentation/pages/onboarding_page.dart
import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
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

  static const List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'በውዳሴ እንኳን ደህና መጡ',
      description:
          'የአዲስና የቀድሞ የአማርኛ አድቬንቲስት መዝሙሮችን በግልጽ፣ በተረጋጋ እና ለስልክ በተመቻቸ መልኩ ያንብቡ።',
      imageAsset: 'assets/onboarding/library.webp',
      icon: Icons.library_music_rounded,
      bullets: ['ለቤተ ክርስቲያን', 'ለቤተሰብ አምልኮ', 'ለግል ጸሎት'],
    ),
    OnboardingStep(
      title: 'በቁጥር ፈጥነው ይክፈቱ',
      description:
          'በመነሻ ገጽ የመዝሙር ቁጥር ያስገቡና መዝሙሩን በአንድ ንክኪ ይክፈቱ። ይህ ለአገልግሎት ጊዜ ፈጣን መንገድ ነው።',
      imageAsset: 'assets/onboarding/number.webp',
      icon: Icons.numbers_rounded,
      bullets: ['ቁጥር ያስገቡ', 'ክፈት ይንኩ', 'ወደ መዝሙሩ በቀጥታ ይሂዱ'],
    ),
    OnboardingStep(
      title: 'በርዕስ እና በግጥም ይፈልጉ',
      description:
          'የፍለጋ አዝራሩን ይክፈቱ። በመዝሙር ርዕስ፣ በቃል ወይም በግጥም ውስጥ በሚገኝ ሐረግ መፈለግ ይችላሉ።',
      imageAsset: 'assets/onboarding/search.webp',
      icon: Icons.search_rounded,
      bullets: ['በርዕስ', 'በግጥም', 'በተመሳሳይ ድምጽ ፊደላት'],
    ),
    OnboardingStep(
      title: 'ማውጫን እና ምድቦችን ይጠቀሙ',
      description:
          'ማውጫ ገጽ መዝሙሮችን በቁጥር ወይም በፊደል ያሳያል። ምድቦች ገጽ ደግሞ መዝሙሮችን በርዕሰ ጉዳይ ያሰባስባል።',
      imageAsset: 'assets/onboarding/index.webp',
      icon: Icons.list_alt_rounded,
      bullets: ['ማውጫ', 'ምድቦች', 'ቁጥር ወይም ፊደል'],
    ),
    OnboardingStep(
      title: 'ተወዳጆች፣ ኖታ እና ድምፅ',
      description:
          'የሚወዱትን መዝሙር በተወዳጆች ያስቀምጡ። ኖታ ሲኖር ከመዝሙሩ ዝርዝር ገጽ ይክፈቱ፤ የድምፅ ባህሪዎች ሲገኙ ከዚያው ይታያሉ።',
      imageAsset: 'assets/onboarding/library.webp',
      icon: Icons.favorite_rounded,
      bullets: ['ተወዳጆች', 'የኖታ ምስል', 'የድምፅ ቅንብር'],
    ),
    OnboardingStep(
      title: 'ቅንብሮችን ያስተካክሉ',
      description:
          'ከቅንብር ገጽ የመዝሙር ስብስብ፣ ቋንቋ፣ የፊደል መጠን፣ የጀርባ ምስል እና ስክሪን እንዳይጠፋ የሚያደርገውን ምርጫ ይቀይሩ።',
      imageAsset: 'assets/onboarding/library.webp',
      icon: Icons.settings_rounded,
      bullets: ['አዲስ መዝሙር', 'ቀድሞ መዝሙር', 'ሀገርኛ'],
    ),
  ];

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
    final horizontalPadding = compact ? 16.0 : 22.0;
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
                padding: EdgeInsets.all(compact ? 16 : 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMockScreenshot(step, compact),
                    SizedBox(height: compact ? 14 : 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          step.icon,
                          color: AppColors.accentGreen,
                          size: compact ? 26 : 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            step.title,
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: compact ? 20 : 22,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'NotoSansEthiopic',
                              height: 1.22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 10 : 12),
                    Text(
                      step.description,
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: compact ? 14 : 15.5,
                        fontFamily: 'NotoSansEthiopic',
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: step.bullets
                          .map(
                            (item) => DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.accentGreen
                                      .withValues(alpha: 0.22),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
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
                            ),
                          )
                          .toList(),
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

  Widget _buildMockScreenshot(OnboardingStep step, bool compact) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: compact ? 1.95 : 1.7,
        child: Image.asset(
          step.imageAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              step.icon,
              color: AppColors.accentGreen,
              size: 44,
            ),
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

class OnboardingStep {
  final String title;
  final String description;
  final String imageAsset;
  final IconData icon;
  final List<String> bullets;

  const OnboardingStep({
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.icon,
    required this.bullets,
  });
}
