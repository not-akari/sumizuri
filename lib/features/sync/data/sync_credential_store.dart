import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:sumizuri/features/sync/models/sync_models.dart';

abstract interface class SecretStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class PlatformSecretStore implements SecretStore {
  PlatformSecretStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class SyncCredentialStore {
  SyncCredentialStore({SecretStore? store})
    : _store = store ?? PlatformSecretStore();

  final SecretStore _store;

  static const _serverKey = 'sync_server';
  static const _usernameKey = 'sync_username';
  static const _tokenKey = 'sync_token';
  static const _installKey = 'sync_install';

  Future<SyncAccount?> readAccount() async {
    final server = await _store.read(_serverKey);
    final username = await _store.read(_usernameKey);
    if (server == null || username == null) return null;
    return SyncAccount(server: server, username: username);
  }

  Future<String?> readToken() => _store.read(_tokenKey);

  Future<String?> readInstallId() => _store.read(_installKey);

  Future<void> save(
    SyncAccount account,
    String token, {
    required String installId,
  }) async {
    await _store.write(_installKey, installId);
    await _store.write(_serverKey, account.server);
    await _store.write(_usernameKey, account.username);
    await _store.write(_tokenKey, token);
  }

  Future<void> clear() async {
    await _store.delete(_serverKey);
    await _store.delete(_usernameKey);
    await _store.delete(_tokenKey);
    await _store.delete(_installKey);
  }
}
