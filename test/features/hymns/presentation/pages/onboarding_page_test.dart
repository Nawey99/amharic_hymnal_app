import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/models/onboarding_content.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/main_navigation_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/onboarding_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart' as di;
import 'package:amharic_hymnal_app/main.dart';

import '../../../../helpers/test_app.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

bool get _completed => di.sl<SettingsRepository>().isOnboardingCompleted();

void main() {
  Future<void> pumpOnboarding(WidgetTester tester) async {
    await setUpTestApp(prefs: {'onboarding_completed': false});
    await pumpInApp(tester, const OnboardingPage());
    await _settle(tester);
  }

  testWidgets('"next" walks every step, and the last one starts the app',
      (tester) async {
    await pumpOnboarding(tester);
    final steps = OnboardingContent.steps.length;

    for (var step = 1; step < steps; step++) {
      expect(find.text('ቀጣይ'), findsOneWidget, reason: 'step $step');
      await tester.tap(find.text('ቀጣይ'));
      await _settle(tester);
      expect(_completed, isFalse);
    }

    expect(find.text('ጀምር'), findsOneWidget);
    await tester.tap(find.text('ጀምር'));
    await _settle(tester);

    expect(_completed, isTrue);
    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.byType(MainNavigationPage), findsOneWidget);
  });

  testWidgets('"skip" finishes straight away', (tester) async {
    await pumpOnboarding(tester);

    await tester.tap(find.text('ዝለል'));
    await _settle(tester);

    expect(_completed, isTrue);
    expect(find.byType(MainNavigationPage), findsOneWidget);
  });

  testWidgets('the app opens on onboarding only until it is completed',
      (tester) async {
    await setUpTestApp(prefs: {'onboarding_completed': false});
    await tester.pumpWidget(const MyApp(loadInitialHymns: false));
    await _settle(tester);
    expect(find.byType(OnboardingPage), findsOneWidget);

    await di.sl<SettingsRepository>().setOnboardingCompleted(true);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MyApp(loadInitialHymns: false));
    await _settle(tester);

    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.byType(MainNavigationPage), findsOneWidget);
  });
}
