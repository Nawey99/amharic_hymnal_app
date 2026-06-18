// lib/features/hymns/presentation/pages/onboarding_page.dart
import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
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

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Welcome to ውዳሴ',
      description:
          'Browse Amharic SDA hymns and worship songs with a calm reading experience built for church, family worship, and devotion.',
      icon: Icons.library_music,
    ),
    OnboardingStep(
      title: 'Choose Your Song Book',
      description:
          'Use Settings to switch between New SDA Hymnal, Old SDA Hymnal, and Hagerigna. Old and New SDA reuse the same song work where they match.',
      icon: Icons.menu_book,
    ),
    OnboardingStep(
      title: 'Find Hymns Quickly',
      description:
          'Open by hymn number, browse the Index, or use Search. SDA categories are available from the Categories tab.',
      icon: Icons.search,
    ),
    OnboardingStep(
      title: 'Navigate Between Hymns',
      description:
          'Swipe left or right in a hymn to move by hymn number. Favorites and automatic History help you return to songs later.',
      icon: Icons.swipe,
    ),
    OnboardingStep(
      title: 'Lyrics and Media',
      description:
          'Adjust lyric size from Settings. Sheet music is available for supported SDA hymns, with audio and download support prepared for future releases.',
      icon: Icons.zoom_in,
    ),
    OnboardingStep(
      title: 'Customize Settings',
      description:
          'Tune font size, background image, and Keep Screen On from Settings. More Ethiopian languages can be added in future releases.',
      icon: Icons.settings,
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
      if (mounted) {
        // Navigate to main navigation page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainNavigationPage(),
          ),
        );
      }
    } catch (e) {
      // If navigation fails, just show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.errorOccurred ?? 'Error:'} ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            body: SafeArea(
              child: Column(
                children: [
                  // Skip button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: GlassButton(
                        onPressed: _completeOnboarding,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        borderRadius: 12.0,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'NotoSansEthiopic',
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Page view
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _steps.length,
                      itemBuilder: (context, index) {
                        return _buildPage(_steps[index]);
                      },
                    ),
                  ),

                  // Page indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _steps.length,
                        (index) => _buildIndicator(index == _currentPage),
                      ),
                    ),
                  ),

                  // Next/Get Started button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                    child: SizedBox(
                      width: double.infinity,
                      child: _OnboardingButton(
                        onPressed: () {
                          if (_currentPage < _steps.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _completeOnboarding();
                          }
                        },
                        text: _currentPage < _steps.length - 1
                            ? 'Next'
                            : 'Get Started',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPage(OnboardingStep step) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 560;
        final pagePadding = compact ? 20.0 : 32.0;
        final cardPadding = compact ? 24.0 : 32.0;
        final iconSize = compact ? 72.0 : 104.0;
        final titleSize = compact ? 23.0 : 28.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(pagePadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - pagePadding * 2).clamp(
                0,
                double.infinity,
              ),
            ),
            child: Center(
              child: GlassContainer(
                borderRadius: 24.0,
                blurSigma: 12.0,
                opacity: 0.15,
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      step.icon,
                      size: iconSize,
                      color: AppColors.accentGreen,
                    ),
                    SizedBox(height: compact ? 24 : 40),
                    Text(
                      step.title,
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoSansEthiopic',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: compact ? 16 : 24),
                    Text(
                      step.description,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 16,
                        fontFamily: 'NotoSansEthiopic',
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
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

  Widget _buildIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.accentGreen : AppColors.secondaryText,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;

  OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Custom button for onboarding that doesn't blur content
class _OnboardingButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String text;

  const _OnboardingButton({
    required this.onPressed,
    required this.text,
  });

  @override
  State<_OnboardingButton> createState() => _OnboardingButtonState();
}

class _OnboardingButtonState extends State<_OnboardingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            // Fully opaque button - no transparency
            color: AppColors.accentGreen,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGreen.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.text,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoSansEthiopic',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
