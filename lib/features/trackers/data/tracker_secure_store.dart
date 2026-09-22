import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TrackerSecureStore {
  TrackerSecureStore(this.trackerName, {FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final String trackerName;
  final FlutterSecureStorage _storage;

  String _key(int profileId, String field) =>
      '${trackerName}_${field}_$profileId';

  Future<String?> read(int profileId, String field) =>
      _storage.read(key: _key(profileId, field));

  Future<void> write(int profileId, String field, String value) =>
      _storage.write(key: _key(profileId, field), value: value);

  Future<void> delete(int profileId, String field) =>
      _storage.delete(key: _key(profileId, field));

  Future<void> clearAll(int profileId, List<String> fields) async {
    for (final field in fields) {
      await delete(profileId, field);
    }
  }
}
