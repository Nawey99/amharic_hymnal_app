import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';

/// What a report is about. The admin inbox filters and sorts by it, so
/// the user picks one.
enum ReportType {
  lyrics('LYRICS'),
  sheetMusic('SHEET_MUSIC'),
  audio('AUDIO'),
  appBug('APP_BUG'),
  suggestion('SUGGESTION'),
  other('OTHER');

  const ReportType(this.apiValue);

  /// The value `POST /reports` expects as `category`.
  final String apiValue;

  /// What to call this on screen, in the app's language.
  ///
  /// A name is a thing to read, so it is chosen where there is a reader
  /// rather than stored on the enum in one language.
  String labelFor(AppLocalizations? l) => switch (this) {
        ReportType.lyrics => l?.reportTypeLyrics ?? 'የግጥም ስህተት',
        ReportType.sheetMusic => l?.reportTypeSheet ?? 'የኖታ ስህተት',
        ReportType.audio => l?.reportTypeAudio ?? 'የድምፅ ችግር',
        ReportType.appBug => l?.reportTypeApp ?? 'የመተግበሪያ ችግር',
        ReportType.suggestion => l?.reportTypeSuggestion ?? 'የማሻሻያ ሐሳብ',
        ReportType.other => l?.reportTypeOther ?? 'ሌላ',
      };
}

class BugReportPayload {
  final String title;
  final String description;
  final String? contactEmail;
  final String severity;
  final ReportType type;

  /// The API ID of the hymn the report is about, e.g. `am-sda-1975-0130`.
  final String? songId;

  /// Where in the app the report was written, e.g. `hymn` or `settings`.
  final String screen;
  final Map<String, dynamic> diagnostics;

  const BugReportPayload({
    required this.title,
    required this.description,
    this.contactEmail,
    this.severity = 'normal',
    this.type = ReportType.appBug,
    this.songId,
    this.screen = 'settings',
    this.diagnostics = const {},
  });

  /// [diagnostics] plus the report's type, hymn and screen, which travel
  /// with it through the offline queue.
  Map<String, dynamic> get queuedDiagnostics => {
        ...diagnostics,
        'reportCategory': type.apiValue,
        if (songId != null) 'songId': songId,
        'screen': screen,
      };
}

class BugReportSubmissionResult {
  final bool submitted;
  final bool queued;

  /// No message: a repository does not choose words. [submitted] and
  /// [queued] say what happened, and the page says it in the reader's
  /// language.
  const BugReportSubmissionResult({
    required this.submitted,
    required this.queued,
  });

  bool get isSuccess => submitted || queued;
}

abstract class BugReportRepository {
  Future<BugReportSubmissionResult> submit(BugReportPayload payload);
}
