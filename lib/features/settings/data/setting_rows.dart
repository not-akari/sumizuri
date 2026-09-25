import 'dart:async';

import 'package:drift/drift.dart';

import 'package:sumizuri/bootstrap/database/app_database.dart';
import 'package:sumizuri/core/utils/async/shared_stream_replay.dart';
import 'package:sumizuri/features/settings/registry/setting_def.dart';

/// Which profile a setting's row belongs to: 0 for the whole app, otherwise profileId.
int settingScopeId(SettingDef<Object?> def, int profileId) =>
    def.scope == SettingScope.app ? 0 : profileId;

// Shared settings watch per profile replaces dozens of queries with one.
final _sharedSettingsWatches =
    Expando<Map<int, SharedStreamReplay<Map<String, String?>>>>(
      'sharedSettingsWatches',
    );

extension SettingRows on AppDatabase {
  Stream<Map<String, String?>> _watchAllSettingRows(int profileId) {
    final byProfile = _sharedSettingsWatches[this] ??= {};
    final shared = byProfile.putIfAbsent(profileId, () {
      final query = select(settingValues)
        ..where((t) => t.profileId.isIn({0, profileId}));
      return SharedStreamReplay(
        query.watch().map(
          (rows) => {
            for (final row in rows)
              '${row.profileId}:${row.settingId}': row.value,
          },
        ),
      );
    });
    return shared.watch();
  }

  Stream<T> watchSettingRow<T>(SettingDef<T> def, {int profileId = 1}) {
    final key = '${settingScopeId(def, profileId)}:${def.id}';
    return _watchAllSettingRows(profileId)
        .map((all) => def.decode(all[key]))
        .distinct();
  }

  Future<T> readSettingRow<T>(SettingDef<T> def, {int profileId = 1}) =>
      watchSettingRow(def, profileId: profileId).first;

  Future<void> writeSettingRow<T>(
    SettingDef<T> def,
    T value, {
    int profileId = 1,
  }) async {
    final row = SettingValuesCompanion(
      profileId: Value(settingScopeId(def, profileId)),
      settingId: Value(def.id),
      value: Value(def.encode(value)),
      synced: Value(def.sync),
    );
    await into(settingValues).insert(
      row,
      onConflict: DoUpdate(
        (old) => row,
        target: [settingValues.profileId, settingValues.settingId],
      ),
    );
  }
}
