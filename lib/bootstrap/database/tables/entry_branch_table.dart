// Drift table for a library entry's branches, such as alternate translations.
import 'package:drift/drift.dart';

import 'package:sumizuri/bootstrap/startup/client_id.dart';

import 'package:sumizuri/bootstrap/database/tables/library_entry_table.dart';

@TableIndex(name: 'idx_entry_branches_entry', columns: {#libraryEntryId})
@TableIndex(
  name: 'idx_entry_branches_client_id',
  columns: {#clientId},
  unique: true,
)
@TableIndex(name: 'idx_entry_branches_updated_at', columns: {#updatedAt})
class EntryBranches extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get clientId =>
      integer().nullable().clientDefault(generateClientId)();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get libraryEntryId =>
      integer().references(LibraryEntries, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
