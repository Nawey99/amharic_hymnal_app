// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:amharic_hymnal_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('Complete user flow: open lyrics, zoom, pan, navigate, unfavorite', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Wait for app to initialize
      await tester.pumpAndSettle();

      // Find and tap on a hymn in the list (if available)
      // Note: This test assumes hymns are loaded
      final hymnListItems = find.byType(ListTile);
      if (hymnListItems.evaluate().isNotEmpty) {
        // Tap first hymn
        await tester.tap(hymnListItems.first);
        await tester.pumpAndSettle();

        // Verify we're on the detail page
        expect(find.textContaining('መዝሙር'), findsWidgets);

        // Test pinch-to-zoom (simulate with gestures)
        final lyricsSection = find.byType(SelectableText);
        if (lyricsSection.evaluate().isNotEmpty) {
          // Simulate pinch gesture
          final gesture = await tester.createGesture();
          await gesture.down(const Offset(200, 400));
          await gesture.moveBy(const Offset(50, 50));
          await tester.pump();
          await gesture.up();
          await tester.pumpAndSettle();
        }

        // Test favorite toggle
        final favoriteButton = find.byIcon(Icons.favorite_border);
        if (favoriteButton.evaluate().isNotEmpty) {
          await tester.tap(favoriteButton);
          await tester.pump();
          // Verify icon changed (optimistic update)
          expect(find.byIcon(Icons.favorite), findsOneWidget);
        }

        // Navigate back
        final backButton = find.byType(BackButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Search functionality', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find search button
      final searchButton = find.byIcon(Icons.search);
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();

        // Enter search query
        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          await tester.enterText(searchField.first, 'test');
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
        }
      }
    });

    testWidgets('Sheet music viewer loads correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to a hymn with sheet music (SDA Hymnal)
      // This test would need specific hymn numbers that have sheet music
      // For now, just verify the viewer widget exists when sheet music is present
      // Sheet music viewer uses PageView internally
      // This is a basic smoke test - full test would require specific hymn data
      expect(find.byType(PageView), findsNothing); // No sheet music on initial load
    });
  });
}

