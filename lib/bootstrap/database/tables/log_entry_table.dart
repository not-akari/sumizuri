import 'package:drift/drift.dart';

import 'package:sumizuri/features/settings/models/log_entry.dart';

@TableIndex(name: 'idx_log_entries_time', columns: {#timestamp})
class LogEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  IntColumn get level => intEnum<LogLevel>()();
  TextColumn get tag => text()();
  TextColumn get message => text()();
  TextColumn get stackTrace => text().nullable()();
}
