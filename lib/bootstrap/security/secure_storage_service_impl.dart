import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/bootstrap/security/secure_storage_service.dart';
import 'package:sumizuri/core/errors/guard_failure.dart';

const _pinSaltKey = 'app_lock_pin_salt';
const _pinHashKey = 'app_lock_pin_hash';
const _tag = 'secure_storage';

class SecureStorageServiceImpl implements SecureStorageService {
  SecureStorageServiceImpl(this._logger, {FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final AppLogger _logger;

  String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  @override
  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null;
  }

  @override
  Future<Result<void, AppFailure>> setPin(String pin) {
    return guardFailure(_logger, _tag, () async {
      final saltBytes = List<int>.generate(
        16,
        (_) => Random.secure().nextInt(256),
      );
      final salt = base64UrlEncode(saltBytes);
      await _storage.write(key: _pinSaltKey, value: salt);
      await _storage.write(key: _pinHashKey, value: _hash(pin, salt));
    });
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _pinSaltKey);
    final storedHash = await _storage.read(key: _pinHashKey);
    if (salt == null || storedHash == null) return false;
    return _hash(pin, salt) == storedHash;
  }

  @override
  Future<Result<void, AppFailure>> clearPin() {
    return guardFailure(_logger, _tag, () async {
      await _storage.delete(key: _pinSaltKey);
      await _storage.delete(key: _pinHashKey);
    });
  }
}
