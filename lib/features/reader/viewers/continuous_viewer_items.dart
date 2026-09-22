import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_page.dart';

sealed class ContinuousItem {}

class TopItem extends ContinuousItem {
  TopItem({
    required this.hasPreviousChapter,
    required this.isLoading,
    this.error,
    this.prevChapter,
  });
  final bool hasPreviousChapter;
  final bool isLoading;
  final AppFailure? error;
  final MChapter? prevChapter;
}

class HeaderItem extends ContinuousItem {
  HeaderItem(this.chapter);
  final MChapter chapter;
}

class PageItem extends ContinuousItem {
  PageItem(this.chapter, this.page, this.pageIndex);
  final MChapter chapter;
  final MPage page;
  final int pageIndex;
}

class LoadingItem extends ContinuousItem {
  LoadingItem(this.chapter);
  final MChapter chapter;
}

class ErrorItem extends ContinuousItem {
  ErrorItem(this.chapter, this.error);
  final MChapter chapter;
  final AppFailure? error;
}

class FooterItem extends ContinuousItem {
  FooterItem({required this.isEndOfManga});
  final bool isEndOfManga;
}
