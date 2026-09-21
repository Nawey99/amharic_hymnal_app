/// What a report is about. The admin inbox filters and sorts by it, so
/// the user picks one.
enum ReportType {
  lyrics('LYRICS', 'የግጥም ስህተት'),
  sheetMusic('SHEET_MUSIC', 'የኖታ ስህተት'),
  audio('AUDIO', 'የድምፅ ችግር'),
  appBug('APP_BUG', 'የመተግበሪያ ችግር'),
  suggestion('SUGGESTION', 'ሀሳብ'),
  other('OTHER', 'ሌላ');

  const ReportType(this.apiValue, this.label);

  /// The value `POST /reports` expects as `category`.
  final String apiValue;
  final String label;
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
  final String message;

  const BugReportSubmissionResult({
    required this.submitted,
    required this.queued,
    required this.message,
  });

  bool get isSuccess => submitted || queued;
}

abstract class BugReportRepository {
  Future<BugReportSubmissionResult> submit(BugReportPayload payload);
}
