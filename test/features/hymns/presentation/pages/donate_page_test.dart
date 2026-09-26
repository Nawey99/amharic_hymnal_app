import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/utils/nav_bar_constants.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/donate_page.dart';

void main() {
  testWidgets('the page and its bank page end clear of the navigation bar',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DonatePage()));
    await tester.pumpAndSettle();

    double listBottomPadding(WidgetTester tester) =>
        (tester.widget<ListView>(find.byType(ListView)).padding! as EdgeInsets)
            .bottom;
    final expected = NavBarConstants.getBottomPadding(
      tester.element(find.byType(ListView)),
    );
    expect(listBottomPadding(tester), expected);

    await tester.tap(find.text('በባንክ ማስተላለፊያ'));
    await tester.pumpAndSettle();
    expect(listBottomPadding(tester), expected);
  });

  testWidgets('PayPal donation shows coming soon dialog', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DonatePage()));

    await tester.tap(find.text('PayPal'));
    await tester.pumpAndSettle();

    expect(find.text('የPayPal ድጋፍ በቅርቡ ይጀምራል።'), findsOneWidget);
  });

  testWidgets('National Bank page exposes copyable fields', (tester) async {
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedText = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(const MaterialApp(home: DonatePage()));

    await tester.tap(find.text('በባንክ ማስተላለፊያ'));
    await tester.pumpAndSettle();

    expect(find.text('በባንክ ማስተላለፊያ'), findsWidgets);
    expect(
      find.textContaining('የባንክ ድጋፍ መረጃ'),
      findsOneWidget,
    );
    expect(find.byTooltip('ቅዳ'), findsOneWidget);

    await tester.tap(find.byTooltip('ቅዳ').first);
    await tester.pumpAndSettle();

    expect(copiedText, 'በኋላ ይጨመራል');
    expect(find.text('የሒሳብ ቁጥሩ ተቀድቷል'), findsOneWidget);
  });
}
