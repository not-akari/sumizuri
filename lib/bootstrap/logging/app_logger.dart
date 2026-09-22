import 'dart:async';
import 'dart:io';

import 'package:sumizuri/bootstrap/logging/log_preferences.dart';

import 'package:flutter/foundation.dart';

import 'package:sumizuri/features/settings/models/log_entry.dart';
import 'package:sumizuri/features/settings/data/log_repository.dart';

class AppLogger {
  AppLogger(this._repository);

  final LogRepository _repository;

  File? fallbackFile;

  Set<String> disabledCategories = {};

  Future<void> loadDisabledCategories() async {
    disabledCategories = await _repository.disabledCategories();
  }

  Future<void> setDisabledCategories(Set<String> categories) async {
    disabledCategories = categories;
    await _repository.setDisabledCategories(categories);
  }

  void debug(String message, {String tag = 'app'}) =>
      _log(LogLevel.debug, tag, message);

  void info(String message, {String tag = 'app'}) =>
      _log(LogLevel.info, tag, message);

  void warning(
    String message, {
    String tag = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) => _log(
    LogLevel.warning,
    tag,
    message,
    error: error,
    stackTrace: stackTrace,
  );

  void error(
    String message, {
    String tag = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);

  void _log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final fullMessage = error == null ? message : '$message: $error';
    if (kDebugMode) {
      debugPrint('[${level.name}] $tag: $fullMessage');
    }
    if (level == LogLevel.debug || level == LogLevel.info) return;
    final performance = performanceLogTags.contains(tag);
    if (disabledCategories.contains(tag) ||
        (!performance && disabledCategories.contains(level.name))) {
      return;
    }

    final entry = AppLogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: fullMessage,
      stackTrace: stackTrace?.toString(),
    );

    unawaited(
      _repository.add(entry).then((result) {
        if (result.isErr) _writeFallback(entry);
      }),
    );
  }

  Future<void> _writeFallback(AppLogEntry entry) async {
    final file = fallbackFile;
    if (file == null) return;
    final line = StringBuffer()
      ..write(entry.timestamp.toIso8601String())
      ..write(' [')
      ..write(entry.level.name)
      ..write('] ')
      ..write(entry.tag)
      ..write(': ')
      ..writeln(entry.message);
    if (entry.stackTrace != null) line.writeln(entry.stackTrace);
    try {
      await file.writeAsString(
        line.toString(),
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {}
  }
}
