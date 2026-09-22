import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/library/models/library_feed_types.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';

export 'package:sumizuri/core/utils/formatting/chapter_number.dart'
    show formatChapterNumber, parseChapterNumber, sortChapters;

MChapter chapterFromRecord(ChapterRecord record) => MChapter(
  url: record.url,
  title: record.title ?? '',
  number: record.number,
  dateUploaded: record.dateUploaded,
  read: record.consumed,
  progress: record.progressPosition,
  bookmarked: record.bookmarked,
  scanlator: record.scanlator,
);

void syncEntryChapters({
  required WidgetRef ref,
  required int libraryEntryId,
  required List<MChapter> chapters,
}) {
  ref
      .read(libraryRepositoryProvider)
      .syncChapters(
        libraryEntryId: libraryEntryId,
        chapters: [
          for (final chapter in chapters)
            ChapterSyncItem(
              url: chapter.url,
              number: chapter.number,
              title: chapter.title,
              dateUploaded: chapter.dateUploaded,
              scanlator: chapter.scanlator,
            ),
        ],
      );
}
