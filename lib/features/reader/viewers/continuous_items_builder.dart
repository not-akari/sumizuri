import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_page.dart';
import 'package:sumizuri/features/reader/models/reader_session_state.dart';
import 'package:sumizuri/features/reader/viewers/continuous_viewer_items.dart';

class ContinuousItemsBuilder {
  List<ContinuousItem>? _cache;
  List<ContinuousChapter>? _cacheChapters;
  List<MPage>? _cachePages;
  bool _cacheHasNextChapter = false;

  List<ContinuousItem> build({
    required List<ContinuousChapter>? continuousChapters,
    required List<MPage> pages,
    required MChapter? currentChapter,
    required bool hasNextChapter,
    required bool hasPreviousChapter,
  }) {
    final cache = _cache;
    if (cache != null &&
        identical(continuousChapters, _cacheChapters) &&
        identical(pages, _cachePages) &&
        hasNextChapter == _cacheHasNextChapter) {
      return cache;
    }
    final items = _compute(
      continuousChapters: continuousChapters,
      pages: pages,
      currentChapter: currentChapter,
      hasNextChapter: hasNextChapter,
      hasPreviousChapter: hasPreviousChapter,
    );
    _cache = items;
    _cacheChapters = continuousChapters;
    _cachePages = pages;
    _cacheHasNextChapter = hasNextChapter;
    return items;
  }

  List<ContinuousItem> _compute({
    required List<ContinuousChapter>? continuousChapters,
    required List<MPage> pages,
    required MChapter? currentChapter,
    required bool hasNextChapter,
    required bool hasPreviousChapter,
  }) {
    final chapters = continuousChapters;
    if (chapters == null || chapters.isEmpty) {
      final ch = currentChapter ?? const MChapter(url: '', title: '');
      return [
        for (var i = 0; i < pages.length; i++) PageItem(ch, pages[i], i),
        FooterItem(isEndOfManga: !hasNextChapter),
      ];
    }

    final items = <ContinuousItem>[];

    final first = chapters.first;
    final firstIsLoading = first.isLoading && first.pages.isEmpty;
    final firstHasError = first.error != null && first.pages.isEmpty;
    if (firstIsLoading || firstHasError) {
      items.add(
        TopItem(
          hasPreviousChapter: hasPreviousChapter,
          isLoading: firstIsLoading,
          error: firstHasError ? first.error : null,
          prevChapter: first.chapter,
        ),
      );
    }

    for (var cIdx = 0; cIdx < chapters.length; cIdx++) {
      final c = chapters[cIdx];
      if (c.isLoading && c.pages.isEmpty && cIdx == 0) {
        continue;
      }
      if (c.error != null && c.pages.isEmpty && cIdx == 0) {
        continue;
      }

      if (cIdx > 0) {
        items.add(HeaderItem(c.chapter));
      }
      for (var pIdx = 0; pIdx < c.pages.length; pIdx++) {
        items.add(PageItem(c.chapter, c.pages[pIdx], pIdx));
      }
      if (c.isLoading) {
        items.add(LoadingItem(c.chapter));
      } else if (c.error != null) {
        items.add(ErrorItem(c.chapter, c.error));
      }
    }

    items.add(FooterItem(isEndOfManga: !hasNextChapter));
    return items;
  }

  int indexForTarget(
    String chapterUrl,
    int pageIndex,
    List<ContinuousItem> items,
  ) {
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (pageIndex == 0 &&
          item is HeaderItem &&
          item.chapter.url == chapterUrl) {
        return i;
      }
      if (item is PageItem &&
          item.chapter.url == chapterUrl &&
          item.pageIndex == pageIndex) {
        return i;
      }
    }
    return -1;
  }

  String resolveChapterUrl(
    String candidateChapterUrl,
    List<ContinuousItem> items,
  ) {
    return items.any(
          (it) => it is PageItem && it.chapter.url == candidateChapterUrl,
        )
        ? candidateChapterUrl
        : (items.whereType<PageItem>().firstOrNull?.chapter.url ?? '');
  }
}
