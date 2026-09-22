import 'package:flutter/material.dart';

import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/reader/viewers/chapter_end_footer.dart';
import 'package:sumizuri/features/reader/viewers/continuous_viewer_items.dart';
import 'package:sumizuri/features/reader/viewers/continuous_viewer_status_widgets.dart';
import 'package:sumizuri/features/reader/widgets/reader_page_image.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

Widget buildContinuousItem(
  BuildContext context,
  ContinuousItem item, {
  required Color textColor,
  required double gap,
  required Widget Function(Widget child) constrainPage,
  required GlobalKey Function(String chapterUrl, int pageIndex) pageKeyFor,
  required ReaderScaleType scaleType,
  required ReaderBackground background,
  required ReaderImageQuality imageQuality,
  required Map<String, String>? headers,
  required bool hasPreviousChapter,
  required bool hasNextChapter,
  required VoidCallback onPreviousChapter,
  required VoidCallback onNextChapter,
  required VoidCallback? onLoadPrevious,
  required VoidCallback? onRetryNext,
  required VoidCallback onImageLoaded,
}) {
  switch (item) {
    case TopItem(:final hasPreviousChapter, :final isLoading, :final error):
      return buildContinuousTop(
        context,
        hasPreviousChapter: hasPreviousChapter,
        isLoading: isLoading,
        error: error,
        textColor: textColor,
        onLoadPrevious: onLoadPrevious,
      );

    case HeaderItem(:final chapter):
      return KeyedSubtree(
        key: ValueKey('${chapter.url}_header'),
        child: buildContinuousHeader(context, chapter, textColor),
      );

    case LoadingItem(:final chapter):
      return buildContinuousLoading(context, chapter, textColor);

    case ErrorItem(:final chapter, :final error):
      return buildContinuousError(
        context,
        chapter,
        error,
        textColor,
        onRetryNext: onRetryNext,
      );

    case FooterItem(:final isEndOfManga):
      if (isEndOfManga) {
        final l10n = AppLocalizations.of(context)!;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: textColor.withValues(alpha: 0.5),
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.readerNoMoreChapters,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ChapterEndFooter(
        hasPreviousChapter: hasPreviousChapter,
        hasNextChapter: hasNextChapter,
        onPreviousChapter: onPreviousChapter,
        onNextChapter: onNextChapter,
        textColor: textColor,
      );

    case PageItem(:final chapter, :final page, :final pageIndex):
      return Padding(
        key: pageKeyFor(chapter.url, pageIndex),
        padding: EdgeInsets.only(bottom: gap),
        child: constrainPage(
          ReaderPageImage(
            page: page,
            scaleType: scaleType,
            background: background,
            enableGesture: false,
            imageQuality: imageQuality,
            headers: headers,
            onLoaded: onImageLoaded,
          ),
        ),
      );
  }
}
