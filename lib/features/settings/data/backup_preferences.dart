import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/settings/models/backup_preferences.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

import 'package:sumizuri/bootstrap/storage/app_paths.dart';

export 'package:sumizuri/features/settings/models/backup_preferences.dart';

const backupFileExtension = 'sumizuribackup';

class BackupPreferencesNotifier extends AsyncNotifier<BackupPreferences> {
  @override
  Future<BackupPreferences> build() =>
      ref.watch(settingsRepositoryProvider).backupPreferences();

  Future<void> change(
    BackupPreferences Function(BackupPreferences) edit,
  ) async {
    final next = edit(state.value ?? const BackupPreferences());
    state = AsyncData(next);
    await ref.read(settingsRepositoryProvider).setBackupPreferences(next);
  }
}

final backupPreferencesProvider =
    AsyncNotifierProvider<BackupPreferencesNotifier, BackupPreferences>(
      BackupPreferencesNotifier.new,
    );

class BackupFileInfo {
  const BackupFileInfo(this.file, this.modified, this.bytes);

  final File file;
  final DateTime modified;
  final int bytes;
}

Future<List<BackupFileInfo>> listAutoBackups() async {
  final dir = await autoBackupsDirectory();
  final out = <BackupFileInfo>[];
  await for (final entity in dir.list()) {
    if (entity is File && entity.path.endsWith('.$backupFileExtension')) {
      final stat = await entity.stat();
      out.add(BackupFileInfo(entity, stat.modified, stat.size));
    }
  }
  out.sort((a, b) => b.modified.compareTo(a.modified));
  return out;
}

Future<void> pruneAutoBackups(int keep) async {
  final all = await listAutoBackups();
  for (final old in all.skip(keep)) {
    try {
      await old.file.delete();
    } catch (_) {}
  }
}
