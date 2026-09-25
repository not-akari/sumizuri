import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/features/trackers/models/tracker_exception.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// A problem in the person's language.
String trackerProblemText(
  AppLocalizations l10n,
  TrackerKind tracker,
  TrackerProblem problem, {
  int? status,
  String? detail,
}) {
  final name = tracker.label;
  return switch (problem) {
    TrackerProblem.notConfigured => l10n.trackerNotConfigured(name),
    TrackerProblem.notConnected => l10n.trackerProblemNotConnected(name),
    TrackerProblem.loginExpired => l10n.trackerProblemLoginExpired(name),
    TrackerProblem.loginFailed => l10n.trackerProblemLoginFailed(name),
    TrackerProblem.busy => l10n.trackerProblemBusy(name),
    TrackerProblem.notFound => l10n.trackerProblemNotFound(name),
    TrackerProblem.titleGone => l10n.trackerProblemTitleGone(name),
    TrackerProblem.network => l10n.trackerProblemNetwork(name),
    TrackerProblem.refused =>
      // What the tracker said itself is the most useful thing to show.
      detail ??
          (status == null
              ? l10n.trackerProblemRefused(name)
              : l10n.trackerProblemRefusedStatus(name, status)),
    TrackerProblem.searchTooShort => l10n.trackerProblemSearchTooShort(name),
    TrackerProblem.unknown => detail ?? l10n.trackerProblemUnknown(name),
  };
}

/// Whatever was thrown while talking to [kind], in the person's language.
String trackerReason(AppLocalizations l10n, TrackerKind kind, Object error) {
  if (error is TrackerException) {
    return trackerProblemText(
      l10n,
      error.tracker,
      error.problem,
      status: error.status,
      detail: error.detail,
    );
  }
  if (error is AppFailure) return error.displayMessage;
  return l10n.trackerProblemUnknown(kind.label);
}

/// A reason kept with a queued title. Ours are stored as a [TrackerProblem]
/// name; anything else is what the tracker itself said and is shown as it is.
String trackerStoredError(
  AppLocalizations l10n,
  TrackerKind kind,
  String stored,
) {
  final problem = TrackerProblem.values.asNameMap()[stored];
  return problem == null ? stored : trackerProblemText(l10n, kind, problem);
}
