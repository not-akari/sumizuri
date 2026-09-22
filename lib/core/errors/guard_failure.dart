// Runs an action and converts any thrown exception into a Result with a mapped failure.
import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/core/errors/failure_mapper.dart';

Future<Result<T, AppFailure>> guardFailure<T>(
  AppLogger logger,
  String tag,
  Future<T> Function() action,
) async {
  try {
    return Ok(await action());
  } catch (error, stackTrace) {
    final failure = mapExceptionToFailure(error);
    logger.error(
      failure.message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
    return Err(failure);
  }
}
