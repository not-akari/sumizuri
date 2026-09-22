import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/settings/flows/mangayomi_import_flow.dart';
import 'package:sumizuri/features/settings/data/mangayomi_import_codec.dart';
import 'package:sumizuri/features/settings/flows/mihon_import_flow.dart';
import 'package:sumizuri/features/settings/data/mihon_import_codec.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/library/migration/auto_source_match.dart';
import 'package:sumizuri/features/library/migration/migration_controller.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/core/utils/files/file_export_helper.dart';
import 'package:sumizuri/core/utils/formatting/timestamps.dart';
import 'package:sumizuri/features/settings/data/backup_codec.dart';
import 'package:sumizuri/features/settings/data/backup_encryption.dart';
import 'package:sumizuri/features/settings/flows/backup_service.dart';
import 'package:sumizuri/features/settings/models/backup_data.dart';
import 'package:sumizuri/features/settings/widgets/backup_password_dialog.dart';
import 'package:sumizuri/features/settings/widgets/restore_preview_dialog.dart';
import 'package:sumizuri/features/sync/providers/sync_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

const _backupTypeGroup = XTypeGroup(
  label: 'Sumizuri backup',
  extensions: ['sumizuribackup', 'json'],
  mimeTypes: ['*/*'],
);

Future<String?> createBackup(BuildContext context, WidgetRef ref) async {
  final password = await askNewBackupPassword(context);
  if (password == null || !context.mounted) return null;
  final data = await ref.read(backupServiceProvider).build();
  final plain = encodeBackup(data);
  return saveExportedText(
    suggestedName: 'sumizuri_backup_${fileStamp()}.sumizuribackup',
    content: password.isEmpty ? plain : encryptBackup(plain, password),
    acceptedTypeGroups: const [_backupTypeGroup],
  );
}

Future<T> _withProgress<T>(
  BuildContext context,
  Future<T> Function() work,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
  try {
    return await work();
  } finally {
    navigator.pop();
  }
}

Future<(int, int)?> previewAndRestore(
  BuildContext context,
  WidgetRef ref,
  BackupData data,
) async {
  if (!await confirmRestorePreview(context, data)) return null;
  if (!context.mounted) return null;
  // Held so an automatic sync never runs against a half-restored library.
  final guard = ref.read(syncGuardProvider.notifier)..hold();
  final runner = ref.read(syncRunnerProvider.notifier);
  try {
    final result = await _withProgress(
      context,
      () => ref.read(backupServiceProvider).restore(data),
    );
    guard.release();
    unawaited(runner.runAfterRestore());
    return result;
  } catch (_) {
    guard.release();
    rethrow;
  }
}

Future<(int, int)?> restoreFromBackupFile(
  BuildContext context,
  WidgetRef ref,
  File file,
) async {
  final messenger = ScaffoldMessenger.of(context);
  var text = await file.readAsString();

  if (looksEncrypted(text)) {
    String? error;
    while (true) {
      if (!context.mounted) return null;
      final password = await askExistingBackupPassword(context, error: error);
      if (password == null) return null;
      final decrypted = decryptBackup(text, password);
      final plain = decrypted.valueOrNull;
      if (plain != null) {
        text = plain;
        break;
      }
      error = decrypted.errorOrNull!.displayMessage;
    }
  }

  final result = decodeBackup(text);
  final data = result.valueOrNull;
  if (data == null) {
    messenger.showSnackBar(
      SnackBar(content: Text(result.errorOrNull!.displayMessage)),
    );
    return null;
  }
  if (!context.mounted) return null;
  return previewAndRestore(context, ref, data);
}

/// Asynchronously attempts to match newly imported candidates against installed sources.
void _runAutoMatchInBackground(
  BuildContext context,
  WidgetRef ref,
  List<AutoMatchCandidate> candidates,
) {
  if (candidates.isEmpty) return;
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    SnackBar(
      content: Text(l10n.autoSourceMatchRunning(candidates.length)),
      duration: const Duration(seconds: 4),
    ),
  );
  unawaited(
    autoMatchInstalledSources(
      library: ref.read(libraryRepositoryProvider),
      loadSource: ref.read(migrationSourceLoaderProvider),
      installedSources: ref.read(installedSourcesProvider).value ?? const [],
      candidates: candidates,
    ).then((result) {
      if (result.matched == 0 || !context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.autoSourceMatchDone(result.matched))),
      );
    }),
  );
}

const _mangayomiTypeGroup = XTypeGroup(
  label: 'Mangayomi backup',
  extensions: ['backup'],
);

/// Picks a Mangayomi ".backup" file and adds what it holds to the library.
Future<MangayomiImportResult?> pickAndImportMangayomiBackup(
  BuildContext context,
  WidgetRef ref,
) async {
  final file = await openFile(acceptedTypeGroups: const [_mangayomiTypeGroup]);
  if (file == null) return null;
  final MangayomiBackup backup;
  try {
    backup = readMangayomiBackup(File(file.path));
  } on MangayomiBackupUnreadable catch (error) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.message)));
    return null;
  }
  final result = await importMangayomiBackup(
    library: ref.read(libraryRepositoryProvider),
    backup: backup,
  );
  if (context.mounted) {
    _runAutoMatchInBackground(context, ref, result.candidates);
  }
  return result;
}

const _mihonTypeGroup = XTypeGroup(
  label: 'Mihon backup',
  extensions: ['tachibk'],
);

/// Picks a Mihon ".tachibk" file and adds what it holds to the library.
Future<MihonImportResult?> pickAndImportMihonBackup(
  BuildContext context,
  WidgetRef ref,
) async {
  final file = await openFile(acceptedTypeGroups: const [_mihonTypeGroup]);
  if (file == null) return null;
  final MihonBackup backup;
  try {
    backup = readMihonBackup(File(file.path));
  } on MihonBackupUnreadable catch (error) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.message)));
    return null;
  }
  final result = await importMihonBackup(
    library: ref.read(libraryRepositoryProvider),
    backup: backup,
  );
  if (context.mounted) {
    _runAutoMatchInBackground(context, ref, result.candidates);
  }
  return result;
}

Future<(int, int)?> pickAndRestoreBackup(
  BuildContext context,
  WidgetRef ref,
) async {
  final file = await openFile(acceptedTypeGroups: const [_backupTypeGroup]);
  if (file == null) return null;
  final path = file.path;
  if (!context.mounted) return null;
  return restoreFromBackupFile(context, ref, File(path));
}
