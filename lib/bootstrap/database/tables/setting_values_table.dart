import 'package:drift/drift.dart';

@TableIndex(name: 'idx_setting_values_setting', columns: {#settingId})
class SettingValues extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 0 for a setting of the whole app, otherwise the profile it belongs to.
  IntColumn get profileId => integer().withDefault(const Constant(0))();

  TextColumn get settingId => text()();

  TextColumn get value => text()();

  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  BoolColumn get synced => boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {profileId, settingId},
  ];
}
