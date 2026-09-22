import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/cards/feed_row.dart';
import 'package:sumizuri/core/utils/formatting/chapter_number.dart';
import 'package:sumizuri/core/widgets/content/manga_cover_tile.dart';
import 'package:sumizuri/features/library/models/library_types.dart';

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
    this.mediaType,
  });

  final MediaType? mediaType;

  final String? coverUrl;
  final String? customCoverPath;
  final String entryTitle;
  final double chapterNumber;
  final String? chapterTitle;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = chapterTitle != null && chapterTitle!.isNotEmpty
        ? '${mediaType == MediaType.anime ? 'Ep.' : 'Ch.'} ${formatChapterNumber(chapterNumber)} · $chapterTitle'
        : '${mediaType == MediaType.anime ? 'Episode' : 'Chapter'} ${formatChapterNumber(chapterNumber)}';
    return FeedRow(
      onTap: onTap,
      leading: LibraryCoverThumbnail(
        coverUrl: coverUrl,
        customCoverPath: customCoverPath,
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
