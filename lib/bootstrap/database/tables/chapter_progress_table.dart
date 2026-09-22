// Drift table for per branch chapter read state and reading progress.
import 'package:drift/drift.dart';

import 'package:sumizuri/bootstrap/startup/client_id.dart';

import 'package:sumizuri/bootstrap/database/tables/content_unit_table.dart';
import 'package:sumizuri/bootstrap/database/tables/entry_branch_table.dart';

@TableIndex(
  name: 'idx_chapter_progress_branch',
  columns: {#branchId, #consumed, #consumedAt},
)
@TableIndex(
  name: 'idx_chapter_progress_client_id',
  columns: {#clientId},
  unique: true,
)
@TableIndex(name: 'idx_chapter_progress_updated_at', columns: {#updatedAt})
class ChapterProgress extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get clientId =>
      integer().nullable().clientDefault(generateClientId)();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get contentUnitId =>
      integer().references(ContentUnits, #id, onDelete: KeyAction.cascade)();
  IntColumn get branchId =>
      integer().references(EntryBranches, #id, onDelete: KeyAction.cascade)();
  BoolColumn get consumed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get consumedAt => dateTime().nullable()();
  RealColumn get progressPosition => real().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {contentUnitId, branchId},
  ];
}
