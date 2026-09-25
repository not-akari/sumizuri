import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/utils/formatting/media_type_label.dart';
import 'package:sumizuri/core/utils/formatting/relative_date.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/features/library/flows/open_library_entry.dart';
import 'package:sumizuri/features/library/models/category_membership.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/widgets/chapter_feed_scaffold.dart';
import 'package:sumizuri/core/widgets/content/manga_cover_tile.dart';
import 'package:sumizuri/features/library/widgets/chapter_feed_tile.dart';
import 'package:sumizuri/features/library/widgets/display_style_sheet.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/library/widgets/library_filter_chips.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class UpdatesScreen extends StatelessWidget {
  const UpdatesScreen({super.key, this.mediaType, this.title});

  final MediaType? mediaType;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AmbientScaffold(
      title: Text(title ?? l10n.updatesTitle),
      actions: [
        IconButton(
          icon: const Icon(Icons.view_module_outlined),
          tooltip: l10n.libraryDisplayButtonTooltip,
          onPressed: () => showDisplayStyleSheet(
            context,
            title: l10n.libraryDisplayUpdatesPage,
            setting: Settings.updatesDisplayStyle,
            provider: updatesDisplayStyleProvider,
          ),
        ),
      ],
      body: UpdatesFeedList(mediaType: mediaType),
    );
  }
}

/// New chapters and episodes. With one library for everything it is first
/// sorted by kind of title, and only then by category, since a category
/// belongs to one kind: manga and anime can both have a "Reading".
class UpdatesFeedList extends ConsumerStatefulWidget {
  const UpdatesFeedList({super.key, required this.mediaType});

  /// Set when the app keeps a library for each kind, so there is nothing to sort.
  final MediaType? mediaType;

  @override
  ConsumerState<UpdatesFeedList> createState() => _UpdatesFeedListState();
}

class _UpdatesFeedListState extends ConsumerState<UpdatesFeedList> {
  MediaType? _type;
  int? _category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enabledTypes = ref.watch(enabledMediaTypesProvider).orMangaOnly;
    final showTypes = widget.mediaType == null && enabledTypes.length > 1;
    final type =
        widget.mediaType ??
        (showTypes && enabledTypes.contains(_type) ? _type : null);

    final style =
        ref.watch(updatesDisplayStyleProvider).value ??
        LibraryDisplayStyle.list;
    final updates = ref.watch(libraryUpdatesProvider(mediaType: type));
    // Categories of several kinds mixed would repeat names and mean nothing.
    final categories = type == null
        ? const []
        : ref.watch(visibleCategoriesProvider(mediaType: type));
    final membership = ref.watch(allEntryCategoryIdsProvider).value ?? const {};
    final hideAllChip = ref.watch(hideAllCategoryChipProvider).value ?? false;
    final hideDefaultChip =
        ref.watch(hideUncategorizedCategoryChipProvider).value ?? false;
    // A category that no longer exists must not leave the feed empty.
    final chosen =
        _category == uncategorizedCategoryId ||
            categories.any((c) => c.id == _category)
        ? _category
        : null;
    final shown = chosen == null
        ? updates
        : updates.whenData(
            (items) => [
              for (final item in items)
                if (isInCategory(membership, item.libraryEntryId, chosen)) item,
            ],
          );

    return Column(
      children: [
        if (showTypes)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilterTabRow<MediaType>(
              allLabel: l10n.libraryCategoryAll,
              selected: type,
              items: [
                for (final t in MediaType.values)
                  if (enabledTypes.contains(t)) (t, mediaTypeLabel(t, l10n)),
              ],
              onSelect: (value) => setState(() {
                _type = value;
                _category = null;
              }),
            ),
          ),
        if (categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilterTabRow<int>(
              brush: true,
              allLabel: l10n.libraryCategoryAll,
              showAllChip: !hideAllChip,
              selected: chosen,
              items: [
                if (!hideDefaultChip)
                  (uncategorizedCategoryId, l10n.libraryCategoryDefault),
                for (final c in categories) (c.id, c.name),
              ],
              onSelect: (value) => setState(() => _category = value),
            ),
          ),
        Expanded(
          child: ChapterFeedScaffold(
            value: shown,
            style: style,
            emptyMessage: l10n.updatesEmpty,
            dateOf: (item) => item.dateUploaded,
            itemBuilder: (context, item, style) {
              void open() => openLibraryEntry(
                context,
                ref,
                libraryEntryId: item.libraryEntryId,
                title: item.entryTitle,
                coverUrl: item.entryCoverUrl,
                sourceId: item.sourceId,
                externalId: item.externalId,
              );
              if (style.isGrid) {
                return MangaCoverTile(
                  variant: switch (style) {
                    LibraryDisplayStyle.compactGrid => CoverTileVariant.compact,
                    LibraryDisplayStyle.coverGrid => CoverTileVariant.coverOnly,
                    _ => CoverTileVariant.comfortable,
                  },
                  title: item.entryTitle,
                  coverUrl: item.entryCoverUrl,
                  customCoverPath: item.customCoverPath,
                  caption: chapterFeedText(
                    l10n,
                    item.mediaType,
                    item.chapterNumber,
                    null,
                  ),
                  onTap: open,
                );
              }
              return ChapterFeedTile(
                mediaType: item.mediaType,
                dense: style == LibraryDisplayStyle.compactList,
                coverUrl: item.entryCoverUrl,
                customCoverPath: item.customCoverPath,
                entryTitle: item.entryTitle,
                chapterNumber: item.chapterNumber,
                chapterTitle: item.chapterTitle,
                timeLabel: formatRelativeDate(l10n, item.dateUploaded),
                onTap: open,
              );
            },
          ),
        ),
      ],
    );
  }
}
