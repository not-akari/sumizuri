import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/cards/feed_row.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/content/cover_image.dart';
import 'package:sumizuri/features/library/models/downloaded_entry.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

String formatStorageBytes(int bytes) {
  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;
  if (bytes < kb) return '$bytes B';
  if (bytes < mb) return '${(bytes / kb).toStringAsFixed(1)} KB';
  if (bytes < gb) return '${(bytes / mb).toStringAsFixed(1)} MB';
  return '${(bytes / gb).toStringAsFixed(2)} GB';
}

class StorageDownloadedEntriesCard extends StatelessWidget {
  const StorageDownloadedEntriesCard({
    super.key,
    required this.entries,
    required this.sizesByEntry,
    required this.onDeleteEntryDownloads,
  });

  final List<DownloadedEntry> entries;
  final Map<int, int> sizesByEntry;
  final void Function(DownloadedEntry entry) onDeleteEntryDownloads;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        for (final entry in entries)
          FeedRow(
            leading: SizedBox(
              width: 40,
              height: 56,
              child: ClipRRect(
                borderRadius: context.shapes.cover.radius,
                child: CoverImage(
                  url: entry.coverUrl,
                  filePath: entry.customCoverPath,
                ),
              ),
            ),
            title: entry.title,
            subtitle: Text(
              '${l10n.storageChapterCount(entry.chapters.length)} · '
              '${formatStorageBytes(sizesByEntry[entry.entryId] ?? 0)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.storageDeleteEntryDownloads,
              onPressed: () => onDeleteEntryDownloads(entry),
            ),
          ),
      ],
    );
  }
}
