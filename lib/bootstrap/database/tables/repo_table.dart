import 'package:drift/drift.dart';

import 'package:sumizuri/bootstrap/startup/client_id.dart';

@TableIndex(name: 'idx_repos_client_id', columns: {#clientId}, unique: true)
@TableIndex(name: 'idx_repos_updated_at', columns: {#updatedAt})
class Repos extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get clientId =>
      integer().nullable().clientDefault(generateClientId)();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  TextColumn get url => text().unique()();
  TextColumn get name => text()();

  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}
