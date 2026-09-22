import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/bootstrap/database/db_provider.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/features/repos/data/repo_repository_impl.dart';
import 'package:sumizuri/features/repos/models/repo.dart';
import 'package:sumizuri/features/repos/data/repo_repository.dart';

part 'repo_providers.g.dart';

@Riverpod(keepAlive: true)
RepoRepository repoRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final logger = ref.watch(appLoggerProvider);
  return DriftRepoRepository(db, logger);
}

@riverpod
Stream<List<Repo>> repos(Ref ref) {
  final repository = ref.watch(repoRepositoryProvider);
  return repository.watchAll();
}
