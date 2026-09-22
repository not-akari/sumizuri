import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/core/utils/formatting/chapter_number.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/library/data/library_repository.dart';
import 'package:sumizuri/features/library/models/series_overrides.dart';
import 'package:sumizuri/features/settings/registry/setting_def.dart';
import 'package:sumizuri/features/reader/models/chapter_lock_checker.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/library/flows/auto_download_gate.dart';
import 'package:sumizuri/features/library/flows/chapter_download_flow.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/reader/data/reader_local_loader.dart';
import 'package:sumizuri/features/reader/data/reader_mode_autodetect.dart';
import 'package:sumizuri/features/reader/models/reader_session_state.dart';

export 'package:sumizuri/features/reader/models/reader_session_state.dart';

part 'reader_providers.g.dart';

@riverpod
class ReaderController extends _$ReaderController {
  ReaderSessionState? _lastState;
  late final LibraryRepository _libraryRepository;

  // What this series keeps for itself. A setting missing here follows the app-wide one.
  SeriesOverrides _overrides = const SeriesOverrides();

  /// Settings a series can keep for itself while reading, apart from mode and two-page.
  static const _seriesDefs = <SettingDef<Object?>>[
    Settings.readerScaleType,
    Settings.readerBackground,
    Settings.readerPageGap,
    Settings.readerInvertTaps,
    Settings.readerColumnWidth,
    Settings.readerImageQuality,
    Settings.novelFontFamily,
    Settings.novelFontSize,
    Settings.novelLineHeight,
    Settings.novelParagraphSpacing,
  ];

  ReaderSessionState _withOverrides(ReaderSessionState s) => s.copyWith(
    scaleType: _overrides.resolve(Settings.readerScaleType, s.scaleType),
    background: _overrides.resolve(Settings.readerBackground, s.background),
    pageGap: _overrides.resolve(Settings.readerPageGap, s.pageGap),
    invertTaps: _overrides.resolve(Settings.readerInvertTaps, s.invertTaps),
    columnWidth: _overrides.resolve(Settings.readerColumnWidth, s.columnWidth),
    imageQuality: _overrides.resolve(
      Settings.readerImageQuality,
      s.imageQuality,
    ),
    novelFontFamily: _overrides.resolve(
      Settings.novelFontFamily,
      s.novelFontFamily,
    ),
    novelFontSize: _overrides.resolve(Settings.novelFontSize, s.novelFontSize),
    novelLineHeight: _overrides.resolve(
      Settings.novelLineHeight,
      s.novelLineHeight,
    ),
    novelParagraphSpacing: _overrides.resolve(
      Settings.novelParagraphSpacing,
      s.novelParagraphSpacing,
    ),
  );

  bool _incognito = false;
  int _keepDownloadsBehind = -1;

  @override
  set state(ReaderSessionState value) {
    _lastState = value;
    super.state = value;
  }

  @override
  ReaderSessionState build(ReaderSessionArgs args) {
    final sortedChapters = sortChapters(args.chapters, ascending: true);
    final initialIndex = sortedChapters.indexWhere(
      (c) => c.url == args.chapter.url,
    );
    final validIndex = initialIndex >= 0 ? initialIndex : 0;

    final globalMode =
        ref.read(globalReaderModeProvider).value ?? ReaderMode.rightToLeft;
    final globalScale =
        ref.read(globalReaderScaleTypeProvider).value ??
        ReaderScaleType.fitWidth;
    final globalBg =
        ref.read(globalReaderBackgroundProvider).value ??
        ReaderBackground.black;
    final globalGap =
        ref.read(globalReaderPageGapProvider).value ?? ReaderPageGap.none;
    final globalDual =
        ref.read(globalReaderDualPageModeProvider).value ??
        ReaderDualPageMode.off;
    final globalInvert =
        ref.read(globalReaderInvertTapsProvider).value ?? false;
    final globalColWidth =
        ref.read(globalReaderColumnWidthProvider).value ??
        ReaderColumnWidth.fullWidth;
    final globalImageQuality =
        ref.read(globalReaderImageQualityProvider).value ??
        ReaderImageQuality.balanced;

    ReaderMode effectiveMode = globalMode;
    var effectiveDual = globalDual;
    bool isOverride = false;
    if (args.libraryEntryId != null) {
      final entryId = args.libraryEntryId!;
      final entryOverride = ref.read(entryReaderModeProvider(entryId)).value;
      if (entryOverride != null) {
        effectiveMode = entryOverride;
        isOverride = true;
      }
      effectiveDual =
          ref.read(entryDualPageModeProvider(entryId)).value ?? globalDual;
    }

    final seriesId = args.libraryEntryId;
    _overrides = seriesId == null
        ? const SeriesOverrides()
        : ref.read(entryOverridesProvider(seriesId)).value ??
              const SeriesOverrides();
    final initialState = _withOverrides(
      ReaderSessionState(
        currentChapter: args.chapter,
        chapters: sortedChapters,
        chapterIndex: validIndex,
        mode: effectiveMode,
        scaleType: globalScale,
        background: globalBg,
        pageGap: globalGap,
        dualPageMode: effectiveDual,
        invertTaps: globalInvert,
        isEntryOverride: isOverride,
        columnWidth: globalColWidth,
        imageQuality: globalImageQuality,
        novelFontFamily:
            ref.read(novelFontFamilyProvider).value ??
            ReaderFontFamily.systemDefault,
        novelFontSize: ref.read(novelFontSizeProvider).value ?? 18,
        novelLineHeight: ref.read(novelLineHeightProvider).value ?? 1.5,
        novelParagraphSpacing:
            ref.read(novelParagraphSpacingProvider).value ?? 12,
      ),
    );
    _lastState = initialState;

    _libraryRepository = ref.read(libraryRepositoryProvider);
    unawaited(
      ref.read(settingsRepositoryProvider).watchIncognito().first.then((v) {
        _incognito = v;
      }),
    );
    ref.listen(incognitoModeProvider, (previous, next) {
      _incognito = next.value ?? false;
    });
    _keepDownloadsBehind = ref.read(keepDownloadsBehindProvider).value ?? -1;
    ref.listen(keepDownloadsBehindProvider, (previous, next) {
      _keepDownloadsBehind = next.value ?? -1;
    });

    Future.microtask(() => _loadChapter(args.chapter));
    unawaited(_resolveInitialSettings());

    ref.onDispose(() {
      _progressDebounceTimer?.cancel();

      final libraryEntryId = _pendingLibraryEntryId;
      final chapterUrl = _pendingChapterUrl;
      final progress = _pendingProgress;
      if (libraryEntryId != null && chapterUrl != null && progress != null) {
        unawaited(
          _libraryRepository.updateChapterProgress(
            libraryEntryId: libraryEntryId,
            chapterUrl: chapterUrl,
            progressPosition: progress,
          ),
        );
      }

      final entryId = args.libraryEntryId;
      final last = _lastState;
      if (entryId != null && last?.pages != null) {
        unawaited(_applyDownloadRetention(entryId, last!.currentChapter.url));
      }
    });

    return initialState;
  }

  Future<void> _resolveInitialSettings() async {
    final settings = ref.read(settingsRepositoryProvider);
    final library = ref.read(libraryRepositoryProvider);
    final seriesId = args.libraryEntryId;
    Future<T> global<T>(SettingDef<T> def) => settings.watchSetting(def).first;

    final globalMode = await global(Settings.readerMode);
    final globalDual = await global(Settings.readerDualPageMode);
    final scale = await global(Settings.readerScaleType);
    final bg = await global(Settings.readerBackground);
    final gap = await global(Settings.readerPageGap);
    final invert = await global(Settings.readerInvertTaps);
    final colWidth = await global(Settings.readerColumnWidth);
    final imageQuality = await global(Settings.readerImageQuality);
    final novelFamily = await global(Settings.novelFontFamily);
    final novelSize = await global(Settings.novelFontSize);
    final novelLine = await global(Settings.novelLineHeight);
    final novelSpacing = await global(Settings.novelParagraphSpacing);
    final keepBehind = await global(Settings.keepDownloadsBehind);
    final entryMode = seriesId == null
        ? null
        : await library.watchEntryReaderMode(seriesId).first;
    final entryDual = seriesId == null
        ? null
        : await library.watchEntryDualPageMode(seriesId).first;
    final overrides = seriesId == null
        ? const SeriesOverrides()
        : await library.watchEntryOverrides(seriesId).first;
    if (!ref.mounted) return;

    _overrides = overrides;
    _keepDownloadsBehind = overrides.resolve(
      Settings.keepDownloadsBehind,
      keepBehind,
    );
    state = _withOverrides(
      state.copyWith(
        mode: entryMode ?? globalMode,
        scaleType: scale,
        background: bg,
        pageGap: gap,
        dualPageMode: entryDual ?? globalDual,
        invertTaps: invert,
        columnWidth: colWidth,
        imageQuality: imageQuality,
        novelFontFamily: novelFamily,
        novelFontSize: novelSize,
        novelLineHeight: novelLine,
        novelParagraphSpacing: novelSpacing,
        isEntryOverride: entryMode != null,
      ),
    );
  }

  Timer? _progressDebounceTimer;

  bool _downloadingAhead = false;

  // Fetches the next few chapters in the background so they open without waiting.
  Future<void> _downloadAhead(int libraryEntryId, MChapter current) async {
    if (_downloadingAhead) return;
    final container = ref.container;
    final globalCount = await container
        .read(settingsRepositoryProvider)
        .watchSetting(Settings.downloadAheadCount)
        .first;
    final count = _overrides.resolve(Settings.downloadAheadCount, globalCount);
    if (count <= 0 || !ref.mounted || !await canAutoDownloadNow(container)) {
      return;
    }
    final index = state.chapters.indexWhere((c) => c.url == current.url);
    if (index < 0) return;

    _downloadingAhead = true;
    try {
      final downloading = container.read(downloadingChaptersProvider);
      final needed = <MChapter>[];
      for (final chapter in state.chapters.skip(index + 1).take(count)) {
        if (isChapterLocked(chapter)) break;
        if (downloading.contains(downloadKey(libraryEntryId, chapter.url))) {
          continue;
        }
        final path = await _libraryRepository
            .watchChapterLocalPath(
              libraryEntryId: libraryEntryId,
              chapterUrl: chapter.url,
            )
            .first;
        if (path == null) needed.add(chapter);
      }
      final title = await _libraryRepository.entryTitle(libraryEntryId);
      if (needed.isEmpty || title == null) return;
      await downloadAllChapters(
        container: container,
        service: args.service,
        libraryEntryId: libraryEntryId,
        sourceId: args.service.info.id,
        entryTitle: title,
        chapters: needed,
      );
    } finally {
      _downloadingAhead = false;
    }
  }

  Future<void> _applyDownloadRetention(
    int libraryEntryId,
    String referenceChapterUrl,
  ) async {
    final keepBehind = _keepDownloadsBehind;
    if (keepBehind < 0) return;

    final repository = _libraryRepository;
    final chapters = (await repository.getAllChapters(libraryEntryId))
        .valueOrNull;
    if (chapters == null) return;

    final referenceIndex = chapters.indexWhere(
      (c) => c.url == referenceChapterUrl,
    );
    final targetIndex = referenceIndex - keepBehind - 1;
    if (referenceIndex < 0 || targetIndex < 0) return;

    final targetUrl = chapters[targetIndex].url;
    final localPath = await repository
        .watchChapterLocalPath(
          libraryEntryId: libraryEntryId,
          chapterUrl: targetUrl,
        )
        .first;
    if (localPath == null) return;
    await deleteChapterDownload(
      repository: repository,
      libraryEntryId: libraryEntryId,
      chapterUrl: targetUrl,
      localPath: localPath,
    );
  }

  Future<void> _loadChapter(MChapter chapter) async {
    final libraryEntryId = args.libraryEntryId;

    if (libraryEntryId != null &&
        state.pages != null &&
        state.currentChapter.url != chapter.url) {
      unawaited(_applyDownloadRetention(libraryEntryId, chapter.url));
    }

    state = state.copyWith(isLoading: true, clearError: true, pages: null);

    final targetUrl = chapter.url;
    final localPath = libraryEntryId == null
        ? null
        : await ref
              .read(libraryRepositoryProvider)
              .watchChapterLocalPath(
                libraryEntryId: libraryEntryId,
                chapterUrl: chapter.url,
              )
              .first;
    var result = localPath != null
        ? await loadLocalPages(localPath)
        : await args.service.getPageList(chapter);
    if (localPath != null && (result.valueOrNull?.isEmpty ?? false)) {
      result = await args.service.getPageList(chapter);
    }

    final pages = result.valueOrNull;
    final resumeIndex = pages != null
        ? await resumePageIndex(ref, libraryEntryId, chapter.url, pages.length)
        : 0;

    if (!ref.mounted) return;

    if (state.currentChapter.url != targetUrl) return;

    result.when(
      ok: (pages) {
        if (libraryEntryId != null) {
          _markCompleteIfLastPage(
            libraryEntryId,
            chapter.url,
            resumeIndex,
            pages.length,
          );
        }
        state = state.copyWith(
          currentChapter: chapter,
          pages: pages,
          continuousChapters: [
            ContinuousChapter(chapter: chapter, pages: pages, isLoading: false),
          ],
          isLoading: false,
          currentPageIndex: resumeIndex,
        );
        if (libraryEntryId != null) {
          unawaited(_downloadAhead(libraryEntryId, chapter));
          unawaited(
            maybeAutoDetectReaderMode(
              ref: ref,
              libraryEntryId: libraryEntryId,
              chapter: chapter,
              pages: pages,
              isOverride: () => state.isEntryOverride,
              isCurrentChapter: () => state.currentChapter.url == chapter.url,
              applyDetectedMode: (mode) {
                state = state.copyWith(mode: mode, isEntryOverride: true);
              },
            ),
          );
        }
      },
      err: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure,
          continuousChapters: [
            ContinuousChapter(
              chapter: chapter,
              isLoading: false,
              error: failure,
            ),
          ],
        );
      },
    );
  }

  bool _isLoadingNextContinuous = false;

  Future<void> loadNextChapterContinuous() async {
    if (_isLoadingNextContinuous) return;
    if (state.continuousChapters.isEmpty) return;

    final lastContinuous = state.continuousChapters.last.chapter;
    final lastIndex = state.chapters.indexWhere(
      (c) => c.url == lastContinuous.url,
    );
    if (lastIndex < 0 || lastIndex >= state.chapters.length - 1) return;

    final nextChapter = state.chapters[lastIndex + 1];
    if (isChapterLocked(nextChapter)) return;

    if (state.continuousChapters.any((c) => c.chapter.url == nextChapter.url)) {
      return;
    }

    _isLoadingNextContinuous = true;
    state = state.copyWith(
      continuousChapters: [
        ...state.continuousChapters,
        ContinuousChapter(chapter: nextChapter, isLoading: true),
      ],
    );

    final libraryEntryId = args.libraryEntryId;
    final localPath = libraryEntryId == null
        ? null
        : await ref
              .read(libraryRepositoryProvider)
              .watchChapterLocalPath(
                libraryEntryId: libraryEntryId,
                chapterUrl: nextChapter.url,
              )
              .first;

    var result = localPath != null
        ? await loadLocalPages(localPath)
        : await args.service.getPageList(nextChapter);
    if (localPath != null && (result.valueOrNull?.isEmpty ?? false)) {
      result = await args.service.getPageList(nextChapter);
    }

    if (!ref.mounted) {
      _isLoadingNextContinuous = false;
      return;
    }

    result.when(
      ok: (pages) {
        final updated = state.continuousChapters.map((c) {
          if (c.chapter.url == nextChapter.url) {
            return c.copyWith(pages: pages, isLoading: false, clearError: true);
          }
          return c;
        }).toList();
        state = state.copyWith(continuousChapters: updated);
      },
      err: (failure) {
        final updated = state.continuousChapters.map((c) {
          if (c.chapter.url == nextChapter.url) {
            return c.copyWith(isLoading: false, error: failure);
          }
          return c;
        }).toList();
        state = state.copyWith(continuousChapters: updated);
      },
    );

    _isLoadingNextContinuous = false;
  }

  bool _isLoadingPreviousContinuous = false;

  Future<void> loadPreviousChapterContinuous() async {
    if (_isLoadingPreviousContinuous) return;
    if (state.continuousChapters.isEmpty) return;

    final firstContinuous = state.continuousChapters.first.chapter;
    final firstIndex = state.chapters.indexWhere(
      (c) => c.url == firstContinuous.url,
    );
    if (firstIndex <= 0) return;

    final prevChapter = state.chapters[firstIndex - 1];
    if (isChapterLocked(prevChapter)) return;

    if (state.continuousChapters.any((c) => c.chapter.url == prevChapter.url)) {
      return;
    }

    _isLoadingPreviousContinuous = true;
    state = state.copyWith(
      continuousChapters: [
        ContinuousChapter(chapter: prevChapter, isLoading: true),
        ...state.continuousChapters,
      ],
    );

    final libraryEntryId = args.libraryEntryId;
    final localPath = libraryEntryId == null
        ? null
        : await ref
              .read(libraryRepositoryProvider)
              .watchChapterLocalPath(
                libraryEntryId: libraryEntryId,
                chapterUrl: prevChapter.url,
              )
              .first;

    var result = localPath != null
        ? await loadLocalPages(localPath)
        : await args.service.getPageList(prevChapter);
    if (localPath != null && (result.valueOrNull?.isEmpty ?? false)) {
      result = await args.service.getPageList(prevChapter);
    }

    if (!ref.mounted) {
      _isLoadingPreviousContinuous = false;
      return;
    }

    result.when(
      ok: (pages) {
        final updated = state.continuousChapters.map((c) {
          if (c.chapter.url == prevChapter.url) {
            return c.copyWith(pages: pages, isLoading: false, clearError: true);
          }
          return c;
        }).toList();
        state = state.copyWith(continuousChapters: updated);
      },
      err: (failure) {
        final updated = state.continuousChapters.map((c) {
          if (c.chapter.url == prevChapter.url) {
            return c.copyWith(isLoading: false, error: failure);
          }
          return c;
        }).toList();
        state = state.copyWith(continuousChapters: updated);
      },
    );

    _isLoadingPreviousContinuous = false;
  }

  void setActiveChapter(MChapter chapter, int pageIndex) {
    if (state.currentChapter.url != chapter.url) {
      final newIdx = state.chapters.indexWhere((c) => c.url == chapter.url);
      final validIdx = newIdx >= 0 ? newIdx : state.chapterIndex;

      final libraryEntryId = args.libraryEntryId;
      if (libraryEntryId != null) {
        // Only mark previous chapter consumed when moving forward, and never while incognito.
        if (validIdx > state.chapterIndex && !_incognito) {
          unawaited(
            ref
                .read(libraryRepositoryProvider)
                .markChapterConsumed(
                  libraryEntryId: libraryEntryId,
                  chapterUrl: state.currentChapter.url,
                ),
          );
        }
        unawaited(_applyDownloadRetention(libraryEntryId, chapter.url));
      }

      final chapterData = state.continuousChapters.firstWhere(
        (c) => c.chapter.url == chapter.url,
        orElse: () => ContinuousChapter(chapter: chapter),
      );

      state = state.copyWith(
        currentChapter: chapter,
        chapterIndex: validIdx,
        pages: chapterData.pages.isNotEmpty ? chapterData.pages : state.pages,
        currentPageIndex: pageIndex,
      );

      _updateProgressForChapter(chapter, pageIndex, chapterData.pages.length);
    } else {
      setPageIndex(pageIndex);
    }
  }

  void _updateProgressForChapter(MChapter chapter, int index, int total) {
    final libraryEntryId = _incognito ? null : args.libraryEntryId;
    if (libraryEntryId == null) return;
    final progress = (index + 1) / (total > 0 ? total : 1);
    _pendingLibraryEntryId = libraryEntryId;
    _pendingChapterUrl = chapter.url;
    _pendingProgress = progress;
    _progressDebounceTimer?.cancel();
    _progressDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _pendingLibraryEntryId = null;
      unawaited(
        ref
            .read(libraryRepositoryProvider)
            .updateChapterProgress(
              libraryEntryId: libraryEntryId,
              chapterUrl: chapter.url,
              progressPosition: progress,
            ),
      );
    });
    _markCompleteIfLastPage(libraryEntryId, chapter.url, index, total);
  }

  void toggleOverlays() {
    state = state.copyWith(overlaysVisible: !state.overlaysVisible);
  }

  int? _pendingLibraryEntryId;
  String? _pendingChapterUrl;
  double? _pendingProgress;

  void setPageIndex(int index) {
    if (state.currentPageIndex != index) {
      state = state.copyWith(currentPageIndex: index);
      final libraryEntryId = _incognito ? null : args.libraryEntryId;
      if (libraryEntryId != null) {
        final chapterUrl = state.currentChapter.url;
        final total = state.pages?.length ?? 1;
        final progress = (index + 1) / (total > 0 ? total : 1);
        _pendingLibraryEntryId = libraryEntryId;
        _pendingChapterUrl = chapterUrl;
        _pendingProgress = progress;
        _progressDebounceTimer?.cancel();
        _progressDebounceTimer = Timer(const Duration(milliseconds: 300), () {
          _pendingLibraryEntryId = null;
          unawaited(
            ref
                .read(libraryRepositoryProvider)
                .updateChapterProgress(
                  libraryEntryId: libraryEntryId,
                  chapterUrl: chapterUrl,
                  progressPosition: progress,
                ),
          );
        });
        _markCompleteIfLastPage(libraryEntryId, chapterUrl, index, total);
      }
    }
  }

  void _markCompleteIfLastPage(
    int libraryEntryId,
    String chapterUrl,
    int index,
    int total,
  ) {
    if (total <= 0 || index < total - 1) return;
    unawaited(
      ref
          .read(libraryRepositoryProvider)
          .markChapterConsumed(
            libraryEntryId: libraryEntryId,
            chapterUrl: chapterUrl,
          ),
    );
  }

  bool nextChapter() {
    if (!state.hasNextChapter) return false;
    final nextChapter = state.chapters[state.chapterIndex + 1];

    if (isChapterLocked(nextChapter)) {
      state = state.copyWith(lockedAttemptChapter: nextChapter);
      return false;
    }

    state = state.copyWith(
      chapterIndex: state.chapterIndex + 1,
      currentChapter: nextChapter,
    );
    _loadChapter(nextChapter);
    return true;
  }

  bool previousChapter() {
    if (!state.hasPreviousChapter) return false;
    final prevChapter = state.chapters[state.chapterIndex - 1];

    if (isChapterLocked(prevChapter)) {
      state = state.copyWith(lockedAttemptChapter: prevChapter);
      return false;
    }

    state = state.copyWith(
      chapterIndex: state.chapterIndex - 1,
      currentChapter: prevChapter,
    );
    _loadChapter(prevChapter);
    return true;
  }

  void clearLockedAttempt() {
    state = state.copyWith(clearLockedAttempt: true);
  }

  /// Saves a setting for this series when it has its own settings, else for the whole app.
  void _change<T>(
    SettingDef<T> def,
    T value,
    ReaderSessionState Function(ReaderSessionState state) apply,
  ) {
    state = apply(state);
    final seriesId = args.libraryEntryId;
    if (seriesId != null && state.isEntryOverride) {
      _overrides = _overrides.set(def, value);
      unawaited(
        ref
            .read(libraryRepositoryProvider)
            .updateEntryOverrides(entryId: seriesId, overrides: _overrides),
      );
    } else {
      unawaited(ref.read(settingsRepositoryProvider).putSetting(def, value));
    }
  }

  void setReaderMode(ReaderMode mode) {
    state = state.copyWith(mode: mode);
    final seriesId = args.libraryEntryId;
    if (seriesId != null && state.isEntryOverride) {
      unawaited(
        ref
            .read(libraryRepositoryProvider)
            .updateEntryReaderMode(entryId: seriesId, readerMode: mode),
      );
    } else {
      unawaited(ref.read(settingsRepositoryProvider).setReaderMode(mode));
    }
  }

  void setDualPageMode(ReaderDualPageMode mode) {
    state = state.copyWith(dualPageMode: mode);
    final seriesId = args.libraryEntryId;
    if (seriesId != null && state.isEntryOverride) {
      unawaited(
        ref
            .read(libraryRepositoryProvider)
            .updateEntryDualPageMode(entryId: seriesId, mode: mode),
      );
    } else {
      unawaited(
        ref.read(settingsRepositoryProvider).setReaderDualPageMode(mode),
      );
    }
  }

  /// Turns the series' own settings on or off, keeping the current ones when turned on.
  void toggleEntryOverride(bool isOverride) {
    state = state.copyWith(isEntryOverride: isOverride);
    final seriesId = args.libraryEntryId;
    if (seriesId == null) return;
    final library = ref.read(libraryRepositoryProvider);
    if (isOverride) {
      _overrides = _overrides
          .set(Settings.readerScaleType, state.scaleType)
          .set(Settings.readerBackground, state.background)
          .set(Settings.readerPageGap, state.pageGap)
          .set(Settings.readerInvertTaps, state.invertTaps)
          .set(Settings.readerColumnWidth, state.columnWidth)
          .set(Settings.readerImageQuality, state.imageQuality)
          .set(Settings.novelFontFamily, state.novelFontFamily)
          .set(Settings.novelFontSize, state.novelFontSize)
          .set(Settings.novelLineHeight, state.novelLineHeight)
          .set(Settings.novelParagraphSpacing, state.novelParagraphSpacing);
    } else {
      _overrides = _overrides.without(_seriesDefs);
    }
    unawaited(
      library.updateEntryOverrides(entryId: seriesId, overrides: _overrides),
    );
    unawaited(
      library.updateEntryReaderMode(
        entryId: seriesId,
        readerMode: isOverride ? state.mode : null,
      ),
    );
    unawaited(
      library.updateEntryDualPageMode(
        entryId: seriesId,
        mode: isOverride ? state.dualPageMode : null,
      ),
    );
    if (!isOverride) unawaited(_resolveInitialSettings());
  }

  void setScaleType(ReaderScaleType v) =>
      _change(Settings.readerScaleType, v, (s) => s.copyWith(scaleType: v));

  void setBackground(ReaderBackground v) =>
      _change(Settings.readerBackground, v, (s) => s.copyWith(background: v));

  void setPageGap(ReaderPageGap v) =>
      _change(Settings.readerPageGap, v, (s) => s.copyWith(pageGap: v));

  void setInvertTaps(bool v) =>
      _change(Settings.readerInvertTaps, v, (s) => s.copyWith(invertTaps: v));

  void setColumnWidth(ReaderColumnWidth v) =>
      _change(Settings.readerColumnWidth, v, (s) => s.copyWith(columnWidth: v));

  void setNovelFontFamily(ReaderFontFamily v) => _change(
    Settings.novelFontFamily,
    v,
    (s) => s.copyWith(novelFontFamily: v),
  );

  void setNovelFontSize(double v) =>
      _change(Settings.novelFontSize, v, (s) => s.copyWith(novelFontSize: v));

  void setNovelLineHeight(double v) => _change(
    Settings.novelLineHeight,
    v,
    (s) => s.copyWith(novelLineHeight: v),
  );

  void setNovelParagraphSpacing(double v) => _change(
    Settings.novelParagraphSpacing,
    v,
    (s) => s.copyWith(novelParagraphSpacing: v),
  );
}

@riverpod
Stream<ReaderMode?> entryReaderMode(Ref ref, int entryId) {
  return ref.watch(libraryRepositoryProvider).watchEntryReaderMode(entryId);
}

@riverpod
Stream<ReaderDualPageMode?> entryDualPageMode(Ref ref, int entryId) {
  return ref.watch(libraryRepositoryProvider).watchEntryDualPageMode(entryId);
}

@riverpod
Stream<SeriesOverrides> entryOverrides(Ref ref, int entryId) {
  return ref.watch(libraryRepositoryProvider).watchEntryOverrides(entryId);
}
