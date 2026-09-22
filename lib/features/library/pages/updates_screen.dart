import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/utils/formatting/relative_date.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/library/widgets/library_filter_chips.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/library/widgets/chapter_feed_scaffold.dart';
import 'package:sumizuri/features/library/widgets/chapter_feed_tile.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/flows/open_library_entry.dart';

class UpdatesScreen extends StatelessWidget {
  const UpdatesScreen({super.key, this.mediaType, this.title});

  final MediaType? mediaType;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AmbientScaffold(
      title: Text(title ?? l10n.updatesTitle),
      body: UpdatesFeedList(mediaType: mediaType),
    );
  }
}

class UpdatesFeedList extends ConsumerStatefulWidget {
  const UpdatesFeedList({super.key, required this.mediaType});

  final MediaType? mediaType;

  @override
  ConsumerState<UpdatesFeedList> createState() => _UpdatesFeedListState();
}

class _UpdatesFeedListState extends ConsumerState<UpdatesFeedList> {
  int? _category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final updates = ref.watch(
      libraryUpdatesProvider(mediaType: widget.mediaType),
    );
    final categories = ref.watch(
      visibleCategoriesProvider(mediaType: widget.mediaType),
    );
    final membership = ref.watch(allEntryCategoryIdsProvider).value ?? const {};
    // A category that no longer exists must not leave the feed empty.
    final chosen = categories.any((c) => c.id == _category) ? _category : null;
    final shown = chosen == null
        ? updates
        : updates.whenData(
            (items) => [
              for (final item in items)
                if (membership[item.libraryEntryId]?.contains(chosen) ?? false)
                  item,
            ],
          );

    return Column(
      children: [
        if (categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilterTabRow<int>(
              brush: true,
              allLabel: l10n.libraryCategoryAll,
              selected: chosen,
              items: [for (final c in categories) (c.id, c.name)],
              onSelect: (value) => setState(() => _category = value),
            ),
          ),
        Expanded(
          child: ChapterFeedScaffold(
            value: shown,
            emptyMessage: l10n.updatesEmpty,
            dateOf: (item) => item.dateUploaded,
            itemBuilder: (context, item) => ChapterFeedTile(
              mediaType: widget.mediaType,
              coverUrl: item.entryCoverUrl,
              customCoverPath: item.customCoverPath,
              entryTitle: item.entryTitle,
              chapterNumber: item.chapterNumber,
              chapterTitle: item.chapterTitle,
              timeLabel: formatRelativeDate(
                AppLocalizations.of(context)!,
                item.dateUploaded,
              ),
              onTap: () => openLibraryEntry(
                context,
                ref,
                libraryEntryId: item.libraryEntryId,
                title: item.entryTitle,
                coverUrl: item.entryCoverUrl,
                sourceId: item.sourceId,
                externalId: item.externalId,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
