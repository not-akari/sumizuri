import 'package:sumizuri/features/extensions/entry_detail/entry_media_wording.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/utils/formatting/chapter_number.dart';
import 'package:sumizuri/core/utils/formatting/series_status_bucket.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart'
    show ExtensionService;
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/library/flows/chapter_download_flow.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';

export 'package:sumizuri/features/extensions/entry_detail/entry_detail_headers.dart';

class EntryMetaRow extends StatelessWidget {
  const EntryMetaRow({
    super.key,
    required this.entry,
    this.chapters,
    this.furthestChapter,
  });

  final MEntry entry;
  final List<MChapter>? chapters;
  final double? furthestChapter;

  @override
  Widget build(BuildContext context) {
    final genres = entry.genres ?? const <String>[];

    final scheduleGuess = looksComplete(entry.status)
        ? null
        : guessReleaseSchedule(chapters);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (EntryFactChips.hasAny(entry, furthestChapter))
            EntryFactChips(entry: entry, furthestChapter: furthestChapter),
          if (scheduleGuess != null) ...[
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!
                  .extensionUsuallyReleasesOnEstimatedFrom(scheduleGuess),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (genres.isNotEmpty) ...[
            if (EntryFactChips.hasAny(entry, furthestChapter))
              const SizedBox(height: 8),
            EntryGenreChips(genres: genres),
          ],
        ],
      ),
    );
  }
}

/// The rating, the status and how far the reader has got, as chips.
class EntryFactChips extends StatelessWidget {
  const EntryFactChips({
    super.key,
    required this.entry,
    required this.furthestChapter,
  });

  final MEntry entry;
  final double? furthestChapter;

  /// Whether there is anything to show, so the caller can leave out the space around it.
  static bool hasAny(MEntry entry, double? furthestChapter) =>
      entry.rating != null || entry.status != null || furthestChapter != null;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (entry.rating != null)
          Chip(
            avatar: const Icon(Icons.star, size: 16),
            label: Text(entry.rating!.toStringAsFixed(1)),
          ),
        if (entry.status != null)
          Chip(
            label: Text(entry.status!),
            backgroundColor: statusChipColor(entry.status),
          ),
        if (furthestChapter != null)
          Chip(
            avatar: const Icon(Icons.bookmark_added_outlined, size: 16),
            label: Text(
              AppLocalizations.of(context)!.furthest(
                EntryMediaType.of(context),
                formatChapterNumber(furthestChapter!),
              ),
            ),
          ),
      ],
    );
  }
}

/// The genres of a title as outlined chips.
class EntryGenreChips extends StatelessWidget {
  const EntryGenreChips({super.key, required this.genres});

  final List<String> genres;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final genre in genres)
          Chip(
            label: Text(genre),
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: context.shapes.chip.radius,
              side: BorderSide(color: outline),
            ),
          ),
      ],
    );
  }
}

class ExpandableDescription extends StatefulWidget {
  const ExpandableDescription({super.key, required this.text});

  final String text;

  static const _collapsedMaxLines = 4;

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : ExpandableDescription._collapsedMaxLines,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Center(
          child: IconButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          ),
        ),
      ],
    );
  }
}

bool looksComplete(String? status) =>
    classifySeriesStatus(status) == SeriesStatusBucket.completed;

Color? statusChipColor(String? status) =>
    switch (classifySeriesStatus(status)) {
      SeriesStatusBucket.hiatus => Colors.amber.withAlpha(60),
      SeriesStatusBucket.completed => Colors.green.withAlpha(60),
      SeriesStatusBucket.ongoing || SeriesStatusBucket.unknown => null,
    };

const weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String? guessReleaseSchedule(List<MChapter>? chapters) {
  if (chapters == null) return null;
  final dates = chapters
      .map((c) => c.dateUploaded)
      .whereType<DateTime>()
      .toList();
  if (dates.length < 4) return null;
  final counts = <int, int>{};
  for (final date in dates) {
    counts[date.weekday] = (counts[date.weekday] ?? 0) + 1;
  }
  final ranked = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final top = ranked.first;
  if (top.value < dates.length * 0.4) return null;
  return weekdayNames[top.key - 1];
}

class PosterAction extends StatelessWidget {
  const PosterAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: context.shapes.button.radius,
    );
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Matches PosterAction's icon square, and the seal colour marks the in-library state.
class LibraryStatusPill extends StatelessWidget {
  const LibraryStatusPill({
    super.key,
    required this.inLibrary,
    required this.label,
    required this.onTap,
  });

  final bool inLibrary;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: context.shapes.button.radius,
    );
    return Material(
      color: inLibrary
          ? cs.primary.withValues(alpha: 0.14)
          : cs.surfaceContainerHighest,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                inLibrary ? Icons.favorite : Icons.favorite_border,
                color: inLibrary ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: inLibrary ? cs.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChapterDownloadButton extends ConsumerWidget {
  const ChapterDownloadButton({
    super.key,
    required this.libraryEntryId,
    required this.chapter,
    required this.sourceId,
    required this.entryTitle,
    required this.service,
  });

  final int libraryEntryId;
  final MChapter chapter;
  final String sourceId;
  final String entryTitle;
  final ExtensionService service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDownloading = ref.watch(
      downloadingChaptersProvider.select(
        (keys) => keys.contains(downloadKey(libraryEntryId, chapter.url)),
      ),
    );
    if (isDownloading) {
      final progress = ref.watch(
        downloadProgressProvider.select(
          (all) => all[downloadKey(libraryEntryId, chapter.url)],
        ),
      );
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, value: progress),
        ),
      );
    }

    final localPath = ref
        .watch(chapterLocalPathProvider(libraryEntryId, chapter.url))
        .value;
    if (localPath != null) {
      return IconButton(
        icon: const Icon(Icons.download_done, size: 20),
        tooltip: l10n.chapterRemoveDownload,
        onPressed: () async {
          await deleteChapterDownload(
            repository: ref.read(libraryRepositoryProvider),
            libraryEntryId: libraryEntryId,
            chapterUrl: chapter.url,
            localPath: localPath,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.chapterDownloadRemoved)),
            );
          }
        },
      );
    }

    return IconButton(
      icon: const Icon(Icons.download_outlined, size: 20),
      tooltip: l10n.chapterDownload,
      onPressed: () => downloadChapter(
        context: context,
        ref: ref,
        service: service,
        libraryEntryId: libraryEntryId,
        sourceId: sourceId,
        entryTitle: entryTitle,
        chapter: chapter,
      ),
    );
  }
}
