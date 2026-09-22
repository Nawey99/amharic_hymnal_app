import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/features/hymns/data/models/hymn_model.dart';

/// A hymn for list-page tests, with an optional category or author.
HymnModel listHymn(
  int number, {
  String? title,
  String? category,
  String? artist,
  String prefix = 'am-sda-2004',
}) =>
    HymnModel(
      id: '$prefix-${number.toString().padLeft(4, '0')}',
      number: number,
      title: title ?? 'መዝሙር $number',
      lyrics: 'የመዝሙር $number ግጥም',
      category: category,
      artist: artist,
    );

/// The vertical position of the list tile showing [text], to check order.
double topOf(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text).first).dy;

/// The message the bloc shows when content cannot be loaded.
const loadErrorMessage = 'Hymns could not be loaded. Please try again.';

/// Finds the loading spinner.
Finder get spinner => find.byType(CircularProgressIndicator);
