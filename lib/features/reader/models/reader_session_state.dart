import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_page.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';

class ReaderSessionArgs {
  const ReaderSessionArgs({
    required this.service,
    required this.chapter,
    required this.chapters,
    this.libraryEntryId,
  });

  final ExtensionService service;
  final MChapter chapter;
  final List<MChapter> chapters;
  final int? libraryEntryId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReaderSessionArgs &&
          runtimeType == other.runtimeType &&
          chapter.url == other.chapter.url &&
          libraryEntryId == other.libraryEntryId;

  @override
  int get hashCode => chapter.url.hashCode ^ (libraryEntryId?.hashCode ?? 0);
}

class ContinuousChapter {
  const ContinuousChapter({
    required this.chapter,
    this.pages = const [],
    this.isLoading = false,
    this.error,
  });

  final MChapter chapter;
  final List<MPage> pages;
  final bool isLoading;
  final AppFailure? error;

  ContinuousChapter copyWith({
    MChapter? chapter,
    List<MPage>? pages,
    bool? isLoading,
    AppFailure? error,
    bool clearError = false,
  }) {
    return ContinuousChapter(
      chapter: chapter ?? this.chapter,
      pages: pages ?? this.pages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ReaderSessionState {
  const ReaderSessionState({
    required this.currentChapter,
    required this.chapters,
    required this.chapterIndex,
    this.pages,
    this.continuousChapters = const [],
    this.isLoading = true,
    this.error,
    this.currentPageIndex = 0,
    this.overlaysVisible = false,
    required this.mode,
    required this.scaleType,
    required this.background,
    required this.pageGap,
    required this.dualPageMode,
    required this.invertTaps,
    required this.isEntryOverride,
    required this.columnWidth,
    this.imageQuality = ReaderImageQuality.balanced,
    this.novelFontFamily = ReaderFontFamily.systemDefault,
    this.novelFontSize = 18,
    this.novelLineHeight = 1.5,
    this.novelParagraphSpacing = 12,
    this.lockedAttemptChapter,
  });

  final MChapter currentChapter;
  final List<MChapter> chapters;
  final int chapterIndex;
  final List<MPage>? pages;
  final List<ContinuousChapter> continuousChapters;
  final bool isLoading;
  final AppFailure? error;
  final int currentPageIndex;
  final bool overlaysVisible;

  final ReaderMode mode;
  final ReaderScaleType scaleType;
  final ReaderBackground background;
  final ReaderPageGap pageGap;
  final ReaderDualPageMode dualPageMode;
  final bool invertTaps;
  final bool isEntryOverride;
  final ReaderColumnWidth columnWidth;
  final ReaderImageQuality imageQuality;
  final ReaderFontFamily novelFontFamily;
  final double novelFontSize;
  final double novelLineHeight;
  final double novelParagraphSpacing;
  final MChapter? lockedAttemptChapter;

  bool get hasPreviousChapter => chapterIndex > 0;
  bool get hasNextChapter => chapterIndex < chapters.length - 1;

  ReaderSessionState copyWith({
    MChapter? currentChapter,
    List<MChapter>? chapters,
    int? chapterIndex,
    List<MPage>? pages,
    List<ContinuousChapter>? continuousChapters,
    bool? isLoading,
    AppFailure? error,
    bool clearError = false,
    int? currentPageIndex,
    bool? overlaysVisible,
    ReaderMode? mode,
    ReaderScaleType? scaleType,
    ReaderBackground? background,
    ReaderPageGap? pageGap,
    ReaderDualPageMode? dualPageMode,
    bool? invertTaps,
    bool? isEntryOverride,
    ReaderColumnWidth? columnWidth,
    ReaderImageQuality? imageQuality,
    ReaderFontFamily? novelFontFamily,
    double? novelFontSize,
    double? novelLineHeight,
    double? novelParagraphSpacing,
    MChapter? lockedAttemptChapter,
    bool clearLockedAttempt = false,
  }) {
    return ReaderSessionState(
      currentChapter: currentChapter ?? this.currentChapter,
      chapters: chapters ?? this.chapters,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      pages: pages ?? this.pages,
      continuousChapters: continuousChapters ?? this.continuousChapters,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      overlaysVisible: overlaysVisible ?? this.overlaysVisible,
      mode: mode ?? this.mode,
      scaleType: scaleType ?? this.scaleType,
      background: background ?? this.background,
      pageGap: pageGap ?? this.pageGap,
      dualPageMode: dualPageMode ?? this.dualPageMode,
      invertTaps: invertTaps ?? this.invertTaps,
      isEntryOverride: isEntryOverride ?? this.isEntryOverride,
      columnWidth: columnWidth ?? this.columnWidth,
      imageQuality: imageQuality ?? this.imageQuality,
      novelFontFamily: novelFontFamily ?? this.novelFontFamily,
      novelFontSize: novelFontSize ?? this.novelFontSize,
      novelLineHeight: novelLineHeight ?? this.novelLineHeight,
      novelParagraphSpacing:
          novelParagraphSpacing ?? this.novelParagraphSpacing,
      lockedAttemptChapter: clearLockedAttempt
          ? null
          : (lockedAttemptChapter ?? this.lockedAttemptChapter),
    );
  }
}
