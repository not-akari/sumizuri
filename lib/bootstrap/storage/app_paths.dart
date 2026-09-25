import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:sumizuri/core/utils/files/delete_if_exists.dart';

String get dataFolderName => kDebugMode ? 'Sumizuri Debug' : 'Sumizuri';

Future<Directory> defaultDataDirectory() async {
  final documentsDir = await getApplicationDocumentsDirectory();
  final appDir = Directory(p.join(documentsDir.path, dataFolderName));
  if (!await appDir.exists()) {
    await appDir.create(recursive: true);
  }
  return appDir;
}

// The folder the user chose for the data, read once per isolate.
String? _customDataPath;
bool _customDataPathLoaded = false;

Future<File> _dataLocationFile() async =>
    File(p.join((await defaultDataDirectory()).path, 'data_location.txt'));

Future<String?> customDataPath() async {
  if (!_customDataPathLoaded) {
    final file = await _dataLocationFile();
    final text = await file.exists() ? (await file.readAsString()).trim() : '';
    _customDataPath = text.isEmpty ? null : text;
    _customDataPathLoaded = true;
  }
  return _customDataPath;
}

Future<void> setCustomDataPath(String? path) async {
  final file = await _dataLocationFile();
  if (path == null) {
    await deleteIfExists(file);
  } else {
    await file.writeAsString(path);
  }
  _customDataPath = path;
  _customDataPathLoaded = true;
}

Future<bool> isFirstRun() async {
  if (await customDataPath() != null) return false;
  final dir = await defaultDataDirectory();
  return !await File(p.join(dir.path, 'sumizuri.sqlite')).exists();
}

Future<Directory> appDataDirectory() async {
  final custom = await customDataPath();
  if (custom == null) return defaultDataDirectory();
  final dir = Directory(custom);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

Future<File> databaseFile() async {
  final appDir = await appDataDirectory();
  return File(p.join(appDir.path, 'sumizuri.sqlite'));
}

Future<Directory> dbBackupsDirectory() async {
  final appDir = await appDataDirectory();
  final dir = Directory(p.join(appDir.path, 'db_backups'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

Future<Directory> customCoversDirectory() async {
  final appDir = await appDataDirectory();
  final coversDir = Directory(p.join(appDir.path, 'custom_covers'));
  if (!await coversDir.exists()) {
    await coversDir.create(recursive: true);
  }
  return coversDir;
}

Future<Directory> profileAvatarsDirectory() async {
  final appDir = await appDataDirectory();
  final avatarsDir = Directory(p.join(appDir.path, 'profile_avatars'));
  if (!await avatarsDir.exists()) {
    await avatarsDir.create(recursive: true);
  }
  return avatarsDir;
}

Future<Directory> translationDraftsDirectory() async {
  final appDir = await appDataDirectory();
  final dir = Directory(p.join(appDir.path, 'translation_drafts'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

Future<Directory> downloadsDirectory({String? overridePath}) async {
  final dir = overridePath != null
      ? Directory(overridePath)
      : Directory(p.join((await appDataDirectory()).path, 'downloads'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

Future<File> appLocaleFile() async {
  final appDir = await appDataDirectory();
  return File(p.join(appDir.path, 'app_locale.txt'));
}

Future<Directory> exportsDirectory() async {
  if (Platform.isAndroid) {
    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        final probe = File(
          p.join(
            downloadDir.path,
            '.sumizuri_probe_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
        await probe.writeAsString('');
        await probe.delete();
        return downloadDir;
      }
    } catch (_) {}

    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final dir = Directory(p.join(extDir.path, 'exports'));
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return dir;
      }
    } catch (_) {}
  }

  final appDir = await appDataDirectory();
  final dir = Directory(p.join(appDir.path, 'exports'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

Future<Directory> themesDirectory() async {
  final appDir = await appDataDirectory();
  final dir = Directory(p.join(appDir.path, 'themes'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

Future<Directory> fontsDirectory() async {
  final appDir = await appDataDirectory();
  final dir = Directory(p.join(appDir.path, 'fonts'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// Where the fonts fetched from Google Fonts are kept, apart from the ones
/// the person imported.
Future<Directory> googleFontsDirectory() async {
  final appDir = await appDataDirectory();
  final dir = Directory(p.join(appDir.path, 'google_fonts'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

Future<File> runStateFile() async {
  final appDir = await appDataDirectory();
  return File(p.join(appDir.path, 'run_state.json'));
}

Future<Directory> cookiesRootDirectory() async {
  final appDir = await appDataDirectory();
  return Directory(p.join(appDir.path, 'cookies'));
}

Future<Directory> autoBackupsDirectory() async {
  final appDir = await appDataDirectory();
  final dir = Directory(p.join(appDir.path, 'backups'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}
