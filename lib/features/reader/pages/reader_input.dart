part of 'reader_screen.dart';

mixin _ReaderInput on ConsumerState<ReaderScreen> {
  abstract int _glide;
  abstract bool _autoScroll;
  Ticker get _ticker;
  abstract Duration _lastTick;
  abstract LogicalKeyboardKey? _glideKey;
  GlobalKey<NovelContinuousViewerState> get _novelContinuousKey;
  GlobalKey<ContinuousVerticalViewerState> get _continuousKey;
  GlobalKey<PagedViewerState> get _pagedKey;
  GlobalKey<NovelPagedViewerState> get _novelPagedKey;
  bool get _scrollable;
  bool get _novelScroll;
  ReaderControls get _controls;
  Future<void> _toggleBookmark(MChapter chapter);
  void _openInBrowser(MChapter chapter);
  void _openSettings();

  void _syncTicker() {
    final needed = _autoScroll || _glide != 0;
    if (needed && !_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    } else if (!needed && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    // A long frame (the app was busy) must not become a lurch.
    final dt = ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastTick = elapsed;
    if (!_scrollable || dt == 0) return;
    final steps = _controls.scroll;
    final speed =
        (_autoScroll ? steps.autoSpeed : 0.0) + _glide * steps.holdSpeed;
    if (speed == 0) return;
    final delta = speed * dt;
    if (_novelScroll) {
      _novelContinuousKey.currentState?.scrollBy(delta, animate: false);
    } else {
      _continuousKey.currentState?.scrollBy(delta, animate: false);
    }
  }

  void _setAutoScroll(bool on) {
    if (_autoScroll == on) return;
    setState(() => _autoScroll = on);
    _syncTicker();
  }

  void _stopGlide() {
    if (_glide == 0) return;
    _glide = 0;
    _glideKey = null;
    _syncTicker();
  }

  void _changeAutoSpeed(ReaderControls controls, double factor) {
    final range = ScrollSteps.autoRange;
    final speed = ((controls.scroll.autoSpeed * factor) / 5).round() * 5.0;
    final next = controls.withScroll(
      controls.scroll.copyWith(autoSpeed: speed.clamp(range.min, range.max)),
    );
    unawaited(
      ref
          .read(settingsRepositoryProvider)
          .setReaderControls(next.isDefault ? null : next.toJsonString()),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 900),
          content: Text(
            AppLocalizations.of(context)!
                .readerAutoScrollNow(next.scroll.autoSpeed.round()),
          ),
        ),
      );
  }

  void _perform(
    ReaderAction action,
    ReaderSessionState state,
    ReaderController notifier, {
    required bool fromTap,
    required ReaderControls controls,
    bool repeat = false,
    LogicalKeyboardKey? key,
    required bool isContinuous,
    required bool isNovelBook,
    required bool isNovelContinuous,
  }) {
    switch (action) {
      case ReaderAction.toggleOverlays:
        notifier.toggleOverlays();
        return;
      case ReaderAction.nextChapter:
        notifier.nextChapter();
        return;
      case ReaderAction.previousChapter:
        notifier.previousChapter();
        return;
      case ReaderAction.openSettings:
        _openSettings();
        return;
      case ReaderAction.toggleAutoScroll:
        if (!isContinuous) return;
        final on = !_autoScroll;
        // Out of the way, so the page is readable while it moves.
        if (on && state.overlaysVisible) notifier.toggleOverlays();
        _setAutoScroll(on);
        return;
      case ReaderAction.autoScrollFaster:
        _changeAutoSpeed(controls, 1.25);
        return;
      case ReaderAction.autoScrollSlower:
        _changeAutoSpeed(controls, 0.8);
        return;
      case ReaderAction.openInBrowser:
        _openInBrowser(state.currentChapter);
        return;
      case ReaderAction.toggleBookmark:
        unawaited(_toggleBookmark(state.currentChapter));
        return;
      default:
        break;
    }

    if (isContinuous) {
      void scrollBy(double delta, {bool animate = true}) => isNovelContinuous
          ? _novelContinuousKey.currentState?.scrollBy(delta, animate: animate)
          : _continuousKey.currentState?.scrollBy(delta, animate: animate);
      final steps = controls.scroll;
      final height = MediaQuery.sizeOf(context).height;
      final screen =
          height * (fromTap ? steps.tapFraction : steps.pageFraction);
      void startGlide(int direction) {
        if (key == null || _glide == direction) return;
        _glide = direction;
        _glideKey = key;
        _syncTicker();
      }

      switch (action) {
        case ReaderAction.nextPage:
          if (!repeat) scrollBy(screen);
        case ReaderAction.previousPage:
          if (!repeat) scrollBy(-screen);
        case ReaderAction.scrollDown:
          repeat ? startGlide(1) : scrollBy(steps.arrowPixels);
        case ReaderAction.scrollUp:
          repeat ? startGlide(-1) : scrollBy(-steps.arrowPixels);
        default:
          break;
      }
      return;
    }

    final isRtl = !isNovelBook && state.mode == ReaderMode.rightToLeft;
    final invert = fromTap && !isNovelBook && state.invertTaps;
    final bool goNext;
    switch (action) {
      case ReaderAction.nextPage:
        goNext = true;
      case ReaderAction.previousPage:
        goNext = false;
      case ReaderAction.pageRight:
        goNext = !(isRtl ^ invert);
      case ReaderAction.pageLeft:
        goNext = isRtl ^ invert;
      default:
        return;
    }
    if (isNovelBook) {
      final viewer = _novelPagedKey.currentState;
      goNext ? viewer?.nextPage() : viewer?.previousPage();
      return;
    }
    final viewer = _pagedKey.currentState;
    goNext ? viewer?.nextPage() : viewer?.previousPage();
  }

  void _onTapZone(
    TapUpDetails details,
    ReaderSessionState state,
    ReaderController notifier,
    ReaderControls controls, {
    required bool isContinuous,
    required bool isNovelBook,
    required bool isNovelContinuous,
  }) {
    final size = MediaQuery.sizeOf(context);
    final action = controls.actionForTap(
      isContinuous ? TapLayout.continuous : TapLayout.paged,
      details.localPosition.dx / size.width,
      details.localPosition.dy / size.height,
    );
    if (action == null) return;
    _perform(
      action,
      state,
      notifier,
      fromTap: true,
      controls: controls,
      isContinuous: isContinuous,
      isNovelBook: isNovelBook,
      isNovelContinuous: isNovelContinuous,
    );
  }

  bool _onKeyEvent(
    KeyEvent event,
    ReaderSessionState state,
    ReaderController notifier,
    ReaderControls controls, {
    required bool isContinuous,
    required bool isNovelBook,
    required bool isNovelContinuous,
  }) {
    if (event is KeyUpEvent) {
      if (_glideKey != event.logicalKey) return false;
      _stopGlide();
      return true;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;

    final keyboard = HardwareKeyboard.instance;
    final action = controls.actionForKey(
      KeyChord(
        event.logicalKey.keyId,
        ctrl: keyboard.isControlPressed,
        shift: keyboard.isShiftPressed,
        alt: keyboard.isAltPressed,
        meta: keyboard.isMetaPressed,
      ),
    );
    if (action == null) return false;
    _perform(
      action,
      state,
      notifier,
      fromTap: false,
      controls: controls,
      repeat: event is KeyRepeatEvent,
      key: event.logicalKey,
      isContinuous: isContinuous,
      isNovelBook: isNovelBook,
      isNovelContinuous: isNovelContinuous,
    );
    return true;
  }
}
