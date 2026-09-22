import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/settings/widgets/clear_image_cache_row.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/core/utils/files/folder_picker.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/features/library/flows/chapter_download_flow.dart';
import 'package:sumizuri/features/settings/data/cache_reset.dart';
import 'package:sumizuri/features/settings/data/storage_breakdown.dart';
import 'package:sumizuri/features/settings/pages/downloads_page.dart';
import 'package:sumizuri/features/settings/flows/data_folder_flow.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/settings/widgets/storage_widgets.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class StoragePage extends ConsumerStatefulWidget {
  const StoragePage({super.key});

  @override
  ConsumerState<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends ConsumerState<StoragePage> {
  Future<StorageBreakdown>? _storage;

  late final Future<Directory> _dataFolder = appDataDirectory();

  Future<StorageBreakdown> _measure() async {
    final path = await ref
        .read(settingsRepositoryProvider)
        .watchDownloadDirectoryPath()
        .first;
    return measureStorage(downloadsPath: path);
  }

  Future<void> _clearUnfinished() async {
    final l10n = AppLocalizations.of(context)!;
    if (ref.read(downloadingChaptersProvider).isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.storageBusyDownloading)));
      return;
    }
    final ok = await showAppConfirmDialog(
      context: context,
      title: l10n.storageClearUnfinishedTitle,
      message: l10n.storageClearUnfinishedMessage,
      confirmLabel: l10n.storageClear,
      isDestructive: true,
    );
    if (!ok || !mounted) return;
    final path = await ref
        .read(settingsRepositoryProvider)
        .watchDownloadDirectoryPath()
        .first;
    final freed = await clearUnfinishedDownloads(
      await downloadsDirectory(overridePath: path),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.storageFreed(formatStorageBytes(freed)))),
    );
    setState(() {
      _storage = _measure();
    });
  }

  Future<void> _clearSessions() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showAppConfirmDialog(
      context: context,
      title: l10n.storageClearSessionsTitle,
      message: l10n.storageClearSessionsMessage,
      confirmLabel: l10n.storageClear,
      isDestructive: true,
    );
    if (!ok || !mounted) return;
    await resetSourceSessions();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.storageSessionsCleared)));
    setState(() {
      _storage = _measure();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = TextStyle(
      fontSize: 13,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    _storage ??= _measure();
    return AmbientScaffold(
      maxContentWidth: 720,
      title: Text(l10n.storagePageTitle),
      actions: [
        IconButton(
          tooltip: l10n.storageRefresh,
          icon: const Icon(Icons.refresh),
          onPressed: () => setState(() {
            _storage = _measure();
          }),
        ),
      ],
      body: FutureBuilder<StorageBreakdown>(
        future: _storage,
        builder: (context, snapshot) {
          final s = snapshot.data;
          if (s == null) {
            return const Center(child: CircularProgressIndicator());
          }
          Widget row(
            IconData icon,
            String title,
            int bytes, {
            String? subtitle,
            Widget? action,
            VoidCallback? onTap,
          }) => AppListRow(
            icon: icon,
            title: title,
            subtitle: subtitle,
            onTap: onTap,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(formatStorageBytes(bytes), style: muted),
                ?action,
              ],
            ),
          );
          return ListView(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              8,
              context.layout.gutter,
              96,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  formatStorageBytes(s.total),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              row(
                Icons.download_outlined,
                l10n.storageDownloadedChapters,
                s.downloads - s.unfinishedDownloads,
                subtitle: l10n.storageManageDownloads,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DownloadsPage()),
                ),
              ),
              if (s.unfinishedDownloads > 0)
                row(
                  Icons.pause_circle_outline,
                  l10n.storageUnfinishedDownloads,
                  s.unfinishedDownloads,
                  subtitle: l10n.storageUnfinishedDownloadsHint,
                  action: TextButton(
                    onPressed: _clearUnfinished,
                    child: Text(l10n.storageClear),
                  ),
                ),
              row(Icons.storage_outlined, l10n.storageDatabase, s.database),
              if (canChooseFolders)
                FutureBuilder<Directory>(
                  future: _dataFolder,
                  builder: (context, folder) => AppListRow(
                    icon: Icons.folder_outlined,
                    title: l10n.dataLocationDataFolder,
                    subtitle: folder.data?.path,
                    onTap: () => changeDataFolder(context),
                  ),
                ),
              row(
                Icons.backup_outlined,
                l10n.storageAutoBackups,
                s.autoBackups,
              ),
              row(
                Icons.history_outlined,
                l10n.storageSafetyCopies,
                s.safetyCopies,
              ),
              row(
                Icons.palette_outlined,
                l10n.storageThemesFonts,
                s.themesAndFonts,
              ),
              row(
                Icons.image_outlined,
                l10n.storageCustomCovers,
                s.customCovers,
              ),
              row(
                Icons.cookie_outlined,
                l10n.storageSourceSessions,
                s.sourceSessions,
                subtitle: l10n.storageSourceSessionsHint,
                action: TextButton(
                  onPressed: _clearSessions,
                  child: Text(l10n.storageClear),
                ),
              ),
              const ClearImageCacheRow(),
            ],
          );
        },
      ),
    );
  }
}
