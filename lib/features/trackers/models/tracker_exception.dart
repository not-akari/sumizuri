import 'package:sumizuri/features/trackers/models/tracker_models.dart';

/// What went wrong talking to a tracker. The page turns it into words in the
/// person's language; nothing here is text to show.
enum TrackerProblem {
  /// The build has no client key for the tracker.
  notConfigured,
  notConnected,
  loginExpired,
  loginFailed,
  busy,
  notFound,

  /// The tracker no longer has a title that was linked to it.
  titleGone,
  network,
  refused,
  searchTooShort,
  unknown,
}

/// Thrown by a tracker backend for anything a person should be told about.
class TrackerException implements Exception {
  const TrackerException(
    this.problem,
    this.tracker, {
    this.status,
    this.detail,
    this.cause,
  });

  final TrackerProblem problem;
  final TrackerKind tracker;

  /// The HTTP status, when the tracker refused with one.
  final int? status;

  /// What the tracker itself said, when it said something worth showing.
  final String? detail;
  final Object? cause;

  /// For logs only.
  @override
  String toString() =>
      '${tracker.label}: ${problem.name}'
      '${status == null ? '' : ' ($status)'}'
      '${detail == null ? '' : ': $detail'}';
}
