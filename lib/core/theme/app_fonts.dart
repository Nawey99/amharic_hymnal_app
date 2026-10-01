import 'dart:ui' show Locale;

/// The two faces the app reads in, and the rule for which one a piece of
/// text gets.
///
/// Amharic is set in Noto Sans Ethiopic and English in Noto Serif. The two
/// are chosen per script rather than per widget, so no screen has to know
/// about fonts: the interface follows the app's language, and an English
/// hymn title is in the serif face whichever language the interface is in.
abstract final class AppFonts {
  /// Amharic. Also carries Latin, which is why English had to be pointed at
  /// the serif face deliberately rather than by fallback.
  static const String ethiopic = 'NotoSansEthiopic';

  /// English. Carries no Ethiopic at all, hence [ethiopicFallback].
  static const String serif = 'NotoSerif';

  /// The weight ordinary text is set in. The app ships a real SemiBold, so
  /// this is a file rather than a smeared Regular.
  static const int bodyWeightValue = 600;

  /// What English falls back to, so an Amharic word inside an English line
  /// still has glyphs to draw with.
  static const List<String> ethiopicFallback = <String>[ethiopic];

  /// What Amharic falls back to. Noto Sans Ethiopic already covers Latin, so
  /// this only matters for characters neither face has.
  static const List<String> serifFallback = <String>[serif];

  /// True when the interface is being read in English.
  static bool isEnglish(Locale? locale) => locale?.languageCode == 'en';

  /// The face the interface reads in, for the language it is set to.
  static String uiFamily(Locale? locale) =>
      isEnglish(locale) ? serif : ethiopic;

  /// The fallback that goes with [uiFamily].
  static List<String> uiFallback(Locale? locale) =>
      isEnglish(locale) ? ethiopicFallback : serifFallback;
}
