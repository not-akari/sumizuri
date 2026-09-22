import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';

abstract interface class SecureStorageService {
  Future<bool> hasPin();

  Future<Result<void, AppFailure>> setPin(String pin);

  Future<bool> verifyPin(String pin);

  Future<Result<void, AppFailure>> clearPin();
}
