class BugReportPayload {
  final String title;
  final String description;
  final String? contactEmail;
  final String severity;
  final Map<String, dynamic> diagnostics;

  const BugReportPayload({
    required this.title,
    required this.description,
    this.contactEmail,
    this.severity = 'normal',
    this.diagnostics = const {},
  });
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
