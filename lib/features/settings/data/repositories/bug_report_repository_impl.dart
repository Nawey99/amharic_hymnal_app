import 'package:amharic_hymnal_app/core/services/bug_report_queue_service.dart';
import 'package:amharic_hymnal_app/features/settings/domain/repositories/bug_report_repository.dart';

typedef BugReportSubmitter = Future<bool> Function(BugReportPayload payload);
typedef BugReportQueuer = Future<bool> Function(BugReportPayload payload);

class BugReportRepositoryImpl implements BugReportRepository {
  final BugReportSubmitter _submitter;
  final BugReportQueuer _queuer;

  BugReportRepositoryImpl({
    BugReportSubmitter? submitter,
    BugReportQueuer? queuer,
  })  : _submitter = submitter ?? _submitWithQueueService,
        _queuer = queuer ?? _queueWithQueueService;

  @override
  Future<BugReportSubmissionResult> submit(BugReportPayload payload) async {
    try {
      final submitted = await _submitter(payload);
      if (submitted) {
        return const BugReportSubmissionResult(
          submitted: true,
          queued: false,
          message: 'የስህተት ሪፖርት ተልኳል!',
        );
      }

      final queued = await _queuer(payload);
      return BugReportSubmissionResult(
        submitted: false,
        queued: queued,
        message: queued
            ? 'ሪፖርቱ ተቀምጧል። ኢንተርኔት ሲኖር ይላካል።'
            : 'የስህተት ሪፖርት መላክ አልተቻለም። እባክዎ እንደገና ይሞክሩ።',
      );
    } catch (_) {
      final queued = await _queuer(payload);
      return BugReportSubmissionResult(
        submitted: false,
        queued: queued,
        message: queued
            ? 'ሪፖርቱ ተቀምጧል። ኢንተርኔት ሲኖር ይላካል።'
            : 'የስህተት ሪፖርት መላክ አልተቻለም። እባክዎ እንደገና ይሞክሩ።',
      );
    }
  }

  static Future<bool> _submitWithQueueService(
    BugReportPayload payload,
  ) {
    return BugReportQueueService.instance.submitBugReport(
      payload.title,
      payload.description,
      contactEmail: payload.contactEmail,
      severity: payload.severity,
      diagnostics: payload.diagnostics,
    );
  }

  static Future<bool> _queueWithQueueService(
    BugReportPayload payload,
  ) {
    return BugReportQueueService.instance.queueBugReport(
      payload.title,
      payload.description,
      contactEmail: payload.contactEmail,
      severity: payload.severity,
      diagnostics: payload.diagnostics,
    );
  }
}
