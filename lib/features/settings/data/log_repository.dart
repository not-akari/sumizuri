import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/settings/models/log_entry.dart';

abstract interface class LogRepository {
  Future<Result<void, AppFailure>> add(AppLogEntry entry);

  Stream<List<AppLogEntry>> watchRecent({int limit});

  Future<Result<void, AppFailure>> clear();

  Future<Set<String>> disabledCategories();

  Future<void> setDisabledCategories(Set<String> categories);

  Future<Result<String, AppFailure>> exportAsText();
}
