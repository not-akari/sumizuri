// Drift backed repository for added source repositories.
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import 'package:sumizuri/bootstrap/database/app_database.dart' hide Repo;
import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/repos/models/repo.dart';
import 'package:sumizuri/features/repos/data/repo_repository.dart';
import 'package:sumizuri/features/repos/models/repo_source.dart';
import 'package:sumizuri/core/errors/guard_failure.dart';
import 'package:sumizuri/features/repos/data/repo_codec.dart';

class DriftRepoRepository implements RepoRepository {
  DriftRepoRepository(this._db, this._logger);

  final AppDatabase _db;
  final AppLogger _logger;

  static const _tag = 'repo';

  @override
  Stream<List<Repo>> watchAll() {
    final query = _db.select(_db.repos)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (r) => Repo(id: r.id, url: r.url, name: r.name, addedAt: r.addedAt),
          )
          .toList(),
    );
  }

  @override
  Future<Result<RepoIndex, AppFailure>> fetchIndex(String url) {
    return guardFailure(_logger, _tag, () async {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode} fetching repo index');
      }
      final result = decodeRepoIndex(response.body);
      return result.when(ok: (index) => index, err: (failure) => throw failure);
    });
  }

  @override
  Future<Result<String, AppFailure>> fetchSourceFile(String fileUrl) {
    return guardFailure(_logger, _tag, () async {
      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode} fetching source file');
      }
      return response.body;
    });
  }

  @override
  Future<Result<Repo, AppFailure>> addRepo(String url) {
    return guardFailure(_logger, _tag, () async {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode} fetching repo index');
      }
      final indexResult = decodeRepoIndex(response.body);
      final index = indexResult.when(
        ok: (v) => v,
        err: (failure) => throw failure,
      );

      final id = await _db
          .into(_db.repos)
          .insert(ReposCompanion.insert(url: url, name: index.name));
      return Repo(id: id, url: url, name: index.name, addedAt: DateTime.now());
    });
  }

  @override
  Future<Result<void, AppFailure>> removeRepo(int id) {
    return guardFailure(_logger, _tag, () async {
      await (_db.delete(_db.repos)..where((t) => t.id.equals(id))).go();
    });
  }
}
