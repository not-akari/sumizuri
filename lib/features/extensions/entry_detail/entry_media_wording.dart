import 'package:flutter/widgets.dart';

import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class EntryMediaType extends InheritedWidget {
  const EntryMediaType({
    super.key,
    required this.mediaType,
    required super.child,
  });

  final MediaType mediaType;

  /// The type of the entry on screen. Manga when nothing above says otherwise.
  static MediaType of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EntryMediaType>()?.mediaType ??
      MediaType.manga;

  @override
  bool updateShouldNotify(EntryMediaType oldWidget) =>
      mediaType != oldWidget.mediaType;
}

extension EntryWording on AppLocalizations {
  String chaptersHeading(MediaType type) => type == MediaType.anime
      ? sourceBrowseEpisodesHeading
      : sourceBrowseChaptersHeading;

  String chapterCount(MediaType type, int count) => type == MediaType.anime
      ? sourceBrowseEpisodeCount(count)
      : sourceBrowseChapterCount(count);

  String continueLabel(MediaType type) => type == MediaType.anime
      ? sourceBrowseContinueWatching
      : sourceBrowseContinueReading;

  String continueResume(MediaType type, String number) =>
      type == MediaType.anime
      ? continueWatchingResume(number)
      : continueReadingResume(number);

  String continueNext(MediaType type, String number) => type == MediaType.anime
      ? continueWatchingNext(number)
      : continueReadingNext(number);

  String continueAlternative(MediaType type, String number) =>
      type == MediaType.anime
      ? continueWatchingAlternative(number)
      : continueReadingAlternative(number);

  String markRead(MediaType type) =>
      type == MediaType.anime ? episodeMarkWatched : chapterSwipeMarkRead;

  String markUnread(MediaType type) =>
      type == MediaType.anime ? episodeMarkUnwatched : chapterSwipeMarkUnread;

  String furthest(MediaType type, String number) => type == MediaType.anime
      ? entryDetailFurthestWatchedBadge(number)
      : entryDetailFurthestBadge(number);

  String markAllRead(MediaType type) => type == MediaType.anime
      ? episodeMenuMarkAllWatched
      : chapterMenuMarkAllRead;

  String markAllUnread(MediaType type) => type == MediaType.anime
      ? episodeMenuMarkAllUnwatched
      : chapterMenuMarkAllUnread;

  String markPreviousRead(MediaType type) => type == MediaType.anime
      ? episodeMarkPreviousAsWatched
      : chapterMarkPreviousAsRead;
}
