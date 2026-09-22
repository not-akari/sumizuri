import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/bootstrap/startup/app_restart.dart';
import 'package:sumizuri/core/utils/files/folder_picker.dart';
import 'package:sumizuri/core/utils/files/folder_problem_text.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/features/settings/data/data_folder_move.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

void _say(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

Future<bool> changeDataFolder(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;

  final pick = await pickFolder(dialogTitle: l10n.dataLocationDataFolder);
  if (!context.mounted) return false;
  final problem = pick.problem;
  if (problem != null) {
    _say(context, folderProblemText(l10n, problem));
    return false;
  }
  final path = pick.path;
  if (path == null) return false;

  final current = (await appDataDirectory()).path;
  if (!context.mounted) return false;
  if (p.equals(current, path)) {
    _say(context, l10n.dataFolderSame);
    return false;
  }

  final hasData = await folderHasData(path);
  if (!context.mounted) return false;
  final confirmed = await showAppConfirmDialog(
    context: context,
    title: hasData ? l10n.dataFolderUseTitle : l10n.dataFolderMoveTitle,
    message: hasData
        ? l10n.dataFolderUseMessage(path)
        : l10n.dataFolderMoveMessage(path),
    confirmLabel: hasData ? l10n.dataFolderUse : l10n.dataFolderMove,
  );
  if (!confirmed || !context.mounted) return false;

  try {
    if (hasData) {
      await useExistingDataFolder(path);
    } else {
      await _moveWithProgress(context, path);
    }
  } on DataFolderMoveException {
    if (context.mounted) _say(context, l10n.dataFolderNested);
    return false;
  } catch (error) {
    if (context.mounted) _say(context, l10n.dataFolderFailed('$error'));
    return false;
  }
  if (!context.mounted) return true;
  await _askForRestart(context);
  return true;
}

Future<void> _moveWithProgress(BuildContext context, String path) async {
  final l10n = AppLocalizations.of(context)!;
  final progress = ValueNotifier<double?>(null);
  final navigator = Navigator.of(context, rootNavigator: true);
  // Not dismissible: leaving halfway would leave a half-copied folder behind.
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(l10n.dataFolderMoving),
          content: ValueListenableBuilder<double?>(
            valueListenable: progress,
            builder: (_, value, _) => LinearProgressIndicator(value: value),
          ),
        ),
      ),
    ),
  );
  try {
    await moveDataFolder(path, onProgress: (v) => progress.value = v);
  } finally {
    navigator.pop();
  }
}

Future<void> _askForRestart(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n.dataFolderRestartTitle),
        content: Text(l10n.dataFolderRestartMessage),
        actions: [
          FilledButton(
            onPressed: restartApp,
            child: Text(
              canRelaunch ? l10n.dataFolderRestart : l10n.dataFolderClose,
            ),
          ),
        ],
      ),
    ),
  );
}
