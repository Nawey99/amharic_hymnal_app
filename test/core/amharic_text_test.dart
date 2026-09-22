import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/services/amharic_phonetic_service.dart';
import 'package:amharic_hymnal_app/core/utils/script_detector.dart';

void main() {
  group('ScriptDetector', () {
    test('detects Fidel and Latin text', () {
      expect(ScriptDetector.detect('ወዳንተ የሱስ ሆይ'), ScriptType.amharic);
      expect(ScriptDetector.detect('Jesus loves me'), ScriptType.english);
      expect(ScriptDetector.isAmharic('ፍቅር'), isTrue);
      expect(ScriptDetector.isEnglish('love'), isTrue);
    });

    test('defaults to English for empty, blank or punctuation-only input', () {
      for (final text in ['', '   ', '!?.,']) {
        expect(ScriptDetector.detect(text), ScriptType.english,
            reason: '"$text"');
      }
    });

    test('numbers are not Amharic', () {
      expect(ScriptDetector.detect('132'), isNot(ScriptType.amharic));
    });

    test('mixed text follows the majority, then the first letter', () {
      expect(ScriptDetector.detect('ጌታ ሆይ Lord'), ScriptType.amharic);
      expect(ScriptDetector.detect('Holy holy ቅዱስ'), ScriptType.english);
      // Equal counts: the first letter decides.
      expect(ScriptDetector.detect('ጌታ ab'), ScriptType.amharic);
      expect(ScriptDetector.detect('ab ጌታ'), ScriptType.english);
    });

    test('the Ethiopic Supplement block counts as Amharic', () {
      expect(ScriptDetector.detect('ᎀᎁᎂ'), ScriptType.amharic);
    });
  });

  group('AmharicPhoneticService', () {
    test('letters that sound the same normalise to one form', () {
      const pairs = [
        ('ሰላም', 'ሠላም'),
        ('ስራ', 'ሥራ'),
        ('ሀገር', 'ሐገር'),
        ('ሀገር', 'ኀገር'),
        ('ጸሎት', 'ፀሎት'),
        ('አምላክ', 'ዐምላክ'),
      ];
      for (final (a, b) in pairs) {
        expect(
          AmharicPhoneticService.normalizeAmharic(a),
          AmharicPhoneticService.normalizeAmharic(b),
          reason: '$a / $b',
        );
      }
    });

    test('letters that sound different stay different', () {
      expect(
        AmharicPhoneticService.normalizeAmharic('ሰላም'),
        isNot(AmharicPhoneticService.normalizeAmharic('ቀላም')),
      );
      expect(
        AmharicPhoneticService.normalizeAmharic('ጸሎት'),
        isNot(AmharicPhoneticService.normalizeAmharic('ጠሎት')),
      );
    });

    test('non-Amharic text passes through unchanged', () {
      expect(AmharicPhoneticService.normalizeAmharic('Jesus 132'), 'Jesus 132');
      expect(AmharicPhoneticService.normalizeAmharic(''), '');
    });

    test('lists every spelling of a sound', () {
      final equivalents = AmharicPhoneticService.getPhoneticEquivalents('ሥ');
      expect(equivalents, containsAll(['ሰ', 'ሠ', 'ስ', 'ሥ']));
      expect(AmharicPhoneticService.getPhoneticEquivalents('ቀ'), ['ቀ']);
      expect(AmharicPhoneticService.getPhoneticEquivalents(''), isEmpty);
    });

    test('equivalence is symmetric', () {
      expect(
          AmharicPhoneticService.arePhoneticallyEquivalent('ሐ', 'ሀ'), isTrue);
      expect(
          AmharicPhoneticService.arePhoneticallyEquivalent('ሀ', 'ሐ'), isTrue);
      expect(
          AmharicPhoneticService.arePhoneticallyEquivalent('ሰ', 'ሠ'), isTrue);
    });

    test('unrelated letters are not equivalent', () {
      expect(
          AmharicPhoneticService.arePhoneticallyEquivalent('ሰ', 'ቀ'), isFalse);
      expect(
          AmharicPhoneticService.arePhoneticallyEquivalent('', 'ሰ'), isFalse);
    });
  });
}
