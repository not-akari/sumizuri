// Horizontal row of AniList recommendation suggestions.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/content/cover_image.dart';
import 'package:sumizuri/features/extensions/pages/global_search_page.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/trackers/data/anilist/anilist_recommendations.dart';
import 'package:sumizuri/features/trackers/models/anilist_media.dart';
import 'package:sumizuri/features/trackers/providers/anilist_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class EntryRecommendationsRow extends ConsumerStatefulWidget {
  const EntryRecommendationsRow({
    super.key,
    required this.title,
    required this.mediaType,
    this.libraryEntryId,
  });

  final String title;
  final MediaType mediaType;

  /// Used to prefer an already-linked AniList title over guessing by name.
  final int? libraryEntryId;

  @override
  ConsumerState<EntryRecommendationsRow> createState() =>
      _EntryRecommendationsRowState();
}

class _EntryRecommendationsRowState
    extends ConsumerState<EntryRecommendationsRow> {
  List<AniListMedia>? _results;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final results = await findAniListRecommendations(
      api: ref.read(aniListApiClientProvider),
      trackerStore: ref.read(trackerStoreProvider),
      title: widget.title,
      mediaType: widget.mediaType,
      libraryEntryId: widget.libraryEntryId,
    );
    if (mounted) setState(() => _results = results);
  }

  void _openSearch(AniListMedia media) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GlobalSearchPage(
          mediaType: widget.mediaType,
          initialQuery: media.title.display,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    if (results == null || results.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final gutter = context.layout.gutter;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: Text(
              l10n.entryRecommendationsTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 188,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: gutter),
              itemCount: results.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final media = results[index];
                return _RecommendationCard(
                  media: media,
                  onTap: () => _openSearch(media),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.media, required this.onTap});

  final AniListMedia media;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CoverImage(url: media.coverUrl),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              media.title.display,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
