import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/library/migration/match_scoring.dart';
import 'package:sumizuri/features/library/models/library_feed_types.dart';
import 'package:sumizuri/features/library/models/library_types.dart';

enum MigrationStatus {
  queued,
  searching,

  found,

  review,

  notFound,
  moved,
  failed,
}

class MigrationOption {
  const MigrationOption({
    required this.entry,
    required this.chapters,
    required this.score,
  });

  final MEntry entry;
  final List<MChapter> chapters;
  final MigrationScore score;
}

class MigrationItem {
  const MigrationItem({
    required this.entryId,
    required this.title,
    required this.coverUrl,
    required this.mediaType,
    required this.subject,
    this.status = MigrationStatus.queued,
    this.options = const [],
    this.chosen,
    this.error,
    this.outcome,
  });

  final int entryId;
  final String title;
  final String? coverUrl;
  final MediaType mediaType;
  final MigrationSubject subject;
  final MigrationStatus status;

  final List<MigrationOption> options;
  final MigrationOption? chosen;
  final String? error;
  final MoveOutcome? outcome;

  MigrationItem copyWith({
    MigrationStatus? status,
    List<MigrationOption>? options,
    MigrationOption? Function()? chosen,
    String? Function()? error,
    MoveOutcome? outcome,
  }) => MigrationItem(
    entryId: entryId,
    title: title,
    coverUrl: coverUrl,
    mediaType: mediaType,
    subject: subject,
    status: status ?? this.status,
    options: options ?? this.options,
    chosen: chosen == null ? this.chosen : chosen(),
    error: error == null ? this.error : error(),
    outcome: outcome ?? this.outcome,
  );
}

class MigrationState {
  const MigrationState({
    this.items = const [],
    this.targetName,
    this.targetSourceId,
    this.running = false,
    this.cancelRequested = false,
    this.processed = 0,
    this.total = 0,
  });

  final List<MigrationItem> items;

  final String? targetName;
  final String? targetSourceId;
  final bool running;
  final bool cancelRequested;

  final int processed;
  final int total;

  List<MigrationItem> withStatus(MigrationStatus status) => [
    for (final item in items)
      if (item.status == status) item,
  ];

  MigrationState copyWith({
    List<MigrationItem>? items,
    String? targetName,
    String? targetSourceId,
    bool? running,
    bool? cancelRequested,
    int? processed,
    int? total,
  }) => MigrationState(
    items: items ?? this.items,
    targetName: targetName ?? this.targetName,
    targetSourceId: targetSourceId ?? this.targetSourceId,
    running: running ?? this.running,
    cancelRequested: cancelRequested ?? this.cancelRequested,
    processed: processed ?? this.processed,
    total: total ?? this.total,
  );
}
