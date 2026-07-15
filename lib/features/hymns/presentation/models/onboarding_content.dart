import 'package:flutter/material.dart';

/// Immutable onboarding content, kept separate from responsive preview widgets.
abstract final class OnboardingContent {
  static const List<OnboardingStep> steps = [
    OnboardingStep(
      title: 'ውዳሴ ምን ያደርጋል?',
      description:
          'ውዳሴ የአማርኛ አድቬንቲስት መዝሙሮችን፣ ሀገርኛ መዝሙሮችን፣ ተወዳጆችን፣ ኖታን እና ድምፅን በአንድ ቦታ ያቀርባል።',
      access: 'መተግበሪያው ሲከፈት መጀመሪያ የቁጥር ገጽ ይታያል። ከታች ያለው ናቪጌሽን ዋና መንገድዎ ነው።',
      preview: OnboardingPreview.library,
      icon: Icons.library_music_rounded,
      bullets: ['የመዝሙር ግጥም', 'በቁጥር መክፈት', 'ተወዳጅ ማስቀመጥ'],
    ),
    OnboardingStep(
      title: 'በቁጥር መዝሙር ይክፈቱ',
      description:
          'መዝሙር ቁጥር ካወቁ በፍጥነት ወደ ግጥሙ መግባት ይችላሉ። ቁጥሩ በስብስቡ ውስጥ ካልገኘ መተግበሪያው ያሳውቃል።',
      access: 'ከታች “ቁጥር” ይንኩ፣ ቁጥሩን ያስገቡ፣ ከዚያ “ክፈት” ይንኩ።',
      preview: OnboardingPreview.number,
      icon: Icons.numbers_rounded,
      bullets: ['ቁጥር ያስገቡ', 'ክፈት ይንኩ', 'ወደ ግጥም ይሂዱ'],
    ),
    OnboardingStep(
      title: 'በማውጫ ይፈልጉ',
      description:
          'ማውጫ መዝሙሮችን በቁጥር ወይም በስም ያሳያል። በፍለጋ ሳጥን ርዕስ፣ የእንግሊዝኛ ርዕስ ወይም በግጥም ውስጥ ያለ ቃል መፈለግ ይችላሉ።',
      access:
          'ከታች “ማውጫ” ይንኩ። የፍለጋ አዝራሩን ይክፈቱ ወይም የአደራደር አዝራሩን በመንካት በቁጥር/በስም ይቀይሩ።',
      preview: OnboardingPreview.indexList,
      icon: Icons.list_alt_rounded,
      bullets: ['በርዕስ', 'በግጥም', 'በቁጥር ወይም በፊደል'],
    ),
    OnboardingStep(
      title: 'በምድብ ያግኙ',
      description:
          'ምድቦች መዝሙሮችን እንደ ምስጋና፣ ጸሎት፣ ሰንበት፣ ጋብቻ እና ተስፋ በርዕሰ ጉዳይ ያደራጃሉ።',
      access: 'ከታች “ምድብ” ይንኩ፣ የሚፈልጉትን ምድብ ይምረጡ፣ ከዚያ በዚያ ምድብ ያሉ መዝሙሮች ይታያሉ።',
      preview: OnboardingPreview.categories,
      icon: Icons.category_rounded,
      bullets: ['ምስጋና', 'ጸሎት', 'ጋብቻ'],
    ),
    OnboardingStep(
      title: 'ግጥም፣ ድምፅ እና ኖታ',
      description:
          'የመዝሙር ገጽ ቁጥሩን፣ የአማርኛ ርዕሱን፣ የእንግሊዝኛ ርዕሱን እና ግጥሙን ያሳያል። ድምፅ ሲኖር ከዚያው ይጫወታል፤ ኖታ ሲኖር በሙሉ ገጽ ይከፈታል።',
      access:
          'ከማንኛውም መዝሙር ዝርዝር መዝሙሩን ይንኩ። ልብ ምልክቱ ወደ ተወዳጆች ያክላል፤ የኖታ ሳጥን ኖታውን ይከፍታል።',
      preview: OnboardingPreview.lyrics,
      icon: Icons.menu_book_rounded,
      bullets: ['ግጥም ማንበብ', 'ድምፅ መጫወት', 'ኖታ መክፈት'],
    ),
    OnboardingStep(
      title: 'ቅንብርን ይቆጣጠሩ',
      description:
          'ከቅንብር ገጽ የመዝሙር ስብስብን፣ የፊደል መጠንን፣ የጀርባ ምስልን፣ ስክሪን እንዳይጠፋ ማድረግን፣ ድጋፍን እና ስህተት ሪፖርትን ያገኛሉ።',
      access: 'ከታች “ቅንብር” ይንኩ። አዲስ/ቀድሞ መዝሙር ወይም ሀገርኛ ለመቀየር የስብስብ ምርጫውን ይጠቀሙ።',
      preview: OnboardingPreview.settings,
      icon: Icons.settings_rounded,
      bullets: ['የመዝሙር ስብስብ', 'የፊደል መጠን', 'ስህተት ሪፖርት'],
    ),
  ];
}

@immutable
class OnboardingStep {
  final String title;
  final String description;
  final String access;
  final OnboardingPreview preview;
  final IconData icon;
  final List<String> bullets;

  const OnboardingStep({
    required this.title,
    required this.description,
    required this.access,
    required this.preview,
    required this.icon,
    required this.bullets,
  });
}

enum OnboardingPreview {
  library,
  number,
  indexList,
  categories,
  lyrics,
  settings,
}
