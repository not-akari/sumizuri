// Drift table for a library entry, the root record for a tracked series.
import 'package:drift/drift.dart';

import 'package:sumizuri/bootstrap/startup/client_id.dart';

import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/bootstrap/database/tables/entry_branch_table.dart';
import 'package:sumizuri/bootstrap/database/tables/profile_table.dart';

@TableIndex(name: 'idx_library_entries_source', columns: {#sourceId})
@TableIndex(
  name: 'idx_library_entries_client_id',
  columns: {#clientId},
  unique: true,
)
@TableIndex(name: 'idx_library_entries_updated_at', columns: {#updatedAt})
@TableIndex(
  name: 'idx_library_entries_active_branch',
  columns: {#activeBranchId},
)
class LibraryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Sync identity, stable across devices and never reused.
  IntColumn get clientId =>
      integer().nullable().clientDefault(generateClientId)();

  // Epoch ms of the last change, and 0 means never stamped.
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get activeBranchId => integer().nullable().references(
    EntryBranches,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get profileId => integer()
      .references(Profiles, #id, onDelete: KeyAction.cascade)
      .withDefault(const Constant(1))();

  TextColumn get title => text()();
  TextColumn get coverUrl => text().nullable()();

  IntColumn get mediaType => intEnum<MediaType>()();

  TextColumn get sourceId => text()();

  TextColumn get excludedScanlators => text().nullable()();

  TextColumn get sourceKey => text().nullable()();
  TextColumn get externalId => text()();

  BoolColumn get favorite => boolean().withDefault(const Constant(false))();

  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastUpdatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  IntColumn get readerMode => intEnum<ReaderMode>().nullable()();

  /// Whether auto-detection has already run for this entry.
  BoolColumn get readerModeChecked =>
      boolean().withDefault(const Constant(false))();

  /// Two-page layout chosen for this series alone. Null follows the app setting.
  IntColumn get readerDualPageMode =>
      intEnum<ReaderDualPageMode>().nullable()();

  /// Settings this series keeps for itself as JSON. Null follows the app settings.
  TextColumn get settingsOverrides => text().nullable()();

  TextColumn get customCoverPath => text().nullable()();

  TextColumn get status => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {profileId, sourceId, externalId},
  ];
}
