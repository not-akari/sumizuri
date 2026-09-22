import 'package:drift/drift.dart';

import 'package:sumizuri/bootstrap/startup/client_id.dart';

import 'package:sumizuri/bootstrap/database/tables/library_entry_table.dart';

@TableIndex(name: 'idx_content_units_entry', columns: {#libraryEntryId})
@TableIndex(name: 'idx_content_units_updates', columns: {#dateUploaded})
@TableIndex(
  name: 'idx_content_units_client_id',
  columns: {#clientId},
  unique: true,
)
@TableIndex(name: 'idx_content_units_updated_at', columns: {#updatedAt})
class ContentUnits extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get clientId =>
      integer().nullable().clientDefault(generateClientId)();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  IntColumn get libraryEntryId =>
      integer().references(LibraryEntries, #id, onDelete: KeyAction.cascade)();

  RealColumn get number => real()();
  TextColumn get displayTitle => text().nullable()();
  TextColumn get url => text()();

  DateTimeColumn get dateUploaded =>
      dateTime().withDefault(currentDateAndTime)();
  BoolColumn get downloaded => boolean().withDefault(const Constant(false))();

  TextColumn get scanlator => text().nullable()();

  BoolColumn get bookmarked => boolean().withDefault(const Constant(false))();

  TextColumn get localPath => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {libraryEntryId, url},
  ];
}
