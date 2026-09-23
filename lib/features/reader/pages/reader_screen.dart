import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/gestures.dart' show PointerScrollEvent;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:sumizuri/features/reader/widgets/screen_filter.dart';
import 'package:sumizuri/core/platform/volume_keys.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/reader/models/chapter_web_address.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/feedback/error_view.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_page.dart';
import 'package:sumizuri/features/reader/models/reader_controls.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/reader/providers/reader_providers.dart';
import 'package:sumizuri/features/reader/viewers/continuous_vertical_viewer.dart';
import 'package:sumizuri/features/reader/viewers/novel_continuous_viewer.dart';
import 'package:sumizuri/features/reader/viewers/novel_paged_viewer.dart';
import 'package:sumizuri/features/reader/viewers/paged_viewer.dart';
import 'package:sumizuri/features/reader/widgets/chapter_locked_dialog.dart';
import 'package:sumizuri/features/reader/widgets/reader_overlay.dart';
import 'package:sumizuri/features/reader/widgets/reader_page_image.dart';
import 'package:sumizuri/features/reader/widgets/reader_settings_sheet.dart';

part 'reader_input.dart';

bool _isNovelText(List<MPage> pages) =>
    pages.isNotEmpty && pages.first.text != null;

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.service,
    required this.chapter,
    required this.chapters,
    this.libraryEntryId,
    this.hasChapterComments = false,
    this.onChapterComments,
  });

  final ExtensionService service;
  final MChapter chapter;
  final List<MChapter> chapters;
  final int? libraryEntryId;
  final bool hasChapterComments;
  final void Function(MChapter chapter)? onChapterComments;

  static Future<void> push(
    BuildContext context, {
    required ExtensionService service,
    required MChapter chapter,
    required List<MChapter> chapters,
    int? libraryEntryId,
    bool hasChapterComments = false,
    void Function(MChapter chapter)? onChapterComments,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          service: service,
          chapter: chapter,
          chapters: chapters,
          libraryEntryId: libraryEntryId,
          hasChapterComments: hasChapterComments,
          onChapterComments: onChapterComments,
        ),
      ),
    );
  }

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with SingleTickerProviderStateMixin, _ReaderInput {
  late final ReaderSessionArgs _args;
  @override
  final GlobalKey<ContinuousVerticalViewerState> _continuousKey = GlobalKey();
  @override
  final GlobalKey<PagedViewerState> _pagedKey = GlobalKey();
  @override
  final GlobalKey<NovelPagedViewerState> _novelPagedKey = GlobalKey();
  @override
  final GlobalKey<NovelContinuousViewerState> _novelContinuousKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();

  @override
  late final Ticker _ticker = createTicker(_onTick);
  @override
  Duration _lastTick = Duration.zero;
  @override
  bool _autoScroll = false;
  @override
  int _glide = 0;
  @override
  LogicalKeyboardKey? _glideKey;
  @override
  ReaderControls _controls = ReaderControls.defaults;
  @override
  bool _scrollable = false;
  @override
  bool _novelScroll = false;
  ReaderSessionState? _state;
  ReaderController? _notifier;
  bool _isNovelBook = false;
  StreamSubscription<bool>? _volumeSub;

  @override
  void initState() {
    super.initState();
    _args = ReaderSessionArgs(
      service: widget.service,
      chapter: widget.chapter,
      chapters: widget.chapters,
      libraryEntryId: widget.libraryEntryId,
    );
    ref.listenManual(readerKeepScreenOnProvider, (previous, next) {
      _keepScreenOn(next.value ?? true);
    }, fireImmediately: true);
    ref.listenManual(readerVolumeKeysProvider, (previous, next) {
      _claimVolumeKeys(next.value ?? false);
    }, fireImmediately: true);
    ref.listenManual(boolSettingProvider(Settings.readerHideSystemBars), (
      previous,
      next,
    ) {
      _hideSystemBars(next.value ?? true);
    }, fireImmediately: true);
  }

  void _hideSystemBars(bool hide) {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        hide ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_volumeSub?.cancel());
    unawaited(VolumeKeys.instance.setIntercept(false));
    _keepScreenOn(false);
    _hideSystemBars(false);
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _keepScreenOn(bool on) {
    try {
      unawaited(on ? WakelockPlus.enable() : WakelockPlus.disable());
    } on Object {
      // A platform without wake locks: nothing to do.
    }
  }

  // The volume buttons turn pages while the reader is open, if the setting is on (Android).
  void _claimVolumeKeys(bool on) {
    if (!VolumeKeys.supported) return;
    unawaited(_volumeSub?.cancel());
    _volumeSub = null;
    if (on) _volumeSub = VolumeKeys.instance.presses.listen(_onVolumeKey);
    unawaited(VolumeKeys.instance.setIntercept(on));
  }

  void _onVolumeKey(bool up) {
    final state = _state;
    final notifier = _notifier;
    if (state == null || notifier == null || !mounted) return;
    _perform(
      up ? ReaderAction.previousPage : ReaderAction.nextPage,
      state,
      notifier,
      fromTap: false,
      controls: _controls,
      isContinuous: _scrollable,
      isNovelBook: _isNovelBook,
      isNovelContinuous: _novelScroll,
    );
  }

  @override
  Future<void> _toggleBookmark(MChapter chapter) async {
    final entryId = widget.libraryEntryId;
    if (entryId == null) return;
    final library = ref.read(libraryRepositoryProvider);
    final now = await library
        .watchChapterBookmarked(
          libraryEntryId: entryId,
          chapterUrl: chapter.url,
        )
        .first;
    await library.setChaptersBookmarked(
      libraryEntryId: entryId,
      chapterUrls: [chapter.url],
      bookmarked: !now,
    );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 900),
          content: Text(
            now ? l10n.readerBookmarkRemoved : l10n.readerBookmarkAdded,
          ),
        ),
      );
  }

  Uri? _chapterAddress(MChapter chapter) {
    final id = int.tryParse(widget.service.info.id);
    final sources = ref.read(installedSourcesProvider).value ?? const [];
    String? base;
    for (final source in sources) {
      if (source.id == id) base = source.baseUrl;
    }
    return chapterWebAddress(chapter.webUrl ?? chapter.url, base);
  }

  @override
  void _openInBrowser(MChapter chapter) {
    final uri = _chapterAddress(chapter);
    if (uri == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.readerOpenInBrowserFailed,
            ),
          ),
        );
      return;
    }
    unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
  }

  @override
  void _openSettings() {
    final pages = ref.read(readerControllerProvider(_args)).pages ?? const [];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ReaderSettingsSheet(args: _args, isNovelText: _isNovelText(pages)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerControllerProvider(_args));
    final notifier = ref.read(readerControllerProvider(_args).notifier);

    ref.listen(readerControllerProvider(_args), (previous, next) {
      if (next.lockedAttemptChapter != null) {
        final locked = next.lockedAttemptChapter!;
        notifier.clearLockedAttempt();
        showChapterLockedDialog(context, locked);
      }
    });

    final controls =
        ref.watch(readerControlsProvider).value ?? ReaderControls.defaults;
    final bgColor = backgroundColorFor(state.background, context);
    _controls = controls;
    final pages = state.pages ?? const [];
    final isNovelText = _isNovelText(pages);
    final isNovelContinuous =
        isNovelText && state.mode == ReaderMode.continuousVertical;
    final isNovelBook = isNovelText && !isNovelContinuous;
    final isContinuous =
        isNovelContinuous ||
        (!isNovelText && state.mode == ReaderMode.continuousVertical);
    _scrollable = isContinuous;
    _novelScroll = isNovelContinuous;
    _state = state;
    _notifier = notifier;
    _isNovelBook = isNovelBook;
    // A reader that cannot scroll continuously has nothing to auto scroll or glide.
    if (!isContinuous && (_autoScroll || _glide != 0)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _stopGlide();
        _setAutoScroll(false);
      });
    }

    return ProviderScope(
      overrides: _novelOverridesFor(state),
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, e) =>
            _onKeyEvent(
              e,
              state,
              notifier,
              controls,
              isContinuous: isContinuous,
              isNovelBook: isNovelBook,
              isNovelContinuous: isNovelContinuous,
            )
            ? KeyEventResult.handled
            : KeyEventResult.ignored,
        child: Stack(
          children: [
            Positioned.fill(
              child: Scaffold(
                backgroundColor: bgColor,
                body: Stack(
                  children: [
                    Positioned.fill(
                      child: Listener(
                        onPointerSignal: (event) {
                          if (event is PointerScrollEvent) {
                            _setAutoScroll(false);
                          }
                        },
                        child: NotificationListener<UserScrollNotification>(
                          onNotification: (n) {
                            if (n.direction != ScrollDirection.idle) {
                              _setAutoScroll(false);
                            }
                            return false;
                          },
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) => _onTapZone(
                              details,
                              state,
                              notifier,
                              controls,
                              isContinuous: isContinuous,
                              isNovelBook: isNovelBook,
                              isNovelContinuous: isNovelContinuous,
                            ),
                            child: Builder(
                              builder: (context) {
                                if (state.isLoading) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (state.error != null) {
                                  return ErrorView(
                                    message: state.error!.displayMessage,
                                  );
                                }
                                if (pages.isEmpty) {
                                  return Center(
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .readerNoPagesFound,
                                    ),
                                  );
                                }

                                if (isNovelBook) {
                                  return NovelPagedViewer(
                                    key: _novelPagedKey,
                                    pages: pages,
                                    background: state.background,
                                    dualPageMode: state.dualPageMode,
                                    hasPreviousChapter:
                                        state.hasPreviousChapter,
                                    hasNextChapter: state.hasNextChapter,
                                    onPreviousChapter: notifier.previousChapter,
                                    onNextChapter: notifier.nextChapter,
                                    onPageChanged: notifier.setPageIndex,
                                  );
                                }

                                if (isNovelContinuous) {
                                  return NovelContinuousViewer(
                                    key: _novelContinuousKey,
                                    pages: pages,
                                    background: state.background,
                                    columnWidth: state.columnWidth,
                                    hasPreviousChapter:
                                        state.hasPreviousChapter,
                                    hasNextChapter: state.hasNextChapter,
                                    onPreviousChapter: notifier.previousChapter,
                                    onNextChapter: notifier.nextChapter,
                                    onPageChanged: notifier.setPageIndex,
                                  );
                                }

                                if (isContinuous) {
                                  return ContinuousVerticalViewer(
                                    key: _continuousKey,
                                    pages: pages,
                                    continuousChapters:
                                        state.continuousChapters,
                                    currentChapter: state.currentChapter,
                                    scaleType: state.scaleType,
                                    background: state.background,
                                    pageGap: state.pageGap,
                                    columnWidth: state.columnWidth,
                                    initialPage: state.currentPageIndex,
                                    hasPreviousChapter:
                                        state.hasPreviousChapter,
                                    hasNextChapter: state.hasNextChapter,
                                    onPreviousChapter: () {
                                      final handled =
                                          _continuousKey.currentState
                                              ?.scrollToPreviousChapter() ??
                                          false;
                                      if (!handled) notifier.previousChapter();
                                    },
                                    onNextChapter: () {
                                      final handled =
                                          _continuousKey.currentState
                                              ?.scrollToNextChapter() ??
                                          false;
                                      if (!handled) notifier.nextChapter();
                                    },
                                    onLoadNextChapter:
                                        notifier.loadNextChapterContinuous,
                                    onLoadPreviousChapter:
                                        notifier.loadPreviousChapterContinuous,
                                    onActiveChapterChanged:
                                        notifier.setActiveChapter,
                                    onPageChanged: notifier.setPageIndex,
                                    imageQuality: state.imageQuality,
                                    headers: widget.service.defaultHeaders,
                                  );
                                }

                                return PagedViewer(
                                  key: _pagedKey,
                                  pages: pages,
                                  mode: state.mode,
                                  scaleType: state.scaleType,
                                  background: state.background,
                                  dualPageMode: state.dualPageMode,
                                  initialPage: state.currentPageIndex,
                                  onPageChanged: notifier.setPageIndex,
                                  imageQuality: state.imageQuality,
                                  headers: widget.service.defaultHeaders,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    ReaderTopBar(
                      title: state.currentChapter.title,
                      visible: state.overlaysVisible,
                      hasComments:
                          widget.hasChapterComments &&
                          widget.onChapterComments != null,
                      onBack: () => Navigator.of(context).pop(),
                      onComments: () =>
                          widget.onChapterComments?.call(state.currentChapter),
                      onSettings: _openSettings,
                      bookmarked:
                          ref
                              .watch(
                                chapterBookmarkedProvider(
                                  widget.libraryEntryId ?? -1,
                                  state.currentChapter.url,
                                ),
                              )
                              .value ??
                          false,
                      onToggleBookmark: widget.libraryEntryId == null
                          ? null
                          : () => unawaited(
                              _toggleBookmark(state.currentChapter),
                            ),
                      onOpenInBrowser:
                          _chapterAddress(state.currentChapter) == null
                          ? null
                          : () => _openInBrowser(state.currentChapter),
                      autoScrolling: _autoScroll,
                      incognito:
                          ref.watch(incognitoModeProvider).value ?? false,
                      onToggleAutoScroll: isContinuous
                          ? () => _perform(
                              ReaderAction.toggleAutoScroll,
                              state,
                              notifier,
                              fromTap: false,
                              controls: controls,
                              isContinuous: isContinuous,
                              isNovelBook: isNovelBook,
                              isNovelContinuous: isNovelContinuous,
                            )
                          : null,
                    ),

                    if (!isNovelText &&
                        isContinuous &&
                        (ref.watch(readerVerticalNavigatorProvider).value ??
                            false))
                      ReaderVerticalNavigator(
                        visible: state.overlaysVisible,
                        currentPage: state.currentPageIndex,
                        totalPages: pages.length,
                        onJump: (page) {
                          notifier.setPageIndex(page);
                          _continuousKey.currentState?.jumpToPage(page);
                        },
                      ),

                    if (!isNovelText)
                      ReaderBottomBar(
                        visible: state.overlaysVisible,
                        currentPage: state.currentPageIndex,
                        totalPages: state.pages?.length ?? 0,
                        hasPreviousChapter: state.hasPreviousChapter,
                        hasNextChapter: state.hasNextChapter,
                        onPageChanged: (page) {
                          notifier.setPageIndex(page);
                          if (isContinuous) {
                            _continuousKey.currentState?.jumpToPage(page);
                          } else {
                            _pagedKey.currentState?.jumpToPage(page);
                          }
                        },
                        onPreviousChapter: () {
                          if (isContinuous) {
                            final handled =
                                _continuousKey.currentState
                                    ?.scrollToPreviousChapter() ??
                                false;
                            if (!handled) notifier.previousChapter();
                          } else {
                            notifier.previousChapter();
                          }
                        },
                        onNextChapter: () {
                          if (isContinuous) {
                            final handled =
                                _continuousKey.currentState
                                    ?.scrollToNextChapter() ??
                                false;
                            if (!handled) notifier.nextChapter();
                          } else {
                            notifier.nextChapter();
                          }
                        },
                      ),

                    if (!isNovelText)
                      ReaderFloatingPageBadge(
                        currentPage: state.currentPageIndex,
                        totalPages: state.pages?.length ?? 0,
                        overlaysVisible: state.overlaysVisible,
                      ),
                  ],
                ),
              ),
            ),
            const Positioned.fill(child: ScreenFilterOverlay()),
          ],
        ),
      ),
    );
  }

  // The text settings of this series for everything below, rebuilt only when a value changes.
  List<Override> _novelOverrides = const [];
  (ReaderFontFamily, double, double, double)? _novelKey;

  List<Override> _novelOverridesFor(ReaderSessionState state) {
    final key = (
      state.novelFontFamily,
      state.novelFontSize,
      state.novelLineHeight,
      state.novelParagraphSpacing,
    );
    if (key == _novelKey) return _novelOverrides;
    _novelKey = key;
    return _novelOverrides = [
      novelFontFamilyProvider.overrideWith((ref) => Stream.value(key.$1)),
      novelFontSizeProvider.overrideWith((ref) => Stream.value(key.$2)),
      novelLineHeightProvider.overrideWith((ref) => Stream.value(key.$3)),
      novelParagraphSpacingProvider.overrideWith((ref) => Stream.value(key.$4)),
    ];
  }
}
