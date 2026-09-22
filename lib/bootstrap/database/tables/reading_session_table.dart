// Drift table recording each time a chapter is read, used for history and statistics.
import 'package:drift/drift.dart';

import 'package:sumizuri/bootstrap/startup/client_id.dart';

import 'package:sumizuri/bootstrap/database/tables/content_unit_table.dart';
import 'package:sumizuri/bootstrap/database/tables/entry_branch_table.dart';
import 'package:sumizuri/bootstrap/database/tables/library_entry_table.dart';

@TableIndex(
  name: 'idx_reading_sessions_entry_time',
  columns: {#libraryEntryId, #readAt},
)
@TableIndex(name: 'idx_reading_sessions_time', columns: {#readAt})
@TableIndex(
  name: 'idx_reading_sessions_client_id',
  columns: {#clientId},
  unique: true,
)
@TableIndex(name: 'idx_reading_sessions_updated_at', columns: {#updatedAt})
class ReadingSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get clientId =>
      integer().nullable().clientDefault(generateClientId)();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  IntColumn get libraryEntryId =>
      integer().references(LibraryEntries, #id, onDelete: KeyAction.cascade)();

  IntColumn get contentUnitId =>
      integer().references(ContentUnits, #id, onDelete: KeyAction.cascade)();

  IntColumn get branchId => integer().nullable().references(
    EntryBranches,
    #id,
    onDelete: KeyAction.cascade,
  )();

  DateTimeColumn get readAt => dateTime().withDefault(currentDateAndTime)();
}
