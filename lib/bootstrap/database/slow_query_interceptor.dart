import 'dart:async';

import 'package:drift/drift.dart';

void Function(String statement, int milliseconds)? onSlowQuery;

const _slowQueryMs = 200;

class SlowQueryInterceptor extends QueryInterceptor {
  Future<T> _time<T>(String statement, Future<T> Function() run) async {
    final watch = Stopwatch()..start();
    try {
      return await run();
    } finally {
      final ms = watch.elapsedMilliseconds;
      // Writing the report itself hits log_entries, so skip it to avoid a feedback loop.
      if (ms >= _slowQueryMs && !statement.contains('log_entries')) {
        onSlowQuery?.call(statement, ms);
      }
    }
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _time(statement, () => super.runSelect(executor, statement, args));

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _time(statement, () => super.runInsert(executor, statement, args));

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _time(statement, () => super.runUpdate(executor, statement, args));

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _time(statement, () => super.runDelete(executor, statement, args));

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _time(statement, () => super.runCustom(executor, statement, args));
}
