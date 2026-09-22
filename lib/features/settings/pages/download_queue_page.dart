import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/widgets/overlays/app_menu.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/features/library/flows/download_queue.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

extension on _QueueClear {
  String label(AppLocalizations l10n) => switch (this) {
    _QueueClear.failed => l10n.downloadQueueClearFailed,
    _QueueClear.all => l10n.downloadQueueCancelAll,
  };
}

/// Everything downloading, waiting, paused or failed, with pause, resume, retry and cancel.
enum _QueueClear { failed, all }

class DownloadQueuePage extends ConsumerWidget {
  const DownloadQueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(downloadQueueProvider);
    final queue = ref.read(downloadQueueProvider.notifier);
    List<DownloadItem> withStatus(DownloadStatus status) => [
      for (final item in items)
        if (item.status == status) item,
    ];
    final running = withStatus(DownloadStatus.running);
    final waiting = withStatus(DownloadStatus.queued);
    final paused = withStatus(DownloadStatus.paused);
    final failed = withStatus(DownloadStatus.failed);
    final active = running.isNotEmpty || waiting.isNotEmpty;

    Widget section(String label, List<DownloadItem> rows) => rows.isEmpty
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionLabel(label: '$label  ${rows.length}'),
              for (final item in rows) _DownloadTile(item: item),
            ],
          );

    return AmbientScaffold(
      maxContentWidth: 720,
      title: Text(l10n.downloadQueueTitle),
      actions: [
        if (active)
          IconButton(
            icon: const Icon(Icons.pause_circle_outline),
            tooltip: l10n.downloadQueuePauseAll,
            onPressed: queue.pauseAll,
          )
        else if (paused.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            tooltip: l10n.downloadQueueResumeAll,
            onPressed: queue.resumeAll,
          ),
        if (items.isNotEmpty)
          AppMenu<_QueueClear>.of(
            onSelected: (choice) {
              switch (choice) {
                case _QueueClear.failed:
                  queue.clearFailed();
                case _QueueClear.all:
                  for (final item in [...items]) {
                    queue.cancel(item.key);
                  }
              }
            },
            values: _QueueClear.values,
            label: (a) => a.label(l10n),
            visible: (a) => a != _QueueClear.failed || failed.isNotEmpty,
          ),
      ],
      body: items.isEmpty
          ? Center(child: Text(l10n.downloadQueueEmpty))
          : ListView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
              children: [
                section(l10n.downloadQueueRunning, running),
                section(l10n.downloadQueueWaiting, waiting),
                section(l10n.downloadQueuePaused, paused),
                section(l10n.downloadQueueFailed, failed),
              ],
            ),
    );
  }
}

class _DownloadTile extends ConsumerWidget {
  const _DownloadTile({required this.item});

  final DownloadItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final queue = ref.read(downloadQueueProvider.notifier);
    final status = item.status;
    final request = item.request;
    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.entryTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  request.chapter.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (status == DownloadStatus.running) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: item.progress,
                      minHeight: 4,
                      backgroundColor: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
                if (status == DownloadStatus.failed && item.error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.error!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
                  ),
                ],
              ],
            ),
          ),
          if (status == DownloadStatus.running ||
              status == DownloadStatus.queued)
            IconButton(
              icon: const Icon(Icons.pause),
              tooltip: l10n.downloadQueuePause,
              onPressed: () => queue.pause(item.key),
            )
          else if (status == DownloadStatus.paused)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: l10n.downloadQueueResume,
              onPressed: () => queue.resume(item.key),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.downloadQueueRetry,
              onPressed: () => queue.resume(item.key),
            ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.downloadQueueCancel,
            onPressed: () => queue.cancel(item.key),
          ),
        ],
      ),
    );
  }
}
