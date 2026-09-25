// Drift tables for tracker (AniList) links and the outbox of changes waiting to be sent.
import 'package:drift/drift.dart';

import 'package:sumizuri/bootstrap/database/tables/library_entry_table.dart';

@DataClassName('TrackerLinkRow')
class TrackerLinks extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get libraryEntryId =>
      integer().references(LibraryEntries, #id, onDelete: KeyAction.cascade)();

  // 'anilist' or 'mal'. A column so another tracker needs no new table.
  TextColumn get tracker => text().withDefault(const Constant('anilist'))();

  IntColumn get remoteMediaId => integer()();
  TextColumn get remoteTitle => text()();

  IntColumn get remoteChapters => integer().nullable()();

  DateTimeColumn get linkedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {libraryEntryId, tracker},
  ];
}

@DataClassName('TrackerOutboxRow')
class TrackerOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get linkId =>
      integer().references(TrackerLinks, #id, onDelete: KeyAction.cascade)();

  IntColumn get firstQueuedAt => integer()();

  // Bumped by every change, so a send can tell if something changed while it was in flight.
  IntColumn get version => integer().withDefault(const Constant(1))();

  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  IntColumn get nextTryAt => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {linkId},
  ];
}
