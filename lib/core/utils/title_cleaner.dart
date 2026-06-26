import 'package:amharic_hymnal_app/core/utils/script_detector.dart';

String cleanEnglishTitle(String? value) {
  if (value == null) return '';
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  if (ScriptDetector.isAmharic(trimmed)) return trimmed;

  var result = trimmed
      .replaceAll(RegExp(r'^[\s#*_~`"“”‘’.,;:!?\[\]{}<>|\\/]+'), '')
      .replaceAll(RegExp(r'[\s#*_~`"“”‘’.,;:!?\[\]{}<>|\\/]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ');

  result = result
      .replaceAll(RegExp(r'\s+([,.;:!?])'), r'$1')
      .replaceAll(RegExp(r'([([])\s+'), r'$1')
      .replaceAll(RegExp(r'\s+([\]\)])'), r'$1')
      .trim();

  while (result.endsWith('!') || result.endsWith('#')) {
    result = result.substring(0, result.length - 1).trimRight();
  }

  return result;
}
