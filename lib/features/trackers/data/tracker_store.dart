import 'package:drift/drift.dart';

import 'package:sumizuri/bootstrap/database/app_database.dart';

const _tracker = 'anilist';

/// Nothing is retried forever.
const maxSendAttempts = 8;

class TrackerLink {
  const TrackerLink({
    required this.id,
    required this.libraryEntryId,
    required this.mediaId,
    required this.title,
    this.chapters,
  });

  final int id;
  final int libraryEntryId;
  final int mediaId;
  final String title;
  final int? chapters;
}

class PendingTitle {
  const PendingTitle({
    required this.linkId,
    required this.libraryEntryId,
    required this.mediaId,
    required this.version,
    required this.firstQueuedAt,
    required this.attempts,
  });

  final int linkId;
  final int libraryEntryId;
  final int mediaId;

  final int version;
  final int firstQueuedAt;
  final int attempts;
}

/// A title waiting to be sent, whether or not it is due, with what went wrong last time.
class QueuedTitle {
  const QueuedTitle({
    required this.linkId,
    required this.libraryEntryId,
    required this.mediaId,
    required this.title,
    required this.firstQueuedAt,
    required this.attempts,
    required this.nextTryAt,
    this.lastError,
  });

  final int linkId;
  final int libraryEntryId;
  final int mediaId;
  final String title;
  final int firstQueuedAt;
  final int attempts;
  final int nextTryAt;
  final String? lastError;
}

class TrackerStore {
  TrackerStore(this._db, {int Function()? now})
    : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase _db;
  final int Function() _now;

  Future<TrackerLink?> linkFor(int libraryEntryId) async {
    final row =
        await (_db.select(_db.trackerLinks)..where(
              (t) =>
                  t.libraryEntryId.equals(libraryEntryId) &
                  t.tracker.equals(_tracker),
            ))
            .getSingleOrNull();
    return row == null ? null : _toLink(row);
  }

  /// With [queue] false it links without telling AniList, as in an import.
  Future<void> link({
    required int libraryEntryId,
    required int mediaId,
    required String title,
    int? chapters,
    bool queue = true,
  }) => _db.transaction(() async {
    await _db
        .into(_db.trackerLinks)
        .insert(
          TrackerLinksCompanion.insert(
            libraryEntryId: libraryEntryId,
            remoteMediaId: mediaId,
            remoteTitle: title,
            remoteChapters: Value(chapters),
          ),
          onConflict: DoUpdate(
            (_) => TrackerLinksCompanion(
              remoteMediaId: Value(mediaId),
              remoteTitle: Value(title),
              remoteChapters: Value(chapters),
              linkedAt: Value(DateTime.now()),
            ),
            target: [_db.trackerLinks.libraryEntryId, _db.trackerLinks.tracker],
          ),
        );
    if (!queue) return;
    final link = (await linkFor(libraryEntryId))!;
    await _queue(link.id);
  });

  /// Asks for a title's progress to be sent at the next chance.
  Future<void> queueLink(int linkId) => _queue(linkId);

  /// Every queued title of the profile, due or not, oldest first.
  Future<List<QueuedTitle>> queue(int profileId) async {
    final rows = await _db
        .customSelect(
          'SELECT o.link_id, o.first_queued_at, o.attempts, o.last_error, '
          'o.next_try_at, tl.library_entry_id, tl.remote_media_id, e.title '
          'FROM tracker_outbox o '
          'JOIN tracker_links tl ON tl.id = o.link_id '
          'JOIN library_entries e ON e.id = tl.library_entry_id '
          'WHERE e.profile_id = ? ORDER BY o.first_queued_at',
          variables: [Variable.withInt(profileId)],
        )
        .get();
    return [
      for (final row in rows)
        QueuedTitle(
          linkId: row.read<int>('link_id'),
          libraryEntryId: row.read<int>('library_entry_id'),
          mediaId: row.read<int>('remote_media_id'),
          title: row.read<String>('title'),
          firstQueuedAt: row.read<int>('first_queued_at'),
          attempts: row.read<int>('attempts'),
          nextTryAt: row.read<int>('next_try_at'),
          lastError: row.readNullable<String>('last_error'),
        ),
    ];
  }

  /// Takes a title out of the queue without sending it.
  Future<void> discard(int linkId) => _db.customStatement(
    'DELETE FROM tracker_outbox WHERE link_id = ?',
    [linkId],
  );

  /// Makes everything queued due now, so "send now" also takes ones waiting out a failure.
  Future<void> makeAllDue(int profileId) => _db.customStatement(
    'UPDATE tracker_outbox SET next_try_at = 0 WHERE link_id IN ('
    'SELECT tl.id FROM tracker_links tl '
    'JOIN library_entries e ON e.id = tl.library_entry_id '
    'WHERE e.profile_id = ?)',
    [profileId],
  );

  /// The titles of the profile linked to AniList: media id to library entry and link.
  Future<Map<int, ({int libraryEntryId, int linkId})>> linkedTitles(
    int profileId,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT tl.id AS link_id, tl.library_entry_id, tl.remote_media_id '
          'FROM tracker_links tl '
          'JOIN library_entries e ON e.id = tl.library_entry_id '
          'WHERE e.profile_id = ? AND tl.tracker = ?',
          variables: [
            Variable.withInt(profileId),
            Variable.withString(_tracker),
          ],
        )
        .get();
    return {
      for (final row in rows)
        row.read<int>('remote_media_id'): (
          libraryEntryId: row.read<int>('library_entry_id'),
          linkId: row.read<int>('link_id'),
        ),
    };
  }

  Future<void> unlink(int libraryEntryId) =>
      (_db.delete(_db.trackerLinks)..where(
            (t) =>
                t.libraryEntryId.equals(libraryEntryId) &
                t.tracker.equals(_tracker),
          ))
          .go();

  Future<void> _queue(int linkId) => _db.customStatement(
    'INSERT INTO tracker_outbox (link_id, first_queued_at) VALUES (?, ?) '
    'ON CONFLICT(link_id) DO UPDATE SET version = version + 1',
    [linkId, _now()],
  );

  Future<List<PendingTitle>> pending(int profileId) async {
    final rows = await _db
        .customSelect(
          'SELECT o.link_id, o.version, o.first_queued_at, o.attempts, '
          'tl.library_entry_id, tl.remote_media_id '
          'FROM tracker_outbox o '
          'JOIN tracker_links tl ON tl.id = o.link_id '
          'JOIN library_entries e ON e.id = tl.library_entry_id '
          'WHERE e.profile_id = ? AND o.next_try_at <= ? '
          'ORDER BY o.first_queued_at',
          variables: [Variable.withInt(profileId), Variable.withInt(_now())],
        )
        .get();
    return [
      for (final row in rows)
        PendingTitle(
          linkId: row.read<int>('link_id'),
          libraryEntryId: row.read<int>('library_entry_id'),
          mediaId: row.read<int>('remote_media_id'),
          version: row.read<int>('version'),
          firstQueuedAt: row.read<int>('first_queued_at'),
          attempts: row.read<int>('attempts'),
        ),
    ];
  }

  Future<bool> isQueued(int libraryEntryId) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS n FROM tracker_outbox o '
          'JOIN tracker_links tl ON tl.id = o.link_id '
          'WHERE tl.library_entry_id = ?',
          variables: [Variable.withInt(libraryEntryId)],
        )
        .getSingle();
    return row.read<int>('n') > 0;
  }

  Future<List<int>> profilesWithPending() async {
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT e.profile_id AS profile_id FROM tracker_outbox o '
          'JOIN tracker_links tl ON tl.id = o.link_id '
          'JOIN library_entries e ON e.id = tl.library_entry_id',
        )
        .get();
    return [for (final row in rows) row.read<int>('profile_id')];
  }

  Future<int> localProgress(int libraryEntryId) async {
    final row = await _db
        .customSelect(
          'SELECT MAX(cu.number) AS n FROM chapter_progress cp '
          'JOIN content_units cu ON cu.id = cp.content_unit_id '
          'WHERE cu.library_entry_id = ?1 AND cp.consumed = 1 AND '
          '(cp.branch_id = (SELECT active_branch_id FROM library_entries WHERE id = ?1) '
          'OR (SELECT active_branch_id FROM library_entries WHERE id = ?1) IS NULL)',
          variables: [Variable.withInt(libraryEntryId)],
        )
        .getSingle();
    final n = row.read<double?>('n');
    return n == null ? 0 : n.floor();
  }

  Future<void> updateChapters(int linkId, int? chapters) =>
      (_db.update(_db.trackerLinks)..where((t) => t.id.equals(linkId))).write(
        TrackerLinksCompanion(remoteChapters: Value(chapters)),
      );

  Future<void> markSent(int linkId, int version) async {
    final removed = await _db.customUpdate(
      'DELETE FROM tracker_outbox WHERE link_id = ? AND version = ?',
      variables: [Variable.withInt(linkId), Variable.withInt(version)],
      updates: {_db.trackerOutbox},
      updateKind: UpdateKind.delete,
    );
    if (removed == 0) {
      await _db.customStatement(
        'UPDATE tracker_outbox SET first_queued_at = ?, attempts = 0, '
        'last_error = NULL, next_try_at = 0 WHERE link_id = ?',
        [_now(), linkId],
      );
    }
  }

  Future<void> markFailed(int linkId, int attempts, String message) async {
    final next = attempts + 1;
    if (next >= maxSendAttempts) {
      await _db.customStatement(
        'DELETE FROM tracker_outbox WHERE link_id = ?',
        [linkId],
      );
      return;
    }
    final minutes = (1 << next).clamp(1, 60);
    await _db.customStatement(
      'UPDATE tracker_outbox SET attempts = ?, last_error = ?, next_try_at = ? '
      'WHERE link_id = ?',
      [next, message, _now() + minutes * 60000, linkId],
    );
  }

  Future<void> deferAll(int profileId, DateTime retryAt) => _db.customStatement(
    'UPDATE tracker_outbox SET next_try_at = ? WHERE link_id IN ('
    'SELECT tl.id FROM tracker_links tl '
    'JOIN library_entries e ON e.id = tl.library_entry_id '
    'WHERE e.profile_id = ?)',
    [retryAt.millisecondsSinceEpoch, profileId],
  );

  TrackerLink _toLink(TrackerLinkRow row) => TrackerLink(
    id: row.id,
    libraryEntryId: row.libraryEntryId,
    mediaId: row.remoteMediaId,
    title: row.remoteTitle,
    chapters: row.remoteChapters,
  );
}
