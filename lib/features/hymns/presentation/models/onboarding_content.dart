import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';

/// Immutable onboarding content, kept separate from responsive preview widgets.
abstract final class OnboardingContent {
  /// The onboarding pages, in the app's language.
  ///
  /// This was a `const` list of Amharic copy, which is why onboarding
  /// stayed Amharic however the app was set.
  static List<OnboardingStep> stepsFor(AppLocalizations? l) => [
        OnboardingStep(
          title: l?.onboardAboutTitle ?? _fallbackAboutTitle,
          description: l?.onboardAboutBody ?? _fallbackAboutBody,
          access: l?.onboardAboutAccess ?? _fallbackAboutAccess,
          preview: OnboardingPreview.library,
          icon: Icons.library_music_rounded,
          bullets: [
            l?.onboardAboutBullet1 ?? _fallbackAboutBullet1,
            l?.onboardAboutBullet2 ?? _fallbackAboutBullet2,
            l?.onboardAboutBullet3 ?? _fallbackAboutBullet3,
          ],
        ),
        OnboardingStep(
          title: l?.onboardNumberTitle ?? _fallbackNumberTitle,
          description: l?.onboardNumberBody ?? _fallbackNumberBody,
          access: l?.onboardNumberAccess ?? _fallbackNumberAccess,
          preview: OnboardingPreview.number,
          icon: Icons.numbers_rounded,
          bullets: [
            l?.onboardNumberBullet1 ?? _fallbackNumberBullet1,
            l?.onboardNumberBullet2 ?? _fallbackNumberBullet2,
            l?.onboardNumberBullet3 ?? _fallbackNumberBullet3,
          ],
        ),
        OnboardingStep(
          title: l?.onboardIndexTitle ?? _fallbackIndexTitle,
          description: l?.onboardIndexBody ?? _fallbackIndexBody,
          access: l?.onboardIndexAccess ?? _fallbackIndexAccess,
          preview: OnboardingPreview.indexList,
          icon: Icons.list_alt_rounded,
          bullets: [
            l?.onboardIndexBullet1 ?? _fallbackIndexBullet1,
            l?.onboardIndexBullet2 ?? _fallbackIndexBullet2,
            l?.onboardIndexBullet3 ?? _fallbackIndexBullet3,
          ],
        ),
        OnboardingStep(
          title: l?.onboardCategoryTitle ?? _fallbackCategoryTitle,
          description: l?.onboardCategoryBody ?? _fallbackCategoryBody,
          access: l?.onboardCategoryAccess ?? _fallbackCategoryAccess,
          preview: OnboardingPreview.categories,
          icon: Icons.category_rounded,
          bullets: [
            l?.onboardCategoryBullet1 ?? _fallbackCategoryBullet1,
            l?.onboardCategoryBullet2 ?? _fallbackCategoryBullet2,
            l?.onboardCategoryBullet3 ?? _fallbackCategoryBullet3,
          ],
        ),
        OnboardingStep(
          title: l?.onboardHymnTitle ?? _fallbackHymnTitle,
          description: l?.onboardHymnBody ?? _fallbackHymnBody,
          access: l?.onboardHymnAccess ?? _fallbackHymnAccess,
          preview: OnboardingPreview.lyrics,
          icon: Icons.menu_book_rounded,
          bullets: [
            l?.onboardHymnBullet1 ?? _fallbackHymnBullet1,
            l?.onboardHymnBullet2 ?? _fallbackHymnBullet2,
            l?.onboardHymnBullet3 ?? _fallbackHymnBullet3,
          ],
        ),
        OnboardingStep(
          title: l?.onboardSettingsTitle ?? _fallbackSettingsTitle,
          description: l?.onboardSettingsBody ?? _fallbackSettingsBody,
          access: l?.onboardSettingsAccess ?? _fallbackSettingsAccess,
          preview: OnboardingPreview.settings,
          icon: Icons.settings_rounded,
          bullets: [
            l?.onboardSettingsBullet1 ?? _fallbackSettingsBullet1,
            l?.onboardSettingsBullet2 ?? _fallbackSettingsBullet2,
            l?.onboardSettingsBullet3 ?? _fallbackSettingsBullet3,
          ],
        ),
      ];
}

/// What each onboarding page says when no translation is loaded.
///
/// These are the Amharic the pages were written in, kept beside the
/// lookups as every other fallback in the app is.
const String _fallbackAboutTitle = 'ስለ ውዳሴ መተግበሪያ';
const String _fallbackAboutBody =
    'ውዳሴ የአማርኛ አድቬንቲስት እና የሀገርኛ መዝሙሮችን ከነግጥማቸው፣ ከሙዚቃ ኖታና ከድምፃቸው ጋር በአንድ ቦታ '
    'ያቀርባል።';
const String _fallbackAboutAccess =
    'መተግበሪያው ሲከፈት መጀመሪያ የቁጥር ገጽ ይታያል። ከታች የሚገኘው የማውጫ አሞሌ በገጾች መካከል ለመዘዋወር '
    'ያገለግላል።';
const String _fallbackAboutBullet1 = 'የመዝሙር ግጥሞች';
const String _fallbackAboutBullet2 = 'በቁጥር መክፈት';
const String _fallbackAboutBullet3 = 'ተወዳጆችን መመዝገብ';
const String _fallbackNumberTitle = 'በቁጥር መዝሙር ይክፈቱ';
const String _fallbackNumberBody =
    'የመዝሙሩን ቁጥር ካወቁ በፍጥነት ወደ ግጥሙ መግባት ይችላሉ። ቁጥሩ በስብስቡ ውስጥ ካልገኘ መተግበሪያው ያሳውቃል።';
const String _fallbackNumberAccess =
    'ከታች “ቁጥር”ን ይንኩ፤ የመዝሙሩን ቁጥር ካስገቡ በኋላ “ክፈት”ን ይጫኑ።';
const String _fallbackNumberBullet1 = 'በቁጥር መፈለግ';
const String _fallbackNumberBullet2 = 'በቀጥታ መክፈት';
const String _fallbackNumberBullet3 = 'ግጥሙን ማንበብ';
const String _fallbackIndexTitle = 'በማውጫ ይፈልጉ';
const String _fallbackIndexBody =
    'ማውጫ መዝሙሮችን በቁጥር ወይም በርዕስ ቅደም ተከተል ያሳያል። በተጨማሪም በፍለጋ ሳጥኑ ውስጥ በርዕስ፣ በእንግሊዝኛ '
    'ርዕስ ወይም በግጥም ቃላት መፈለግ ይችላሉ።';
const String _fallbackIndexAccess =
    'ከታች “ማውጫ”ን ይንኩ። የፍለጋ ምልክቱን በመንካት መፈለግ፣ ወይም የአደራደር አዝራሩን በመንካት በቁጥር አሊያም '
    'በርዕስ ቅደም ተከተል ማስተካከል ይችላሉ።';
const String _fallbackIndexBullet1 = 'በርዕስ';
const String _fallbackIndexBullet2 = 'በግጥም';
const String _fallbackIndexBullet3 = 'በቁጥር ወይም በፊደል';
const String _fallbackCategoryTitle = 'በምድብ ያግኙ';
const String _fallbackCategoryBody =
    'ምድቦች መዝሙሮችን እንደ ምስጋና፣ ጸሎት፣ ሰንበት፣ ጋብቻ እና ተስፋ በርዕሰ ጉዳይ ያደራጃሉ።';
const String _fallbackCategoryAccess =
    'ከታች “ምድብ”ን ይንኩና የሚፈልጉትን ምድብ ይምረጡ፤ ከዚያም በምድቡ ሥር የተካተቱት መዝሙሮች ይዘረዘራሉ።';
const String _fallbackCategoryBullet1 = 'ምስጋና';
const String _fallbackCategoryBullet2 = 'ጸሎት';
const String _fallbackCategoryBullet3 = 'ጋብቻ';
const String _fallbackHymnTitle = 'ግጥም፣ ድምፅ እና ኖታ';
const String _fallbackHymnBody =
    'የመዝሙሩ ገጽ ቁጥሩን፣ የአማርኛና የእንግሊዝኛ ርዕሱን እንዲሁም ሙሉ ግጥሙን ያሳያል። ድምፅ ሲኖረው ከዚያው ማጫወት፣ '
    'የሙዚቃ ኖታ ሲኖረውም በሙሉ ገጽ መክፈት ይችላሉ።';
const String _fallbackHymnAccess =
    'ከማንኛውም የመዝሙር ዝርዝር ውስጥ የሚፈልጉትን መዝሙር ይንኩ። የልብ ምልክቱን በመንካት ወደ ተወዳጅ መዝሙሮች ማከል፣ '
    'የኖታ ምልክቱን በመንካት ደግሞ ኖታውን መክፈት ይችላሉ።';
const String _fallbackHymnBullet1 = 'ግጥም ማንበብ';
const String _fallbackHymnBullet2 = 'ድምፅ መጫወት';
const String _fallbackHymnBullet3 = 'ኖታ መክፈት';
const String _fallbackSettingsTitle = 'ቅንብሮችን ያስተካክሉ';
const String _fallbackSettingsBody =
    'ከቅንብሮች ገጽ የመዝሙር ስብስብን፣ የፊደል መጠንን፣ የጀርባ ምስልን፣ ማያ እንዳይጠፋ ማድረግን፣ የልገሳ ድጋፍን እና '
    'የስህተት ጥቆማን ያገኛሉ።';
const String _fallbackSettingsAccess =
    'ከታች “ቅንብሮች”ን ይንኩ። የ2004፣ የ1975 ወይም የ1961 ውዳሴ መዝሙርን አሊያም የሀገርኛ መዝሙር ስብስብን '
    'ለመቀየር የስብስብ ምርጫውን ይጠቀሙ።';
const String _fallbackSettingsBullet1 = 'የመዝሙር ስብስብ';
const String _fallbackSettingsBullet2 = 'የፊደል መጠን';
const String _fallbackSettingsBullet3 = 'የስህተት ጥቆማ';

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
