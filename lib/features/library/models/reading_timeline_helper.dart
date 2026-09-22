import 'package:sumizuri/features/library/models/reading_session_record.dart';

List<ReadingTimelineBurst> groupSessionsIntoBursts(
  List<ReadingSessionRecord> sessions,
) {
  if (sessions.isEmpty) return const [];

  final chronological = [...sessions]
    ..sort((a, b) {
      final cmp = a.readAt.compareTo(b.readAt);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });

  final seenUnitIds = <int>{};
  final taggedSessions = <_TaggedSession>[];

  for (final s in chronological) {
    final isReRead = seenUnitIds.contains(s.contentUnitId);
    seenUnitIds.add(s.contentUnitId);
    taggedSessions.add(_TaggedSession(session: s, isReRead: isReRead));
  }

  taggedSessions.sort((a, b) {
    final cmp = b.session.readAt.compareTo(a.session.readAt);
    if (cmp != 0) return cmp;
    return b.session.id.compareTo(a.session.id);
  });

  final builders = <(int, int, int, int, bool), _BurstBuilder>{};

  for (final tagged in taggedSessions) {
    final s = tagged.session;
    final key = (
      s.libraryEntryId,
      s.readAt.year,
      s.readAt.month,
      s.readAt.day,
      tagged.isReRead,
    );
    final dateKey = DateTime(s.readAt.year, s.readAt.month, s.readAt.day);

    final builder = builders.putIfAbsent(
      key,
      () => _BurstBuilder(
        libraryEntryId: s.libraryEntryId,
        entryTitle: s.entryTitle,
        entryCoverUrl: s.entryCoverUrl,
        customCoverPath: s.customCoverPath,
        sourceId: s.sourceId,
        externalId: s.externalId,
        date: dateKey,
        isReRead: tagged.isReRead,
      ),
    );
    builder.add(s);
  }

  return builders.values.map((b) => b.build()).toList();
}

class _TaggedSession {
  const _TaggedSession({required this.session, required this.isReRead});

  final ReadingSessionRecord session;
  final bool isReRead;
}

class _BurstBuilder {
  _BurstBuilder({
    required this.libraryEntryId,
    required this.entryTitle,
    required this.entryCoverUrl,
    required this.customCoverPath,
    required this.sourceId,
    required this.externalId,
    required this.date,
    required this.isReRead,
  });

  final int libraryEntryId;
  final String entryTitle;
  final String? entryCoverUrl;
  final String? customCoverPath;
  final String sourceId;
  final String externalId;
  final DateTime date;
  final bool isReRead;

  final List<double> _chapterNumbers = [];
  DateTime? _lastReadAt;
  String? _latestChapterUrl;
  String? _latestChapterTitle;

  void add(ReadingSessionRecord s) {
    _chapterNumbers.add(s.chapterNumber);
    if (_lastReadAt == null || s.readAt.isAfter(_lastReadAt!)) {
      _lastReadAt = s.readAt;
      _latestChapterUrl = s.chapterUrl;
      _latestChapterTitle = s.chapterTitle;
    }
  }

  ReadingTimelineBurst build() {
    final uniqueChapters = _chapterNumbers.toSet().toList()..sort();
    return ReadingTimelineBurst(
      libraryEntryId: libraryEntryId,
      entryTitle: entryTitle,
      entryCoverUrl: entryCoverUrl,
      customCoverPath: customCoverPath,
      sourceId: sourceId,
      externalId: externalId,
      date: date,
      isReRead: isReRead,
      chapterNumbers: uniqueChapters,
      lastReadAt: _lastReadAt ?? date,
      latestChapterUrl: _latestChapterUrl,
      latestChapterTitle: _latestChapterTitle,
    );
  }
}
