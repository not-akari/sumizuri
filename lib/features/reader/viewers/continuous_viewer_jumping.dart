part of 'continuous_vertical_viewer.dart';

mixin _ContinuousJumping on State<ContinuousVerticalViewer> {
  ScrollController get _scrollController;
  ListController get _listController;
  ContinuousItemsBuilder get _itemsBuilder;
  Map<String, GlobalKey> get _pageKeysMap;
  abstract bool _revealed;
  set _lastReportedPage(int value);
  abstract String? _lastReportedChapterUrl;
  set _isChapterTransitioning(bool value);
  set _isJumpingToPage(bool value);
  abstract int _jumpToPageRequestId;
  abstract int _jumpToChapterRequestId;

  List<ContinuousItem> _buildItems();
  void _reportVisiblePage(List<ContinuousItem> items, {bool force = false});
  void _reportPage(PageItem item, {required bool force});

  // Animates each jump hop, or jumps instantly when reduce motion is on.
  void _moveToTarget(
    int targetIdx, {
    Duration? animationDuration,
    bool instant = false,
  }) {
    // Sliding over many pages would load them all, so a far target is jumped to.
    final from = _listController.isAttached
        ? _listController.visibleRange?.$1
        : null;
    final far = from != null && (targetIdx - from).abs() > 4;
    if (instant || far || MediaQuery.disableAnimationsOf(context)) {
      _listController.jumpToItem(
        index: targetIdx,
        scrollController: _scrollController,
        alignment: 0.0,
      );
      return;
    }
    final duration =
        animationDuration ??
        ContinuousVerticalViewerState._hopAnimationDuration;
    _listController.animateToItem(
      index: targetIdx,
      scrollController: _scrollController,
      alignment: 0.0,
      duration: (_) => duration,
      curve: (_) => AppMotion.curveInteractive,
    );
  }

  // Retries on postFrameCallback so each attempt reflects a real completed layout pass.
  void _jumpToInitialPage(int target, [int attempt = 0]) {
    if (!mounted) return;

    if (!_listController.isAttached || !_scrollController.hasClients) {
      if (attempt < 5) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _jumpToInitialPage(target, attempt + 1),
        );
        return;
      }
      if (!_revealed) setState(() => _revealed = true);
      return;
    }

    final chapterUrl = _lastReportedChapterUrl ?? '';
    final targetIdx = _itemsBuilder.indexForTarget(
      chapterUrl,
      target,
      _buildItems(),
    );
    if (targetIdx < 0) {
      if (!_revealed) setState(() => _revealed = true);
      return;
    }

    _listController.jumpToItem(
      index: targetIdx,
      scrollController: _scrollController,
      alignment: 0.0,
    );

    final range = _listController.visibleRange;
    final settled =
        range != null && range.$1 <= targetIdx && targetIdx <= range.$2;
    if (!settled && attempt < 5) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _jumpToInitialPage(target, attempt + 1),
      );
      return;
    }

    _lastReportedPage = target;
    _lastReportedChapterUrl = chapterUrl;

    _isJumpingToPage = true;
    _confirmJumpSettled(
      chapterUrl,
      target,
      0,
      null,
      ++_jumpToPageRequestId,
      true,
      () {
        if (mounted && !_revealed) setState(() => _revealed = true);
      },
    );
  }

  void jumpToPage(int index) {
    final requestId = ++_jumpToPageRequestId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || requestId != _jumpToPageRequestId) return;
      _performJumpToPage(index);
    });
  }

  void _performJumpToPage(int index) {
    if (!_listController.isAttached || !_scrollController.hasClients) return;
    final candidateChapterUrl =
        _lastReportedChapterUrl ??
        widget.currentChapter?.url ??
        widget.continuousChapters?.firstOrNull?.chapter.url ??
        '';
    final items = _buildItems();
    final chapterUrl = _itemsBuilder.resolveChapterUrl(
      candidateChapterUrl,
      items,
    );
    final targetIdx = _itemsBuilder.indexForTarget(chapterUrl, index, items);
    if (targetIdx < 0) return;

    // Do not preset the last reported page, or the real landing is skipped as a duplicate.
    _isJumpingToPage = true;
    _confirmJumpSettled(chapterUrl, index, 0, null, _jumpToPageRequestId);
  }

  // Repeatedly re-jumps with fresh data each attempt instead of jumping once and watching.
  void _confirmJumpSettled(
    String chapterUrl,
    int pageIndex, [
    int attempt = 0,
    double? lastDy,
    int? requestId,
    bool instant = false,
    VoidCallback? onDone,
  ]) {
    if (requestId != null && requestId != _jumpToPageRequestId) {
      onDone?.call();
      return;
    }

    if (!mounted ||
        !_listController.isAttached ||
        !_scrollController.hasClients) {
      _isJumpingToPage = false;
      onDone?.call();
      return;
    }

    final key = _pageKeysMap['${chapterUrl}_$pageIndex'];
    final box = key?.currentContext?.findRenderObject();
    double? dy;
    if (box is RenderBox && box.hasSize && box.attached) {
      dy = box.localToGlobal(Offset.zero).dy;
      final isNearTop = dy.abs() < 50;
      final isStable = lastDy != null && (dy - lastDy).abs() < 1.0;
      if (isNearTop && isStable) {
        for (final item in _buildItems()) {
          if (item is PageItem &&
              item.chapter.url == chapterUrl &&
              item.pageIndex == pageIndex) {
            _isJumpingToPage = false;
            _reportPage(item, force: true);
            onDone?.call();
            return;
          }
        }
      }
    }

    if (attempt >= ContinuousVerticalViewerState._maxSettleAttempts) {
      _isJumpingToPage = false;
      if (!instant) _reportVisiblePage(_buildItems(), force: true);
      onDone?.call();
      return;
    }

    final items = _buildItems();
    final targetIdx = _itemsBuilder.indexForTarget(
      chapterUrl,
      pageIndex,
      items,
    );
    // Near the top it only settles while pictures load and is not jumped to again.
    final nearTop = dy != null && dy.abs() < 50;
    if (targetIdx >= 0 && !nearTop) {
      _moveToTarget(targetIdx, instant: instant);
    }

    // Paces retries to real loading time.
    Future.delayed(
      ContinuousVerticalViewerState._settleRetryInterval,
      () => _confirmJumpSettled(
        chapterUrl,
        pageIndex,
        attempt + 1,
        dy,
        requestId,
        instant,
        onDone,
      ),
    );
  }

  void jumpToChapter(MChapter chapter) {
    if (!_listController.isAttached || !_scrollController.hasClients) return;
    final targetIdx = _itemsBuilder.indexForTarget(
      chapter.url,
      0,
      _buildItems(),
    );
    if (targetIdx < 0) return;

    const animatedDuration = Duration(milliseconds: 250);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? const Duration(milliseconds: 32)
        : animatedDuration;
    final requestId = ++_jumpToChapterRequestId;
    _isChapterTransitioning = true;
    _moveToTarget(targetIdx, animationDuration: animatedDuration);
    Future.delayed(duration, () {
      if (requestId != _jumpToChapterRequestId) return;
      _isChapterTransitioning = false;
      if (!mounted) return;
      _reportVisiblePage(_buildItems(), force: true);
    });
  }
}
