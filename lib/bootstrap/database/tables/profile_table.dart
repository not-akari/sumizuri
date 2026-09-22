import 'package:drift/drift.dart';

class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  TextColumn get avatarPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ActiveProfileTable extends Table {
  @override
  String get tableName => 'active_profile';

  IntColumn get id => integer().withDefault(const Constant(0))();
  IntColumn get profileId =>
      integer().references(Profiles, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {id};
}
