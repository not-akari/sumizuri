import 'package:drift/drift.dart';

import 'package:sumizuri/bootstrap/startup/client_id.dart';

import 'package:sumizuri/features/library/models/library_types.dart';

@TableIndex(
  name: 'idx_installed_sources_client_id',
  columns: {#clientId},
  unique: true,
)
@TableIndex(name: 'idx_installed_sources_updated_at', columns: {#updatedAt})
class InstalledSources extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get clientId =>
      integer().nullable().clientDefault(generateClientId)();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  TextColumn get name => text()();
  TextColumn get lang => text().withDefault(const Constant('en'))();
  IntColumn get mediaType => intEnum<MediaType>()();
  TextColumn get jsSource => text()();
  TextColumn get iconUrl => text().withDefault(const Constant(''))();
  TextColumn get baseUrl => text().withDefault(const Constant(''))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  TextColumn get engineKind => text().withDefault(const Constant('js'))();

  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  TextColumn get repoUrl => text().nullable()();
  TextColumn get repoSourceId => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get nsfw => boolean().withDefault(const Constant(false))();
}
