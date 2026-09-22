import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/utils/files/folder_picker.dart';
import 'package:sumizuri/core/utils/files/folder_problem_text.dart';
import 'package:flutter/material.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/library/models/downloaded_entry.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/library/flows/chapter_download_flow.dart';
import 'package:sumizuri/features/library/flows/download_queue.dart';
import 'package:sumizuri/features/settings/pages/download_queue_page.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/settings/data/storage_breakdown.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/settings/widgets/auto_download_limits.dart';
import 'package:sumizuri/features/settings/widgets/storage_widgets.dart';

class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({super.key});

  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage> {
  Map<int, int> _sizesByEntry = const {};
  int _totalBytes = 0;
  List<DownloadedEntry> _sizedFor = const [];

  Future<void> _recomputeSizes(List<DownloadedEntry> entries) async {
    final sizes = await measureDownloadedEntries(entries);
    if (!mounted) return;
    setState(() {
      _sizesByEntry = sizes.byEntry;
      _totalBytes = sizes.total;
      _sizedFor = entries;
    });
  }

  Future<bool> _confirmDelete(String title, String message) {
    final l10n = AppLocalizations.of(context)!;
    return showAppConfirmDialog(
      context: context,
      title: title,
      message: message,
      confirmLabel: l10n.storageDeleteConfirmConfirm,
      cancelLabel: l10n.browseAddWarningCancel,
      isDestructive: true,
    );
  }

  Future<void> _deleteEntryDownloads(DownloadedEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirmDelete(
      l10n.storageDeleteEntryConfirmTitle(entry.title),
      l10n.storageDeleteEntryConfirmMessage,
    );
    if (!confirmed) return;
    final repository = ref.read(libraryRepositoryProvider);
    for (final chapter in entry.chapters) {
      await deleteChapterDownload(
        repository: repository,
        libraryEntryId: entry.entryId,
        chapterUrl: chapter.chapterUrl,
        localPath: chapter.localPath,
      );
    }
  }

  Future<void> _deleteAllDownloads(List<DownloadedEntry> entries) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirmDelete(
      l10n.storageDeleteAllConfirmTitle,
      l10n.storageDeleteAllConfirmMessage,
    );
    if (!confirmed) return;
    final repository = ref.read(libraryRepositoryProvider);
    for (final entry in entries) {
      for (final chapter in entry.chapters) {
        await deleteChapterDownload(
          repository: repository,
          libraryEntryId: entry.entryId,
          chapterUrl: chapter.chapterUrl,
          localPath: chapter.localPath,
        );
      }
    }
  }

  Future<void> _pickDownloadDirectory(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSheetHeader(title: l10n.settingsDownloadLocationTile),
            AppListRow(
              icon: Icons.folder_outlined,
              title: l10n.settingsDownloadLocationChoose,
              onTap: () => Navigator.of(context).pop('choose'),
            ),
            AppListRow(
              icon: Icons.restart_alt,
              title: l10n.settingsDownloadLocationReset,
              onTap: () => Navigator.of(context).pop('reset'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    if (choice == 'reset') {
      await ref.read(settingsRepositoryProvider).setDownloadDirectoryPath(null);
      return;
    }

    final pick = await pickFolder(
      dialogTitle: l10n.settingsDownloadLocationTile,
    );
    if (!context.mounted) return;
    final problem = pick.problem;
    if (problem != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(folderProblemText(l10n, problem))));
      return;
    }
    final path = pick.path;
    if (path == null) return;
    await ref.read(settingsRepositoryProvider).setDownloadDirectoryPath(path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final entries = ref.watch(downloadedEntriesProvider).value ?? const [];
    final downloadDirPath = ref.watch(downloadDirectoryPathProvider).value;
    final autoOnUpdate =
        ref.watch(autoDownloadOnLibraryUpdateProvider).value ?? false;
    final autoOnAdd =
        ref.watch(autoDownloadOnAddToLibraryProvider).value ?? false;
    final wifiOnly = ref.watch(downloadsWifiOnlyProvider).value ?? true;
    final autoLimit = ref.watch(autoDownloadChapterLimitProvider).value ?? 0;
    final keepBehind = ref.watch(keepDownloadsBehindProvider).value ?? -1;
    final downloadAhead =
        ref.watch(intSettingProvider(Settings.downloadAheadCount)).value ?? 0;
    final downloadDelay = ref.watch(downloadDelaySecondsProvider).value ?? 1;
    final repo = ref.read(settingsRepositoryProvider);
    final queueCount = ref.watch(downloadQueueProvider).length;

    if (!DownloadedEntry.sameLists(entries, _sizedFor)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _recomputeSizes(entries),
      );
    }
    final totalChapters = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.chapters.length,
    );

    return AmbientScaffold(
      maxContentWidth: 720,
      title: Text(l10n.downloadsTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
        children: [
          AppListRow(
            icon: Icons.downloading_outlined,
            title: l10n.downloadQueueTitle,
            subtitle: l10n.downloadQueueRowHint(queueCount),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DownloadQueuePage(),
              ),
            ),
          ),
          AppListRow(
            icon: Icons.pie_chart_outline,
            title: l10n.storageUsageSummary(
              formatStorageBytes(_totalBytes),
              totalChapters,
              entries.length,
            ),
          ),
          AppSectionLabel(label: l10n.storageDownloadsSectionTitle),
          AppListRow(
            icon: Icons.folder_outlined,
            title: l10n.settingsDownloadLocationTile,
            subtitle: downloadDirPath ?? l10n.settingsDownloadLocationDefault,
            onTap: () => _pickDownloadDirectory(context, ref),
          ),
          AppSwitchRow(
            icon: Icons.cloud_download_outlined,
            title: l10n.storageAutoDownloadOnUpdate,
            subtitle: l10n.storageAutoDownloadOnUpdateHint,
            value: autoOnUpdate,
            onChanged: repo.setAutoDownloadOnLibraryUpdate,
          ),
          AppSwitchRow(
            icon: Icons.playlist_add_check_outlined,
            title: l10n.storageAutoDownloadOnAdd,
            subtitle: l10n.storageAutoDownloadOnAddHint,
            value: autoOnAdd,
            onChanged: repo.setAutoDownloadOnAddToLibrary,
          ),
          AppSwitchRow(
            icon: Icons.copy_all_outlined,
            title: l10n.downloadsSkipDuplicateRead,
            subtitle: l10n.downloadsSkipDuplicateReadHint,
            value:
                ref
                    .watch(
                      boolSettingProvider(Settings.downloadsSkipDuplicateRead),
                    )
                    .value ??
                false,
            onChanged: (on) =>
                repo.putSetting(Settings.downloadsSkipDuplicateRead, on),
          ),
          AppSwitchRow(
            icon: Icons.wifi_outlined,
            title: l10n.downloadsWifiOnlyTitle,
            subtitle: l10n.downloadsWifiOnlyHint,
            value: wifiOnly,
            onChanged: repo.setDownloadsWifiOnly,
          ),
          AppListRow(
            icon: Icons.timer_outlined,
            title: l10n.settingsDownloadDelayTile,
            subtitle: l10n.settingsDownloadDelaySubtitle,
            trailing: AppChoice<int>.of(
              style: AppChoiceStyle.menu,
              expanded: false,
              values: const [0, 1, 2, 3, 5],
              label: (seconds) => seconds == 0
                  ? l10n.settingsDownloadDelayOff
                  : l10n.settingsNetworkTimeoutSeconds(seconds),
              value: const [0, 1, 2, 3, 5].contains(downloadDelay)
                  ? downloadDelay
                  : 1,
              onChanged: repo.setDownloadDelaySeconds,
            ),
          ),
          AutoDownloadLimitsSection(
            autoLimit: autoLimit,
            keepBehind: keepBehind,
            downloadAhead: downloadAhead,
            onAutoLimitChanged: repo.setAutoDownloadChapterLimit,
            onKeepBehindChanged: repo.setKeepDownloadsBehind,
            onDownloadAheadChanged: (count) =>
                repo.putSetting(Settings.downloadAheadCount, count),
          ),
          AppSectionLabel(label: l10n.storageDownloadedEntriesTitle),
          if (entries.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.layout.gutter,
                vertical: 8,
              ),
              child: Text(
                l10n.storageNoDownloadsYet,
                style: theme.textTheme.bodyMedium,
              ),
            )
          else ...[
            StorageDownloadedEntriesCard(
              entries: entries,
              sizesByEntry: _sizesByEntry,
              onDeleteEntryDownloads: _deleteEntryDownloads,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.layout.gutter,
                8,
                context.layout.gutter,
                0,
              ),
              child: OutlinedButton.icon(
                onPressed: () => _deleteAllDownloads(entries),
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(l10n.storageDeleteAllDownloads),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
