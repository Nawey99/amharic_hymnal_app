import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/widgets/app_version_footer.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_version_service.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/settings_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart' as di;

import '../../../../helpers/fakes.dart';
import '../../../../helpers/test_app.dart';

const _wakelockToggle =
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The edition list offline: settings falls back to the built-in editions.
void _offlineVersionCatalog() {
  di.sl.unregister<HymnalVersionService>();
  di.sl.registerLazySingleton<HymnalVersionService>(
    () => HymnalVersionService(
      baseUrl: 'https://api.example.test/api/v1',
      client: MockClient((_) async => http.Response('', 503)),
    ),
  );
}

void main() {
  group('SettingsPage', () {
    late List<Object?> wakelockCalls;

    setUp(() {
      wakelockCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(_wakelockToggle, (message) async {
        // The message uses Pigeon's own codec; that it arrived is what
        // matters here.
        wakelockCalls.add(message);
        return const StandardMessageCodec().encodeMessage(<Object?>[]);
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(_wakelockToggle, null);
    });

    Future<void> scrollToFooter(WidgetTester tester) async {
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('app-version-footer')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await _settle(tester);
    }

    Future<void> tapVersion(WidgetTester tester, int times) async {
      for (var tap = 0; tap < times; tap++) {
        await tester.tap(find.byKey(const ValueKey('app-version-footer')));
        await tester.pump(const Duration(milliseconds: 120));
      }
      await _settle(tester);
    }

    Future<HymnsBloc> pumpSettings(WidgetTester tester) async {
      await setUpTestApp(content: {
        'sda_new': sampleHymns(),
        'sda_old': sampleHymns(count: 3, prefix: 'am-sda-1975'),
      });
      _offlineVersionCatalog();
      final bloc = await pumpInApp(
        tester,
        const Scaffold(body: SettingsPage()),
        size: const Size(412, 1400),
      );
      await _settle(tester);
      return bloc;
    }

    testWidgets('switching edition saves it and reloads that book',
        (tester) async {
      final bloc = await pumpSettings(tester);

      await tester.tap(find.text('የ2004 ውዳሴ መዝሙር').last);
      await _settle(tester);
      await tester.tap(find.text('የ1975 ውዳሴ መዝሙር').last);
      await _settle(tester);

      expect(di.sl<SettingsRepository>().getSelectedVersion(), 'sda_old');
      final state = bloc.state as HymnsLoaded;
      expect(state.version, 'sda_old');
      expect(state.hymns, hasLength(3));
    });

    testWidgets(
        'the privacy policy is reachable, and points at the page '
        'the store listing names', (tester) async {
      await pumpSettings(tester);

      final tile = find.byKey(const ValueKey('privacy-tile'));
      await tester.scrollUntilVisible(
        tile,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await _settle(tester);

      expect(tile, findsOneWidget);
      expect(find.text('የግላዊነት ፖሊሲ'), findsOneWidget);
      expect(
        SettingsPage.privacyUri.toString(),
        'https://nawey99.github.io/amharic_hymnal_app/privacy.html',
      );
    });

    testWidgets('no donation entry while there is no account number to show',
        (tester) async {
      await pumpSettings(tester);
      await scrollToFooter(tester);

      expect(SettingsPage.donationsReady, isFalse);
      expect(find.byKey(const ValueKey('donate-tile')), findsNothing);
      expect(find.text('ይለግሱ'), findsNothing);
    });

    testWidgets('keep-screen-on is saved and applied', (tester) async {
      await pumpSettings(tester);
      expect(di.sl<SettingsRepository>().getKeepScreenOn(), isFalse);

      await tester.tap(find.byType(Switch).last);
      await _settle(tester);

      expect(di.sl<SettingsRepository>().getKeepScreenOn(), isTrue);
      expect(wakelockCalls, isNotEmpty, reason: 'the wake lock was toggled');
    });

    testWidgets('offers whole-book sheet music and audio downloads',
        (tester) async {
      await pumpSettings(tester);

      expect(find.text('ኖታዎችን በሙሉ አውርድ'), findsOneWidget);
      expect(find.text('ድምፆችን በሙሉ አውርድ'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('ድምፆችን በሙሉ አውርድ')).dx,
        tester.getTopLeft(find.text('ኖታዎችን በሙሉ አውርድ')).dx,
      );
    });

    testWidgets('the download title lines up with the switch above it',
        (tester) async {
      await pumpSettings(tester);

      expect(
        tester.getTopLeft(find.text('ኖታዎችን በሙሉ አውርድ')).dx,
        tester.getTopLeft(find.text('ማያ እንዳይጠፋ')).dx,
      );
    });

    testWidgets('a switch that is off still looks enabled', (tester) async {
      await pumpSettings(tester);

      final off = tester.widget<Switch>(find.byType(Switch).last);
      expect(off.value, isFalse);
      final thumb = off.thumbColor!.resolve(<WidgetState>{})!;
      final outline = off.trackOutlineColor!.resolve(<WidgetState>{})!;
      expect(thumb.a, greaterThan(0.8), reason: 'a bright thumb');
      expect(outline.a, greaterThan(0.3), reason: 'a visible track');
    });

    testWidgets('a divider appears under the title once the list scrolls',
        (tester) async {
      await setUpTestApp(content: {'sda_new': sampleHymns()});
      _offlineVersionCatalog();
      await pumpInApp(
        tester,
        const Scaffold(body: SettingsPage()),
        size: const Size(412, 700),
      );
      await _settle(tester);

      Color dividerColor() => ((tester
                  .widget<AnimatedContainer>(
                    find.byKey(const ValueKey('title-bar-divider')),
                  )
                  .decoration as BoxDecoration)
              .border as Border)
          .bottom
          .color;

      expect(dividerColor().a, 0);
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await _settle(tester);
      expect(dividerColor().a, greaterThan(0));

      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await _settle(tester);
      expect(dividerColor().a, 0);
    });

    testWidgets('the development section is hidden, with the version shown',
        (tester) async {
      await pumpSettings(tester);
      await scrollToFooter(tester);

      expect(find.byKey(const ValueKey('contribution-tile')), findsNothing);
      expect(find.text('ልማት እና አስተዋፅዖ'), findsNothing);
      expect(find.textContaining('ውዳሴ · ስሪት'), findsOneWidget);
    });

    testWidgets('tapping the version enough times reveals it, and remembers',
        (tester) async {
      await pumpSettings(tester);
      await scrollToFooter(tester);

      await tapVersion(tester, AppVersionFooter.unlockTaps - 1);
      expect(find.byKey(const ValueKey('contribution-tile')), findsNothing);
      expect(find.text('ለማሳየት 1 ጊዜ ይንኩ።'), findsOneWidget);

      await tapVersion(tester, 1);
      expect(find.byKey(const ValueKey('contribution-tile')), findsOneWidget);
      expect(find.text('የልማት ክፍሉ አሁን ይታያል።'), findsOneWidget);
      expect(di.sl<SettingsRepository>().isContributionUnlocked(), isTrue);
    });

    testWidgets('taps spread out over time never reveal it', (tester) async {
      await pumpSettings(tester);
      await scrollToFooter(tester);

      for (var round = 0; round < 3; round++) {
        await tapVersion(tester, AppVersionFooter.unlockTaps - 1);
        await tester.pump(AppVersionFooter.tapWindow * 2);
      }

      expect(find.byKey(const ValueKey('contribution-tile')), findsNothing);
      expect(di.sl<SettingsRepository>().isContributionUnlocked(), isFalse);
    });

    testWidgets('once revealed it stays, until a long press hides it again',
        (tester) async {
      await setUpTestApp(
        content: {'sda_new': sampleHymns()},
        prefs: {'contribution_unlocked': true},
      );
      _offlineVersionCatalog();
      await pumpInApp(
        tester,
        const Scaffold(body: SettingsPage()),
        size: const Size(412, 1400),
      );
      await _settle(tester);
      // The page is long enough that the tile is built only once reached.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('contribution-tile')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await _settle(tester);
      expect(find.byKey(const ValueKey('contribution-tile')), findsOneWidget);

      await scrollToFooter(tester);
      await tester.longPress(find.byKey(const ValueKey('app-version-footer')));
      await _settle(tester);

      expect(find.byKey(const ValueKey('contribution-tile')), findsNothing);
      expect(find.text('የልማት ክፍሉ ተደብቋል።'), findsOneWidget);
      expect(di.sl<SettingsRepository>().isContributionUnlocked(), isFalse);
    });

    testWidgets('opening the source code asks before leaving the app',
        (tester) async {
      await pumpSettings(tester);
      await scrollToFooter(tester);
      await tapVersion(tester, AppVersionFooter.unlockTaps);

      await tester.tap(find.byKey(const ValueKey('contribution-tile')));
      await _settle(tester);
      expect(find.text('GitHub ይከፈት?'), findsOneWidget);

      await tester.tap(find.text('ይቅር'));
      await _settle(tester);
      expect(find.text('GitHub ይከፈት?'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
