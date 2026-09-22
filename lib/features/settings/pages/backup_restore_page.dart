import 'dart:io';

import 'package:sumizuri/features/library/migration/migration_prompt.dart';
import 'package:sumizuri/features/settings/flows/mangayomi_import_flow.dart';
import 'package:sumizuri/features/settings/flows/mihon_import_flow.dart';
import 'package:sumizuri/features/settings/pages/storage_page.dart';
import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/bootstrap/startup/app_restart.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/settings/data/backup_preferences.dart';
import 'package:sumizuri/features/settings/flows/backup_flow.dart';
import 'package:sumizuri/features/settings/data/db_file_backup.dart'
    as db_file_backup;
import 'package:sumizuri/features/settings/flows/backup_service.dart';
import 'package:sumizuri/features/settings/widgets/storage_widgets.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class BackupRestorePage extends ConsumerStatefulWidget {
  const BackupRestorePage({super.key});

  @override
  ConsumerState<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends ConsumerState<BackupRestorePage> {
  late Future<List<BackupFileInfo>> _autoBackups = listAutoBackups();
  late Future<List<File>> _safetyCopies = db_file_backup.listBackups();
  bool _backingUp = false;

  void _refresh() => setState(() {
    _autoBackups = listAutoBackups();
    _safetyCopies = db_file_backup.listBackups();
  });

  String _when(DateTime t) => DateFormat.yMMMd().add_jm().format(t.toLocal());

  void _reportMangayomi(MangayomiImportResult? result) {
    if (result == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showMigratePrompt(
      context,
      l10n.settingsMangayomiImportDone(result.added, result.skipped),
      result.addedIds,
    );
  }

  void _reportMihon(MihonImportResult? result) {
    if (result == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showMigratePrompt(
      context,
      l10n.settingsMihonImportDone(result.added, result.skipped),
      result.addedIds,
    );
  }

  void _report((int, int)? outcome) {
    if (outcome == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final (restored, skipped) = outcome;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settingsRestoreBackupDone(restored, skipped)),
      ),
    );
  }

  Future<void> _createBackup() async {
    final l10n = AppLocalizations.of(context)!;
    final path = await createBackup(context, ref);
    if (path != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsBackupSaved(path))));
    }
  }

  Future<void> _backUpNow() async {
    final prefs =
        ref.read(backupPreferencesProvider).value ?? const BackupPreferences();
    setState(() => _backingUp = true);
    try {
      await ref.read(backupServiceProvider).writeAuto(keep: prefs.keep);
      await ref
          .read(backupPreferencesProvider.notifier)
          .change((p) => p.copyWith(lastAt: DateTime.now()));
    } finally {
      if (mounted) setState(() => _backingUp = false);
      _refresh();
    }
  }

  Future<void> _restoreSafetyCopy(File backup) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.settingsRestoreLastBackupConfirmTitle,
      message: l10n.settingsRestoreLastBackupConfirmMessage,
      confirmLabel: l10n.settingsRestoreLastBackupConfirmConfirm,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    await ref.read(backupServiceProvider).restoreDatabaseFile(backup);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsRestoreLastBackupDone),
        actions: [
          FilledButton(
            onPressed: exitCleanly,
            child: Text(l10n.settingsRestoreLastBackupRestartNow),
          ),
        ],
      ),
    );
  }

  Widget _autoBackupSection(AppLocalizations l10n, BackupPreferences prefs) {
    final notifier = ref.read(backupPreferencesProvider.notifier);
    final last = prefs.lastAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSwitchRow(
          icon: Icons.schedule_send_outlined,
          title: l10n.autoBackupTitle,
          subtitle: last == null
              ? l10n.autoBackupHint
              : l10n.autoBackupLast(_when(last)),
          value: prefs.enabled,
          onChanged: (on) => notifier.change((p) => p.copyWith(enabled: on)),
        ),
        if (prefs.enabled) ...[
          AppChoice<int>.of(
            title: l10n.autoBackupEvery,
            padded: true,
            style: AppChoiceStyle.pills,
            values: const [1, 3, 7],
            label: l10n.autoBackupDays,
            icon: (_) => Icons.event_repeat_outlined,
            value: prefs.intervalDays,
            onChanged: (days) =>
                notifier.change((p) => p.copyWith(intervalDays: days)),
          ),
          AppChoice<int>.of(
            title: l10n.autoBackupKeep,
            padded: true,
            style: AppChoiceStyle.pills,
            values: const [3, 5, 10],
            label: l10n.autoBackupCopies,
            icon: (_) => Icons.inventory_2_outlined,
            value: prefs.keep,
            onChanged: (n) => notifier.change((p) => p.copyWith(keep: n)),
          ),
        ],
        AppListRow(
          icon: Icons.backup_outlined,
          title: l10n.autoBackupNow,
          trailing: _backingUp
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: _backingUp ? null : _backUpNow,
        ),
      ],
    );
  }

  Widget _restorePoints(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<List<BackupFileInfo>>(
      future: _autoBackups,
      builder: (context, snapshot) {
        final files = snapshot.data ?? const [];
        if (files.isEmpty) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              4,
              context.layout.gutter,
              8,
            ),
            child: Text(
              l10n.restorePointsEmpty,
              style: TextStyle(fontSize: 12, color: cs.outline),
            ),
          );
        }
        return Column(
          children: [
            for (final info in files)
              AppListRow(
                icon: Icons.restore_outlined,
                title: _when(info.modified),
                subtitle: formatStorageBytes(info.bytes),
                onTap: () async {
                  _report(await restoreFromBackupFile(context, ref, info.file));
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: l10n.categoryDelete,
                  onPressed: () async {
                    await info.file.delete();
                    _refresh();
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _safetyCopiesSection(AppLocalizations l10n) {
    return FutureBuilder<List<File>>(
      future: _safetyCopies,
      builder: (context, snapshot) {
        final files = snapshot.data ?? const [];
        if (files.isEmpty) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              4,
              context.layout.gutter,
              8,
            ),
            child: Text(
              l10n.settingsRestoreLastBackupNone,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final file in files)
              AppListRow(
                icon: Icons.history_outlined,
                title: _when(file.statSync().modified),
                subtitle: formatStorageBytes(file.statSync().size),
                onTap: () => _restoreSafetyCopy(file),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs =
        ref.watch(backupPreferencesProvider).value ?? const BackupPreferences();

    return AmbientScaffold(
      maxContentWidth: 720,
      title: Text(l10n.settingsSectionBackup),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
        children: [
          AppSectionLabel(label: l10n.storageBackupSectionTitle),
          AppListRow(
            icon: Icons.save_alt_outlined,
            title: l10n.settingsCreateBackupTile,
            subtitle: l10n.settingsCreateBackupSubtitle,
            onTap: _createBackup,
          ),
          AppListRow(
            icon: Icons.settings_backup_restore_outlined,
            title: l10n.settingsRestoreBackupTile,
            subtitle: l10n.settingsRestoreBackupSubtitle,
            onTap: () async {
              _report(await pickAndRestoreBackup(context, ref));
            },
          ),
          AppListRow(
            icon: Icons.move_to_inbox_outlined,
            title: l10n.settingsMangayomiImportTile,
            subtitle: l10n.settingsMangayomiImportSubtitle,
            onTap: () async {
              final confirmed = await showAppConfirmDialog(
                context: context,
                title: l10n.settingsMangayomiImportTile,
                message: l10n.settingsMangayomiImportWarning,
              );
              if (!confirmed || !context.mounted) return;
              _reportMangayomi(
                await pickAndImportMangayomiBackup(context, ref),
              );
            },
          ),
          AppListRow(
            icon: Icons.move_to_inbox_outlined,
            title: l10n.settingsMihonImportTile,
            subtitle: l10n.settingsMihonImportSubtitle,
            onTap: () async {
              final confirmed = await showAppConfirmDialog(
                context: context,
                title: l10n.settingsMihonImportTile,
                message: l10n.settingsMihonImportWarning,
              );
              if (!confirmed || !context.mounted) return;
              _reportMihon(await pickAndImportMihonBackup(context, ref));
            },
          ),
          AppSectionLabel(label: l10n.autoBackupSection),
          _autoBackupSection(l10n, prefs),
          AppSectionLabel(label: l10n.restorePointsSection),
          _restorePoints(l10n),
          AppSectionLabel(label: l10n.safetyCopiesSection),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              0,
              context.layout.gutter,
              4,
            ),
            child: Text(
              l10n.safetyCopiesHint,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          _safetyCopiesSection(l10n),
          AppSectionLabel(label: l10n.storageOverviewSection),
          AppListRow(
            icon: Icons.pie_chart_outline,
            title: l10n.storagePageTitle,
            subtitle: l10n.storagePageSubtitle,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const StoragePage())),
          ),
        ],
      ),
    );
  }
}
