import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';

/// Immutable onboarding content, kept separate from responsive preview widgets.
abstract final class OnboardingContent {
  /// Locale-aware step list. Rebuilt on each call so the strings follow the
  /// user's chosen language.
  static List<OnboardingStep> stepsFor(AppLocalizations l) => [
        OnboardingStep(
          title: l.onboardingStep1Title,
          description: l.onboardingStep1Description,
          access: l.onboardingStep1Access,
          preview: OnboardingPreview.library,
          icon: Icons.library_music_rounded,
          bullets: [
            l.onboardingStep1Bullet1,
            l.onboardingStep1Bullet2,
            l.onboardingStep1Bullet3,
          ],
        ),
        OnboardingStep(
          title: l.onboardingStep2Title,
          description: l.onboardingStep2Description,
          access: l.onboardingStep2Access,
          preview: OnboardingPreview.number,
          icon: Icons.numbers_rounded,
          bullets: [
            l.onboardingStep2Bullet1,
            l.onboardingStep2Bullet2,
            l.onboardingStep2Bullet3,
          ],
        ),
        OnboardingStep(
          title: l.onboardingStep3Title,
          description: l.onboardingStep3Description,
          access: l.onboardingStep3Access,
          preview: OnboardingPreview.indexList,
          icon: Icons.list_alt_rounded,
          bullets: [
            l.onboardingStep3Bullet1,
            l.onboardingStep3Bullet2,
            l.onboardingStep3Bullet3,
          ],
        ),
        OnboardingStep(
          title: l.onboardingStep4Title,
          description: l.onboardingStep4Description,
          access: l.onboardingStep4Access,
          preview: OnboardingPreview.categories,
          icon: Icons.category_rounded,
          bullets: const ['ምስጋና', 'ጸሎት', 'ጋብቻ'],
        ),
        OnboardingStep(
          title: l.onboardingStep5Title,
          description: l.onboardingStep5Description,
          access: l.onboardingStep5Access,
          preview: OnboardingPreview.lyrics,
          icon: Icons.menu_book_rounded,
          bullets: [
            l.onboardingStep5Bullet1,
            l.onboardingStep5Bullet2,
            l.onboardingStep5Bullet3,
          ],
        ),
        OnboardingStep(
          title: l.onboardingStep6Title,
          description: l.onboardingStep6Description,
          access: l.onboardingStep6Access,
          preview: OnboardingPreview.settings,
          icon: Icons.settings_rounded,
          bullets: [
            l.onboardingStep6Bullet1,
            l.onboardingStep6Bullet2,
            l.onboardingStep6Bullet3,
          ],
        ),
      ];
}

@immutable
class OnboardingStep {
  final String title;
  final String description;
  final String access;
  final OnboardingPreview preview;
  final IconData icon;
  final List<String> bullets;

  const OnboardingStep({
    required this.title,
    required this.description,
    required this.access,
    required this.preview,
    required this.icon,
    required this.bullets,
  });
}

enum OnboardingPreview {
  library,
  number,
  indexList,
  categories,
  lyrics,
  settings,
}
