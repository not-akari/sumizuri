import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import 'package:sumizuri/core/theming/app_motion.dart';
import 'package:sumizuri/core/widgets/controls/no_scrollbar.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_page.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/reader/data/page_aspect_cache.dart';
import 'package:sumizuri/features/reader/data/page_dimension_probe.dart';
import 'package:sumizuri/features/reader/models/reader_session_state.dart';
import 'package:sumizuri/features/reader/viewers/continuous_items_builder.dart';
import 'package:sumizuri/features/reader/viewers/continuous_viewer_item_builder.dart';
import 'package:sumizuri/features/reader/viewers/continuous_viewer_items.dart';
import 'package:sumizuri/features/reader/widgets/pinch_zoom.dart';
import 'package:sumizuri/features/reader/widgets/reader_page_image.dart';

part 'continuous_viewer_jumping.dart';

class ContinuousVerticalViewer extends StatefulWidget {
  const ContinuousVerticalViewer({
    super.key,
    required this.pages,
    this.continuousChapters,
    this.currentChapter,
    required this.scaleType,
    required this.background,
    required this.pageGap,
    required this.initialPage,
    required this.onPageChanged,
    required this.columnWidth,
    required this.hasPreviousChapter,
    required this.hasNextChapter,
    required this.onPreviousChapter,
    required this.onNextChapter,
    this.onLoadNextChapter,
    this.onLoadPreviousChapter,
    this.onActiveChapterChanged,
    this.imageQuality = ReaderImageQuality.balanced,
    this.headers,
  });

  final List<MPage> pages;
  final List<ContinuousChapter>? continuousChapters;
  final MChapter? currentChapter;
  final ReaderScaleType scaleType;
  final ReaderBackground background;
  final ReaderPageGap pageGap;
  final int initialPage;
  final ValueChanged<int> onPageChanged;
  final ReaderColumnWidth columnWidth;
  final ReaderImageQuality imageQuality;
  final bool hasPreviousChapter;
  final bool hasNextChapter;
  final VoidCallback onPreviousChapter;
  final VoidCallback onNextChapter;
  final Future<void> Function()? onLoadNextChapter;
  final Future<void> Function()? onLoadPreviousChapter;
  final void Function(MChapter chapter, int pageIndex)? onActiveChapterChanged;
  final Map<String, String>? headers;

  @override
  State<ContinuousVerticalViewer> createState() =>
      ContinuousVerticalViewerState();
}

class ContinuousVerticalViewerState extends State<ContinuousVerticalViewer>
    with _ContinuousJumping {
  @override
  late final ScrollController _scrollController;
  @override
  late final ListController _listController;

  @override
  late bool _revealed;

  @override
  int _lastReportedPage = 0;
  @override
  String? _lastReportedChapterUrl;

  // Holds back page reports while a chapter skip or slider jump converges, to avoid flicker.
  bool _transitioning = false;
  bool _jumping = false;

  // The list is built differently while it jumps, so a change asks for a rebuild.
  void _rebuildSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  bool get _isChapterTransitioning => _transitioning;
  @override
  set _isChapterTransitioning(bool value) {
    if (_transitioning == value) return;
    _transitioning = value;
    _rebuildSoon();
  }

  bool get _isJumpingToPage => _jumping;
  @override
  set _isJumpingToPage(bool value) {
    if (_jumping == value) return;
    _jumping = value;
    _rebuildSoon();
  }

  @override
  int _jumpToPageRequestId = 0;
  @override
  int _jumpToChapterRequestId = 0;

  // Keyed per page so the visibility check can measure how much of a page is on screen.
  @override
  final Map<String, GlobalKey> _pageKeysMap = {};

  @override
  final _itemsBuilder = ContinuousItemsBuilder();
  List<ContinuousItem> _cachedItems = const [];

  static const _settleRetryInterval = Duration(milliseconds: 200);
  static const _maxSettleAttempts = 12;
  static const _hopAnimationDuration = Duration(milliseconds: 180);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _listController = ListController();
    _lastReportedPage = widget.initialPage;
    _lastReportedChapterUrl =
        widget.currentChapter?.url ??
        widget.continuousChapters?.firstOrNull?.chapter.url;

    WidgetsBinding.instance.addPostFrameCallback((_) => _probePages());

    final target = widget.initialPage;
    _revealed = target <= 0;
    if (!_revealed) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _jumpToInitialPage(target),
      );
    }
  }

  @override
  void didUpdateWidget(ContinuousVerticalViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _probePages();
    });
    // Only the first chapter changing can put items above the ones being read.
    if (!identical(
      oldWidget.continuousChapters?.firstOrNull,
      widget.continuousChapters?.firstOrNull,
    )) {
      _keepPlaceWhenItemsAreAddedAbove();
    }
    if (widget.currentChapter != null &&
        widget.currentChapter?.url != oldWidget.currentChapter?.url) {
      _lastReportedChapterUrl = widget.currentChapter!.url;
    }
  }

  @override
  void dispose() {
    _probe.close();
    _listController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  List<ContinuousItem> _buildItems() => _itemsBuilder.build(
    continuousChapters: widget.continuousChapters,
    pages: widget.pages,
    currentChapter: widget.currentChapter,
    hasNextChapter: widget.hasNextChapter,
    hasPreviousChapter: widget.hasPreviousChapter,
  );

  bool scrollToNextChapter() {
    final chapters = widget.continuousChapters;
    if (chapters == null || chapters.isEmpty) {
      widget.onNextChapter();
      return true;
    }

    final activeUrl =
        widget.currentChapter?.url ??
        _lastReportedChapterUrl ??
        chapters.first.chapter.url;
    final currentIdx = chapters.indexWhere((c) => c.chapter.url == activeUrl);
    if (currentIdx >= 0 && currentIdx < chapters.length - 1) {
      final nextChapter = chapters[currentIdx + 1].chapter;
      jumpToChapter(nextChapter);
      return true;
    }

    if (widget.hasNextChapter) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: AppMotion.curveInteractive,
        );
      }
      // Not preloaded yet, so the scroll above only reaches the current end.
      final loadNext = widget.onLoadNextChapter;
      if (loadNext != null) {
        loadNext().then((_) {
          if (!mounted) return;
          final updated = widget.continuousChapters;
          final idx = updated?.indexWhere((c) => c.chapter.url == activeUrl);
          if (updated != null &&
              idx != null &&
              idx >= 0 &&
              idx < updated.length - 1) {
            jumpToChapter(updated[idx + 1].chapter);
          }
        });
      }
      return true;
    }
    return false;
  }

  bool scrollToPreviousChapter() {
    final chapters = widget.continuousChapters;
    if (chapters == null || chapters.isEmpty) {
      widget.onPreviousChapter();
      return true;
    }

    final activeUrl =
        widget.currentChapter?.url ??
        _lastReportedChapterUrl ??
        chapters.first.chapter.url;
    final currentIdx = chapters.indexWhere((c) => c.chapter.url == activeUrl);
    if (currentIdx > 0) {
      final prevChapter = chapters[currentIdx - 1].chapter;
      jumpToChapter(prevChapter);
      return true;
    }

    if (widget.hasPreviousChapter) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: AppMotion.curveInteractive,
        );
      }
      final loadPrevious = widget.onLoadPreviousChapter;
      if (loadPrevious != null) {
        loadPrevious().then((_) {
          if (!mounted) return;
          final updated = widget.continuousChapters;
          final idx = updated?.indexWhere((c) => c.chapter.url == activeUrl);
          if (updated != null && idx != null && idx > 0) {
            jumpToChapter(updated[idx - 1].chapter);
          }
        });
      }
      return true;
    }
    return false;
  }

  void scrollBy(double offset, {bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + offset).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    if (!animate) {
      _scrollController.jumpTo(target);
      return;
    }
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: AppMotion.curveInteractive,
    );
  }

  // What tells an item apart when the list changes. Only pages and chapter headers have one.
  String? _identityOf(ContinuousItem item) => switch (item) {
    PageItem(:final chapter, :final pageIndex) => '${chapter.url}_$pageIndex',
    HeaderItem(:final chapter) => '${chapter.url}_header',
    _ => null,
  };

  double _estimateItemExtent(ContinuousItem item, double crossAxisExtent) {
    if (item is PageItem) {
      final width = crossAxisExtent < widget.columnWidth.pixels
          ? crossAxisExtent
          : widget.columnWidth.pixels;
      return width *
              PageAspectCache.instance.aspectOrGuess(item.page.imageUrl) +
          widget.pageGap.pixels;
    }
    return switch (item) {
      HeaderItem() => 110.0,
      TopItem() => 80.0,
      LoadingItem() || ErrorItem() => 100.0,
      FooterItem() => 80.0,
      PageItem() => 0.0,
    };
  }

  double _offsetOfIndex(int index) {
    var offset = 0.0;
    for (var i = 0; i < index; i++) {
      offset += _listController.extentForIndex(i).$1;
    }
    return offset;
  }

  // A previous chapter adds items above, so the offset is corrected to avoid a jump.
  void _keepPlaceWhenItemsAreAddedAbove() {
    if (!_listController.isAttached || !_scrollController.hasClients) return;
    final oldItems = _cachedItems;
    final range = _listController.visibleRange;
    if (oldItems.isEmpty || range == null) return;

    int? anchorOld;
    String? anchorId;
    for (var i = range.$1; i <= range.$2 && i < oldItems.length; i++) {
      final id = _identityOf(oldItems[i]);
      if (id != null) {
        anchorOld = i;
        anchorId = id;
        break;
      }
    }
    if (anchorOld == null || anchorId == null) return;

    final newItems = _buildItems();
    final anchorNew = newItems.indexWhere((i) => _identityOf(i) == anchorId);
    final added = anchorNew - anchorOld;
    if (added <= 0) return;

    final position = _scrollController.position;
    final inside = position.pixels - _offsetOfIndex(anchorOld);
    final width = MediaQuery.sizeOf(context).width;
    var shift = 0.0;
    for (var i = 0; i < added; i++) {
      shift += _estimateItemExtent(newItems[i], width);
    }
    position.correctBy(shift);

    // Once the new items are measured, settle on the exact place.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_listController.isAttached) return;
      if (!_scrollController.hasClients) return;
      // A finger or a fling already in motion is left alone, since the estimate above holds.
      if (_scrollController.position.isScrollingNotifier.value) return;
      final target = _offsetOfIndex(anchorNew) + inside;
      if ((_scrollController.position.pixels - target).abs() > 8) {
        _scrollController.jumpTo(
          target.clamp(0.0, _scrollController.position.maxScrollExtent),
        );
      }
    });
  }

  double _estimateExtent(int? index, double crossAxisExtent) {
    if (index == null || index < 0 || index >= _cachedItems.length) {
      return crossAxisExtent * PageAspectCache.instance.guess;
    }
    final item = _cachedItems[index];
    if (item is PageItem) {
      final width = crossAxisExtent < widget.columnWidth.pixels
          ? crossAxisExtent
          : widget.columnWidth.pixels;
      return width *
              PageAspectCache.instance.aspectOrGuess(item.page.imageUrl) +
          widget.pageGap.pixels;
    }
    return switch (item) {
      HeaderItem() => 110.0,
      TopItem() => 80.0,
      LoadingItem() || ErrorItem() => 100.0,
      FooterItem() => 80.0,
      PageItem() => crossAxisExtent * PageAspectCache.instance.guess,
    };
  }

  // Reads page heights from file starts, nearest to the reader first, before pictures load.
  final _probe = PageDimensionProbe();
  final _probeTried = <String>{};
  final _probeLearned = <String>{};
  var _probeWorkers = 0;
  bool _invalidateQueued = false;

  static const _probeWorkerCount = 3;

  void _probePages() {
    if (widget.scaleType == ReaderScaleType.original) return;
    // The worker count is fixed first, since idle workers end at once and would loop forever.
    final toStart = _probeWorkerCount - _probeWorkers;
    for (var i = 0; i < toStart; i++) {
      _probeWorkers++;
      unawaited(_probeWorker());
    }
  }

  PageItem? _nextPageToProbe() {
    final range = _listController.isAttached
        ? _listController.visibleRange
        : null;
    final center = range?.$1 ?? 0;
    PageItem? best;
    var bestDistance = 1 << 30;
    for (var i = 0; i < _cachedItems.length; i++) {
      final item = _cachedItems[i];
      if (item is! PageItem) continue;
      final url = item.page.imageUrl;
      if (url == null || url.isEmpty || item.page.text != null) continue;
      if (PageAspectCache.instance.of(url) != null) continue;
      if (_probeTried.contains(url)) continue;
      final distance = (i - center).abs();
      if (distance < bestDistance) {
        best = item;
        bestDistance = distance;
      }
    }
    return best;
  }

  Future<void> _probeWorker() async {
    try {
      while (mounted) {
        final item = _nextPageToProbe();
        if (item == null) return;
        final url = item.page.imageUrl!;
        _probeTried.add(url);
        final aspect = await _probe.aspectOf(
          item.page,
          headers: widget.headers,
        );
        if (!mounted) return;
        if (aspect != null && PageAspectCache.instance.record(url, aspect)) {
          _probeLearned.add(url);
          _queueExtentRefresh();
        }
      }
    } finally {
      _probeWorkers--;
    }
  }

  // Pages whose height was just learned and not yet measured use it as their estimate.
  void _queueExtentRefresh() {
    if (_invalidateQueued) return;
    _invalidateQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _invalidateQueued = false;
      if (!mounted || !_listController.isAttached) return;
      final learned = {..._probeLearned};
      _probeLearned.clear();
      for (var i = 0; i < _cachedItems.length; i++) {
        final item = _cachedItems[i];
        if (item is! PageItem || !learned.contains(item.page.imageUrl)) {
          continue;
        }
        if (i < _listController.numberOfItems &&
            _listController.extentForIndex(i).$2) {
          _listController.invalidateExtent(i);
        }
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  // Deferred to a post frame callback, since mutating Riverpod state during a build throws.
  void _deferred(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) action();
    });
  }

  void _handlePageImageLoaded() {
    if (!mounted) return;
    if (_isChapterTransitioning || _isJumpingToPage) return;
    _queueVisiblePageReport();
  }

  @override
  void _reportVisiblePage(
    List<ContinuousItem> items, {
    bool force = false,
    bool allowFallback = true,
  }) {
    final range = _listController.isAttached
        ? _listController.visibleRange
        : null;
    if (range == null) return;

    final screenHeight = MediaQuery.sizeOf(context).height;
    PageItem? fallback;
    for (var i = range.$1; i <= range.$2 && i < items.length; i++) {
      final item = items[i];
      if (item is! PageItem) continue;
      fallback ??= item;

      final key = _pageKeysMap['${item.chapter.url}_${item.pageIndex}'];
      final box = key?.currentContext?.findRenderObject();
      if (box is RenderBox && box.hasSize && box.attached) {
        final position = box.localToGlobal(Offset.zero);
        if (position.dy + box.size.height > 100 && position.dy < screenHeight) {
          _reportPage(item, force: force);
          return;
        }
      }
    }

    if (allowFallback && fallback != null) {
      _reportPage(fallback, force: force);
    }
  }

  @override
  void _reportPage(PageItem item, {required bool force}) {
    if (force ||
        _lastReportedChapterUrl != item.chapter.url ||
        _lastReportedPage != item.pageIndex) {
      _lastReportedChapterUrl = item.chapter.url;
      _lastReportedPage = item.pageIndex;
      final chapter = item.chapter;
      final pageIndex = item.pageIndex;
      _deferred(() {
        if (chapter.url.isNotEmpty) {
          widget.onActiveChapterChanged?.call(chapter, pageIndex);
        }
        widget.onPageChanged(pageIndex);
      });
    }
  }

  bool _onScrollNotification(
    ScrollNotification notification,
    List<ContinuousItem> items,
  ) {
    if (notification is OverscrollNotification &&
        notification.overscroll < 0 &&
        widget.hasPreviousChapter &&
        widget.onLoadPreviousChapter != null) {
      _deferred(() => widget.onLoadPreviousChapter?.call());
    }

    if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification) {
      if (widget.hasNextChapter && widget.onLoadNextChapter != null) {
        final position = _scrollController.position;
        if (position.maxScrollExtent - position.pixels < 2500) {
          _deferred(() => widget.onLoadNextChapter?.call());
        }
      }

      if (!_isChapterTransitioning && !_isJumpingToPage) {
        _queueVisiblePageReport();
      }
    }
    return false;
  }

  bool _reportQueued = false;

  // Scroll notifications can arrive mid layout, so the check runs once at the frame end.
  void _queueVisiblePageReport() {
    if (_reportQueued) return;
    _reportQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reportQueued = false;
      if (!mounted || _isChapterTransitioning || _isJumpingToPage) return;
      _reportVisiblePage(_cachedItems, allowFallback: false);
      _probePages();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColorFor(widget.background, context);
    final gap = widget.pageGap.pixels;
    final maxWidth = widget.columnWidth.pixels;
    final textColor = textColorFor(widget.background);
    final items = _buildItems();
    _cachedItems = items;

    Widget constrainPage(Widget child) {
      if (maxWidth.isFinite) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      }
      return child;
    }

    return Container(
      color: bgColor,
      child: PinchZoom(
        builder: (context, pinching) => _list(
          context,
          items: items,
          pinching: pinching,
          gap: gap,
          constrainPage: constrainPage,
          textColor: textColor,
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context, {
    required List<ContinuousItem> items,
    required bool pinching,
    required double gap,
    required Widget Function(Widget) constrainPage,
    required Color textColor,
  }) {
    return Stack(
      children: [
        IgnorePointer(
          ignoring: !_revealed,
          child: Opacity(
            opacity: _revealed ? 1.0 : 0.0,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) => _onScrollNotification(n, items),
              child: ScrollConfiguration(
                behavior: const NoScrollbarBehavior().copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  },
                ),
                child: SuperListView.builder(
                  controller: _scrollController,
                  listController: _listController,
                  extentEstimation: _estimateExtent,
                  // Held still while two fingers pinch, so the page does not slide under them.
                  physics: pinching
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(),
                  // About one screen ahead, since page sizes come from headers, and less while jumping.
                  cacheExtent: _isJumpingToPage || _isChapterTransitioning
                      ? MediaQuery.sizeOf(context).height * 0.25
                      : MediaQuery.sizeOf(context).height.clamp(900.0, 2000.0),
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  itemBuilder: (context, index) => buildContinuousItem(
                    context,
                    items[index],
                    textColor: textColor,
                    gap: gap,
                    constrainPage: constrainPage,
                    pageKeyFor: (chapterUrl, pageIndex) => _pageKeysMap
                        .putIfAbsent('${chapterUrl}_$pageIndex', GlobalKey.new),
                    scaleType: widget.scaleType,
                    background: widget.background,
                    imageQuality: widget.imageQuality,
                    headers: widget.headers,
                    hasPreviousChapter: widget.hasPreviousChapter,
                    hasNextChapter: widget.hasNextChapter,
                    onPreviousChapter: () => scrollToPreviousChapter(),
                    onNextChapter: () => scrollToNextChapter(),
                    onLoadPrevious: widget.onLoadPreviousChapter == null
                        ? null
                        : () => widget.onLoadPreviousChapter!(),
                    onRetryNext: widget.onLoadNextChapter == null
                        ? null
                        : () => widget.onLoadNextChapter!(),
                    onImageLoaded: () => _handlePageImageLoaded(),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!_revealed) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
