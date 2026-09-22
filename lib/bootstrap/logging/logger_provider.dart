import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/bootstrap/database/slow_query_interceptor.dart';
import 'package:sumizuri/features/settings/data/log_repository_impl.dart';
import 'package:sumizuri/features/settings/data/log_repository.dart';
import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/bootstrap/database/db_provider.dart';

part 'logger_provider.g.dart';

@Riverpod(keepAlive: true)
LogRepository logRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftLogRepository(db);
}

@Riverpod(keepAlive: true)
AppLogger appLogger(Ref ref) {
  final repository = ref.watch(logRepositoryProvider);
  final logger = AppLogger(repository);

  appDataDirectory()
      .then(
        (dir) =>
            logger.fallbackFile = File(p.join(dir.path, 'fallback_log.txt')),
      )
      .ignore();
  onSlowQuery = (statement, ms) {
    final shown = statement.length > 200
        ? '${statement.substring(0, 200)}…'
        : statement;
    logger.warning('Slow query: ${ms}ms\n  $shown', tag: 'database');
  };
  logger.loadDisabledCategories().ignore();
  return logger;
}
