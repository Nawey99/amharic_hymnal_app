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

/// What an Amharic screen says when content cannot be loaded. It used to be
/// the bloc's English sentence, shown as-is whatever the app's language.
const loadErrorMessage = 'መዝሙሮቹን መጫን አልተቻለም። እባክዎ እንደገና ይሞክሩ።';

/// Finds the loading spinner.
Finder get spinner => find.byType(CircularProgressIndicator);
