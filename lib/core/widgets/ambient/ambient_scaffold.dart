import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/ambient/ambient_bloom_background.dart';
import 'package:sumizuri/core/widgets/controls/no_scrollbar.dart';

/// A page with the ambient background and an app bar that hides while scrolling down.
class AmbientScaffold extends StatefulWidget {
  const AmbientScaffold({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    required this.body,
    this.floatingActionButton,
    this.maxContentWidth,
    this.autoHideBar = true,
  });

  final Widget title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget body;
  final Widget? floatingActionButton;

  /// Centers the body and caps its width so settings pages stay readable when wide.
  final double? maxContentWidth;

  /// Whether the app bar leaves the screen while the content scrolls down.
  final bool autoHideBar;

  @override
  State<AmbientScaffold> createState() => _AmbientScaffoldState();
}

class _AmbientScaffoldState extends State<AmbientScaffold>
    with SingleTickerProviderStateMixin {
  // How far content must move one way before the bar follows, so a wobble does not flicker.
  static const _travel = 32.0;
  // After the bar moves, scroll movement is not the reader's for a moment.
  static const _settle = Duration(milliseconds: 300);

  // 1 when the bar is shown, 0 when it is gone.
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  )..addListener(_followBar);

  bool _visible = true;
  double _travelled = 0;
  DateTime _lockedUntil = DateTime.fromMillisecondsSinceEpoch(0);

  double _barHeight = 0;
  double _shownHeight = 0;
  ScrollPosition? _position;

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  void _setVisible(bool visible) {
    if (_visible == visible) return;
    _visible = visible;
    _travelled = 0;
    _lockedUntil = DateTime.now().add(_settle);
    _slide.animateTo(
      visible ? 1 : 0,
      curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
    );
  }

  // The page height changes as the bar slides, so the scroll moves by the same amount.
  void _followBar() {
    final height = _barHeight * _slide.value;
    final change = height - _shownHeight;
    _shownHeight = height;
    final position = _position;
    if (change == 0 || position == null || !position.hasPixels) return;
    if (change < 0) {
      final room = position.pixels - position.minScrollExtent;
      final by = -change > room ? -room : change;
      if (by != 0) position.correctBy(by);
    } else if (position.pixels > position.minScrollExtent) {
      position.correctBy(change);
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (!widget.autoHideBar) return false;
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final context = notification.context;
    if (context != null) _position = Scrollable.maybeOf(context)?.position;
    if (notification is! ScrollUpdateNotification) return false;

    // Near the top the bar is always there.
    if (notification.metrics.pixels <= 0) {
      _setVisible(true);
      return false;
    }
    if (DateTime.now().isBefore(_lockedUntil)) return false;

    final delta = notification.scrollDelta ?? 0;
    if (delta == 0) return false;
    // A change of direction starts the count again.
    if ((delta > 0) != (_travelled > 0)) _travelled = 0;
    _travelled += delta;
    if (_travelled > _travel && notification.metrics.pixels > _barHeight) {
      _setVisible(false);
    } else if (_travelled < -_travel) {
      _setVisible(true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bar = AppBar(
      title: widget.title,
      actions: widget.actions,
      bottom: widget.bottom,
      backgroundColor: Colors.transparent,
      flexibleSpace: const WindowAmbient(),
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    );
    final barHeight =
        bar.preferredSize.height + MediaQuery.paddingOf(context).top;
    if (barHeight != _barHeight) {
      _barHeight = barHeight;
      _shownHeight = barHeight * _slide.value;
    }

    final body = widget.maxContentWidth == null
        ? widget.body
        : Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.maxContentWidth!),
              child: ScrollConfiguration(
                behavior: const NoScrollbarBehavior(),
                child: widget.body,
              ),
            ),
          );

    return Scaffold(
      floatingActionButton: widget.floatingActionButton,
      body: Stack(
        children: [
          const AmbientBloomBackground(),
          Column(
            children: [
              AnimatedBuilder(
                animation: _slide,
                child: OverflowBox(
                  alignment: Alignment.bottomCenter,
                  minHeight: barHeight,
                  maxHeight: barHeight,
                  child: bar,
                ),
                builder: (context, child) => Container(
                  height: barHeight * _slide.value,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  child: child,
                ),
              ),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScroll,
                    child: body,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AmbientAppBarBackdrop extends StatelessWidget {
  const AmbientAppBarBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const WindowAmbient();
  }
}
