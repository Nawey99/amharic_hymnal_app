import 'package:flutter/material.dart';

/// Immutable onboarding content, kept separate from responsive preview widgets.
abstract final class OnboardingContent {
  static const List<OnboardingStep> steps = [
    OnboardingStep(
      title: 'ስለ ውዳሴ መተግበሪያ',
      description:
          'ውዳሴ የአማርኛ አድቬንቲስት እና የሀገርኛ መዝሙሮችን ከነግጥማቸው፣ ከሙዚቃ ኖታና ከድምፃቸው ጋር በአንድ ቦታ ያቀርባል።',
      access:
          'መተግበሪያው ሲከፈት መጀመሪያ የቁጥር ገጽ ይታያል። ከታች የሚገኘው የማውጫ አሞሌ በገጾች መካከል ለመዘዋወር ያገለግላል።',
      preview: OnboardingPreview.library,
      icon: Icons.library_music_rounded,
      bullets: ['የመዝሙር ግጥሞች', 'በቁጥር መክፈት', 'ተወዳጆችን መመዝገብ'],
    ),
    OnboardingStep(
      title: 'በቁጥር መዝሙር ይክፈቱ',
      description:
          'የመዝሙሩን ቁጥር ካወቁ በፍጥነት ወደ ግጥሙ መግባት ይችላሉ። ቁጥሩ በስብስቡ ውስጥ ካልገኘ መተግበሪያው ያሳውቃል።',
      access: 'ከታች “ቁጥር”ን ይንኩ፤ የመዝሙሩን ቁጥር ካስገቡ በኋላ “ክፈት”ን ይጫኑ።',
      preview: OnboardingPreview.number,
      icon: Icons.numbers_rounded,
      bullets: ['በቁጥር መፈለግ', 'በቀጥታ መክፈት', 'ግጥሙን ማንበብ'],
    ),
    OnboardingStep(
      title: 'በማውጫ ይፈልጉ',
      description:
          'ማውጫ መዝሙሮችን በቁጥር ወይም በርዕስ ቅደም ተከተል ያሳያል። በተጨማሪም በፍለጋ ሳጥኑ ውስጥ በርዕስ፣ በእንግሊዝኛ ርዕስ ወይም በግጥም ቃላት መፈለግ ይችላሉ።',
      access:
          'ከታች “ማውጫ”ን ይንኩ። የፍለጋ ምልክቱን በመንካት መፈለግ፣ ወይም የአደራደር አዝራሩን በመንካት በቁጥር አሊያም በርዕስ ቅደም ተከተል ማስተካከል ይችላሉ።',
      preview: OnboardingPreview.indexList,
      icon: Icons.list_alt_rounded,
      bullets: ['በርዕስ', 'በግጥም', 'በቁጥር ወይም በፊደል'],
    ),
    OnboardingStep(
      title: 'በምድብ ያግኙ',
      description:
          'ምድቦች መዝሙሮችን እንደ ምስጋና፣ ጸሎት፣ ሰንበት፣ ጋብቻ እና ተስፋ በርዕሰ ጉዳይ ያደራጃሉ።',
      access:
          'ከታች “ምድብ”ን ይንኩና የሚፈልጉትን ምድብ ይምረጡ፤ ከዚያም በምድቡ ሥር የተካተቱት መዝሙሮች ይዘረዘራሉ።',
      preview: OnboardingPreview.categories,
      icon: Icons.category_rounded,
      bullets: ['ምስጋና', 'ጸሎት', 'ጋብቻ'],
    ),
    OnboardingStep(
      title: 'ግጥም፣ ድምፅ እና ኖታ',
      description:
          'የመዝሙሩ ገጽ ቁጥሩን፣ የአማርኛና የእንግሊዝኛ ርዕሱን እንዲሁም ሙሉ ግጥሙን ያሳያል። ድምፅ ሲኖረው ከዚያው ማጫወት፣ የሙዚቃ ኖታ ሲኖረውም በሙሉ ገጽ መክፈት ይችላሉ።',
      access:
          'ከማንኛውም የመዝሙር ዝርዝር ውስጥ የሚፈልጉትን መዝሙር ይንኩ። የልብ ምልክቱን በመንካት ወደ ተወዳጅ መዝሙሮች ማከል፣ የኖታ ምልክቱን በመንካት ደግሞ ኖታውን መክፈት ይችላሉ።',
      preview: OnboardingPreview.lyrics,
      icon: Icons.menu_book_rounded,
      bullets: ['ግጥም ማንበብ', 'ድምፅ መጫወት', 'ኖታ መክፈት'],
    ),
    OnboardingStep(
      title: 'ቅንብሮችን ያስተካክሉ',
      description:
          'ከቅንብሮች ገጽ የመዝሙር ስብስብን፣ የፊደል መጠንን፣ የጀርባ ምስልን፣ ማያ እንዳይጠፋ ማድረግን፣ የልገሳ ድጋፍን እና የስህተት ጥቆማን ያገኛሉ።',
      access:
          'ከታች “ቅንብሮች”ን ይንኩ። የ2004፣ የ1975 ወይም የ1961 ውዳሴ መዝሙርን አሊያም የሀገርኛ መዝሙር ስብስብን ለመቀየር የስብስብ ምርጫውን ይጠቀሙ።',
      preview: OnboardingPreview.settings,
      icon: Icons.settings_rounded,
      bullets: ['የመዝሙር ስብስብ', 'የፊደል መጠን', 'የስህተት ጥቆማ'],
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
