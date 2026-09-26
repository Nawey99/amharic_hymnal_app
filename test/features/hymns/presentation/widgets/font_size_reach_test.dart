import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/services/font_size_service.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/core/widgets/app_text_scope.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/hymn_list_item.dart';

import '../../../../helpers/test_app.dart';

const _hymn = Hymn(
  id: 'sda_new-sda-1',
  number: 1,
  title: 'አምላካችን',
  lyrics: 'አምላካችን አመስግኑ',
);

/// The size of the hymn's title in a list row.
double _titleSize(WidgetTester tester) =>
    tester.widget<Text>(find.text('አምላካችን')).style!.fontSize!;

void main() {
  setUp(() async {
    await setUpTestApp();
    FontSizeService().initialize(20);
  });

  testWidgets('a list row follows the setting as it changes', (tester) async {
    await pumpInApp(
      tester,
      const AppTextScope(
        child: Scaffold(
          body: HymnListItem(hymn: _hymn, onTap: _noop),
        ),
      ),
    );
    final atTwenty = _titleSize(tester);

    await FontSizeService().setFontSize(30);
    await tester.pump();
    final atThirty = _titleSize(tester);

    await FontSizeService().setFontSize(12);
    await tester.pump();
    final atTwelve = _titleSize(tester);

    expect(atThirty, greaterThan(atTwenty));
    expect(atTwelve, lessThan(atTwenty));
    expect(
      atThirty - atTwelve,
      greaterThanOrEqualTo(6),
      reason: 'the setting has to be worth moving in a list, not 2 pixels',
    );
  });

  testWidgets('the phone text size still applies, up to twice', (tester) async {
    await pumpInApp(
      tester,
      const AppTextScope(
        child: Scaffold(
          body: HymnListItem(hymn: _hymn, onTap: _noop),
        ),
      ),
      textScale: 3,
    );

    expect(
      tester.widget<MediaQuery>(find.byType(MediaQuery).last).data.textScaler,
      const TextScaler.linear(AppTextScope.maxSystemScale),
      reason: 'past twice the size the layouts give way',
    );
  });
}

void _noop() {}
