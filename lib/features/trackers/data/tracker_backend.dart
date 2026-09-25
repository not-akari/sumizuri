import 'package:sumizuri/features/trackers/data/oauth_loopback_listener.dart';
import 'package:sumizuri/features/trackers/models/tracker_exception.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';

/// What the tracker pages need from a tracker, whichever one it is. Anything
/// that goes wrong is thrown as a [TrackerException]; the page puts it in words.
abstract interface class TrackerBackend {
  TrackerKind get kind;

  /// False in a build made without the tracker's client id or secret.
  bool get configured;

  /// The connected account, or null when nobody is.
  Future<TrackerAccountInfo?> account(int profileId);

  /// The numbers of both lists. [entries] reads a list for trackers that have
  /// to work a number out from it.
  Future<TrackerStats> stats(
    int profileId,
    Future<List<TrackerEntry>> Function(TrackerMedia media) entries,
  );

  /// The whole list of one kind, as the tracker has it.
  Future<List<TrackerEntry>> entries(int profileId, TrackerMedia media);

  /// Looks a title up by name, to link a library entry to it. [novel] narrows a
  /// manga search to novels, or, when false, leaves them out.
  Future<List<TrackerSearchResult>> search(
    int profileId,
    String query, {
    required TrackerMedia media,
    bool novel = false,
  });

  /// What the tracker holds for one title: its length and the account's entry,
  /// or null when the tracker no longer has the title.
  Future<TrackerRemoteState?> remote(
    int profileId,
    TrackerMedia media,
    int mediaId,
  );

  Future<void> save(int profileId, TrackerEntryUpdate update);

  Future<void> remove(int profileId, TrackerEntry entry);

  /// Opens the tracker's sign-in page and waits for the person to come back.
  /// Null when they did not, or refused.
  Future<TrackerAccountInfo?> login(
    int profileId, {
    required OAuthPageText page,
  });

  void cancelLogin();

  Future<void> logout(int profileId);

  /// Sends what is waiting in the outbox.
  Future<TrackerFlushResult> flush(int profileId, {bool force = false});

  Future<void> flushAll({bool force = false});
}
