// Drift backed repository for user profiles.
import 'package:drift/drift.dart';

import 'package:sumizuri/bootstrap/database/app_database.dart';
import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/profile/models/profile.dart' as domain;
import 'package:sumizuri/features/profile/data/profile_repository.dart';
import 'package:sumizuri/core/errors/guard_failure.dart';

class DriftProfileRepository implements ProfileRepository {
  DriftProfileRepository(this._db, this._logger);

  final AppDatabase _db;
  final AppLogger _logger;

  static const _tag = 'profile';

  @override
  Stream<List<domain.Profile>> watchAll() {
    return (_db.select(_db.profiles)..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .watch()
        .map((rows) => rows.map(_mapProfile).toList());
  }

  @override
  Stream<domain.Profile?> watchActive() {
    final query = _db.select(_db.activeProfileTable).join([
      innerJoin(
        _db.profiles,
        _db.profiles.id.equalsExp(_db.activeProfileTable.profileId),
      ),
    ]);

    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      return _mapProfile(row.readTable(_db.profiles));
    });
  }

  @override
  Future<Result<domain.Profile, AppFailure>> create({
    required String name,
    String? avatarPath,
  }) => guardFailure(_logger, _tag, () async {
    final id = await _db
        .into(_db.profiles)
        .insert(
          ProfilesCompanion.insert(name: name, avatarPath: Value(avatarPath)),
        );

    final profile = domain.Profile(
      id: id,
      name: name,
      avatarPath: avatarPath,
      createdAt: DateTime.now(),
    );
    _logger.info('Created profile #$id "$name"', tag: _tag);
    return profile;
  });

  @override
  Future<Result<void, AppFailure>> rename({
    required int id,
    required String name,
  }) => guardFailure(_logger, _tag, () async {
    await (_db.update(_db.profiles)..where((t) => t.id.equals(id))).write(
      ProfilesCompanion(name: Value(name)),
    );
    _logger.info('Renamed profile #$id to "$name"', tag: _tag);
  });

  @override
  Future<Result<void, AppFailure>> setAvatar({required int id, String? path}) =>
      guardFailure(_logger, _tag, () async {
        await (_db.update(_db.profiles)..where((t) => t.id.equals(id))).write(
          ProfilesCompanion(avatarPath: Value(path)),
        );
        _logger.info('Updated avatar for profile #$id', tag: _tag);
      });

  @override
  Future<Result<void, AppFailure>> delete(int id) => guardFailure(
    _logger,
    _tag,
    () async {
      final all = await _db.select(_db.profiles).get();
      if (all.length <= 1) {
        throw StateError('Cannot delete the only profile.');
      }

      final active = await _db.select(_db.activeProfileTable).getSingleOrNull();
      if (active?.profileId == id) {
        final nextProfile = all.firstWhere((p) => p.id != id);
        await switchTo(nextProfile.id);
      }

      await (_db.delete(_db.profiles)..where((t) => t.id.equals(id))).go();
      _logger.info('Deleted profile #$id', tag: _tag);
    },
  );

  @override
  Future<Result<void, AppFailure>> switchTo(int id) =>
      guardFailure(_logger, _tag, () async {
        await _db
            .into(_db.activeProfileTable)
            .insertOnConflictUpdate(
              ActiveProfileTableCompanion.insert(
                id: const Value(0),
                profileId: id,
              ),
            );
        _logger.info('Switched active profile to #$id', tag: _tag);
      });

  domain.Profile _mapProfile(Profile row) {
    return domain.Profile(
      id: row.id,
      name: row.name,
      avatarPath: row.avatarPath,
      createdAt: row.createdAt,
    );
  }
}
