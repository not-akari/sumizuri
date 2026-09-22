// Maps a raw thrown exception to an app level AppFailure.
import 'dart:async';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart' show SqliteException;

import 'package:sumizuri/core/errors/app_failure.dart';

AppFailure mapExceptionToFailure(Object error) {
  if (error is AppFailure) return error;
  if (error is SqliteException) {
    return DatabaseFailure('A database error occurred.', cause: error);
  }
  if (error is SocketException ||
      error is HandshakeException ||
      error is TimeoutException) {
    return NetworkFailure(
      'Could not reach the server. Check your connection.',
      cause: error,
    );
  }
  return UnknownFailure('Something went wrong.', cause: error);
}
