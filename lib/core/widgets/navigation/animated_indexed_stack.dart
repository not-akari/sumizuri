import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/theming/app_motion.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_bloom_background.dart';

enum AnimatedStackMotion { depth, slide, fade }

class AnimatedIndexedStack extends StatefulWidget {
  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.motion = AnimatedStackMotion.depth,
    this.duration = AppMotion.page,
    this.curve = AppMotion.curveSpring,
  });

  final int index;
  final List<Widget> children;
  final AnimatedStackMotion motion;
  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  int _currentIndex = 0;
  int _previousIndex = 0;
  int _settledEpoch = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _previousIndex = widget.index;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _settledEpoch += 1);
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _currentIndex) {
      _previousIndex = _currentIndex;
      _currentIndex = widget.index;

      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final speed = context.options.motion.transitionSpeed;
      _controller.duration = reduceMotion
          ? Duration.zero
          : Duration(
              microseconds: (widget.duration.inMicroseconds / speed).round(),
            );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildTransition({
    required Widget child,
    required bool isIncoming,
    required bool isForward,
    required Animation<double> animation,
  }) {
    switch (widget.motion) {
      case AnimatedStackMotion.depth:
        final slideTween = isIncoming
            ? Tween<Offset>(
                begin: Offset(0.0, isForward ? 0.045 : -0.045),
                end: Offset.zero,
              )
            : Tween<Offset>(
                begin: Offset.zero,
                end: Offset(0.0, isForward ? -0.025 : 0.025),
              );
        final scaleTween = isIncoming
            ? Tween<double>(begin: 0.94, end: 1.0)
            : Tween<double>(begin: 1.0, end: 0.96);
        final opacityTween = isIncoming
            ? Tween<double>(begin: 0.0, end: 1.0)
            : Tween<double>(begin: 1.0, end: 0.0);

        return SlideTransition(
          position: slideTween.animate(animation),
          child: ScaleTransition(
            scale: scaleTween.animate(animation),
            child: FadeTransition(
              opacity: opacityTween.animate(animation),
              child: child,
            ),
          ),
        );

      case AnimatedStackMotion.slide:
        final slideTween = isIncoming
            ? Tween<Offset>(
                begin: Offset(isForward ? 0.22 : -0.22, 0.0),
                end: Offset.zero,
              )
            : Tween<Offset>(
                begin: Offset.zero,
                end: Offset(isForward ? -0.22 : 0.22, 0.0),
              );
        final scaleTween = isIncoming
            ? Tween<double>(begin: 0.94, end: 1.0)
            : Tween<double>(begin: 1.0, end: 0.94);
        final opacityTween = isIncoming
            ? Tween<double>(begin: 0.0, end: 1.0)
            : Tween<double>(begin: 1.0, end: 0.0);

        return SlideTransition(
          position: slideTween.animate(animation),
          child: ScaleTransition(
            scale: scaleTween.animate(animation),
            child: FadeTransition(
              opacity: opacityTween.animate(animation),
              child: child,
            ),
          ),
        );

      case AnimatedStackMotion.fade:
        final opacityTween = isIncoming
            ? Tween<double>(begin: 0.0, end: 1.0)
            : Tween<double>(begin: 1.0, end: 0.0);

        return FadeTransition(
          opacity: opacityTween.animate(animation),
          child: child,
        );
    }
  }

  Widget _page(int i, {required bool isAnimating, required bool isForward}) {
    final isCurrent = i == _currentIndex;
    final isLeaving = i == _previousIndex && isAnimating && !isCurrent;
    final visible = isCurrent || isLeaving;
    final animation = (isAnimating && visible)
        ? _animation
        : (isCurrent
              ? kAlwaysCompleteAnimation
              : const AlwaysStoppedAnimation<double>(0));
    return KeyedSubtree(
      key: ValueKey('page-$i'),
      child: TickerMode(
        enabled: visible,
        child: Offstage(
          offstage: !visible,
          child: _buildTransition(
            isIncoming: !isLeaving,
            isForward: isForward,
            animation: animation,
            child: RepaintBoundary(
              child: IgnorePointer(
                ignoring: isLeaving,
                child: widget.children[i],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();
    if (_currentIndex >= widget.children.length) {
      _currentIndex = 0;
    }
    if (_previousIndex >= widget.children.length) {
      _previousIndex = 0;
    }

    final isForward = _currentIndex >= _previousIndex;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final isAnimating = _controller.isAnimating;

        return AmbientEpoch(
          epoch: _settledEpoch,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                for (var i = 0; i < widget.children.length; i++)
                  _page(i, isAnimating: isAnimating, isForward: isForward),
              ],
            ),
          ),
        );
      },
    );
  }
}
