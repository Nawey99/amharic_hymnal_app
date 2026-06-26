import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/pages/donate_page.dart';

void main() {
  testWidgets('PayPal donation shows coming soon dialog', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DonatePage()));

    await tester.tap(find.text('PayPal'));
    await tester.pumpAndSettle();

    expect(find.text('የPayPal ድጋፍ በቅርቡ ይዘጋጃል።'), findsOneWidget);
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

    await tester.tap(find.text('ብሔራዊ ባንክ'));
    await tester.pumpAndSettle();

    expect(find.text('ብሔራዊ ባንክ'), findsWidgets);
    expect(
      find.textContaining('የባንክ ድጋፍ መረጃ'),
      findsOneWidget,
    );
    expect(find.byTooltip('ቅዳ'), findsWidgets);

    await tester.tap(find.byTooltip('ቅዳ').first);
    await tester.pumpAndSettle();

    expect(copiedText, 'National Bank of Ethiopia');
    expect(find.text('ባንክ ተቀድቷል'), findsOneWidget);
  });
}
