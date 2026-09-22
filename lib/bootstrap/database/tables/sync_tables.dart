import 'package:drift/drift.dart';

import 'package:sumizuri/bootstrap/database/tables/profile_table.dart';

class SyncDeletions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get profileId => integer()();

  TextColumn get entity => text()();
  IntColumn get clientId => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {profileId, entity, clientId},
  ];
}

class SyncState extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();

  IntColumn get applying => integer().withDefault(const Constant(0))();

  TextColumn get installId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncProfileState extends Table {
  IntColumn get profileId =>
      integer().references(Profiles, #id, onDelete: KeyAction.cascade)();

  IntColumn get serverProfileId => integer().nullable()();
  TextColumn get serverProfileName => text().nullable()();

  // Server clock time of the last finished sync. 0 means never.
  IntColumn get since => integer().withDefault(const Constant(0))();

  IntColumn get localSince => integer().withDefault(const Constant(0))();

  // Device-clock time the last sync finished at. 0 is never.
  IntColumn get lastSyncAt => integer().withDefault(const Constant(0))();

  IntColumn get autoSyncIntervalMinutes =>
      integer().withDefault(const Constant(0))();
  BoolColumn get syncOnLaunch => boolean().withDefault(const Constant(true))();

  // Opt in to also sync on the same schedule while the app is closed, on Android and iOS.
  BoolColumn get backgroundSync =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {profileId};
}

class SyncFiles extends Table {
  IntColumn get profileId => integer()();

  TextColumn get kind => text()();
  TextColumn get name => text()();

  TextColumn get sha256 => text()();
  IntColumn get sizeBytes => integer()();

  IntColumn get modifiedAt => integer()();

  @override
  Set<Column> get primaryKey => {profileId, kind, name};
}
