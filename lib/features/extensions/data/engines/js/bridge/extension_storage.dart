import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart' as p;

class ExtensionStorage {
  ExtensionStorage(this.storageDirPath) {
    _init();
  }

  final String storageDirPath;

  late final File _storageFile;
  late final File _preferencesFile;

  final Map<String, dynamic> _storageData = {};
  final Map<String, dynamic> _preferencesData = {};

  void _init() {
    final dir = Directory(storageDirPath);
    if (!dir.existsSync()) {
      try {
        dir.createSync(recursive: true);
      } catch (_) {}
    }

    _storageFile = File(p.join(storageDirPath, 'storage.json'));
    _preferencesFile = File(p.join(storageDirPath, 'preferences.json'));

    _storageData.addAll(_readFileMap(_storageFile));
    _preferencesData.addAll(_readFileMap(_preferencesFile));
  }

  static Map<String, dynamic> _readFileMap(File file) {
    if (!file.existsSync()) return {};
    try {
      final text = file.readAsStringSync();
      if (text.trim().isEmpty) return {};
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        return decoded.cast<String, dynamic>();
      }
    } catch (_) {}
    return {};
  }

  void _writeFileMap(File file, Map<String, dynamic> data) {
    try {
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      file.writeAsStringSync(jsonEncode(data), flush: true);
    } catch (error) {
      // Nowhere to report this from here, but a lost write should not be silent in development.
      debugPrint('Extension storage could not write ${file.path}: $error');
    }
  }

  dynamic get(String key) => _storageData[key];

  void set(String key, dynamic value) {
    _storageData[key] = value;
    _writeFileMap(_storageFile, _storageData);
  }

  void delete(String key) {
    if (_storageData.remove(key) != null) {
      _writeFileMap(_storageFile, _storageData);
    }
  }

  void clear() {
    _storageData.clear();
    _writeFileMap(_storageFile, _storageData);
  }

  Map<String, dynamic> all() => Map.unmodifiable(_storageData);

  dynamic getPreference(String key) => _preferencesData[key];

  void setPreference(String key, dynamic value) {
    _preferencesData[key] = value;
    _writeFileMap(_preferencesFile, _preferencesData);
  }

  void setPreferences(Map<String, dynamic> values) {
    _preferencesData.addAll(values);
    _writeFileMap(_preferencesFile, _preferencesData);
  }

  Map<String, dynamic> allPreferences() => Map.unmodifiable(_preferencesData);
}
