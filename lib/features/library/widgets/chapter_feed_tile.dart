import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/cards/feed_row.dart';
import 'package:sumizuri/core/utils/formatting/chapter_number.dart';
import 'package:sumizuri/core/widgets/content/manga_cover_tile.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// What a new chapter or episode is called, in the person's language.
String chapterFeedText(
  AppLocalizations l10n,
  MediaType mediaType,
  double number,
  String? title,
) {
  final shown = formatChapterNumber(number);
  final anime = mediaType == MediaType.anime;
  if (title != null && title.isNotEmpty) {
    return anime
        ? l10n.feedEpisodeTitled(shown, title)
        : l10n.feedChapterTitled(shown, title);
  }
  return anime ? l10n.feedEpisode(shown) : l10n.feedChapter(shown);
}

class ChapterFeedTile extends StatelessWidget {
  const ChapterFeedTile({
    super.key,
    required this.coverUrl,
    this.customCoverPath,
    required this.entryTitle,
    required this.chapterNumber,
    required this.chapterTitle,
    required this.timeLabel,
    required this.onTap,
    this.mediaType = MediaType.manga,
    this.dense = false,
  });

  /// Whether the number is a chapter or an episode.
  final MediaType mediaType;

  /// A smaller cover, so more rows fit.
  final bool dense;

  final String? coverUrl;
  final String? customCoverPath;
  final String entryTitle;
  final double chapterNumber;
  final String? chapterTitle;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtitle = chapterFeedText(
      l10n,
      mediaType,
      chapterNumber,
      chapterTitle,
    );
    return FeedRow(
      onTap: onTap,
      leading: LibraryCoverThumbnail(
        coverUrl: coverUrl,
        customCoverPath: customCoverPath,
        width: dense ? 32 : 42,
      ),
      title: entryTitle,
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        timeLabel,
        style: TextStyle(
          fontSize: 11.5,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
