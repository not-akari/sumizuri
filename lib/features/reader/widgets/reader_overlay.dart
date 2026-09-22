import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/app_motion.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

part 'reader_top_bar.dart';
part 'reader_bottom_bar.dart';

class ReaderVerticalNavigator extends StatefulWidget {
  const ReaderVerticalNavigator({
    super.key,
    required this.visible,
    required this.currentPage,
    required this.totalPages,
    required this.onJump,
  });

  final bool visible;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onJump;

  @override
  State<ReaderVerticalNavigator> createState() =>
      _ReaderVerticalNavigatorState();
}

class _ReaderVerticalNavigatorState extends State<ReaderVerticalNavigator> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final last = (widget.totalPages - 1).clamp(0, 1 << 30).toDouble();
    if (last <= 0) return const SizedBox.shrink();
    final value = (_drag ?? widget.currentPage.toDouble()).clamp(0.0, last);
    final height = MediaQuery.sizeOf(context).height * 0.55;
    final theme = SliderTheme.of(context).copyWith(
      thumbColor: Colors.white,
      activeTrackColor: Colors.white70,
      inactiveTrackColor: Colors.white24,
      overlayShape: SliderComponentShape.noOverlay,
      trackHeight: 3,
    );
    return Positioned(
      right: 2,
      top: 0,
      bottom: 0,
      child: AnimatedOpacity(
        duration: AppMotion.medium,
        opacity: widget.visible ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !widget.visible,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${value.round() + 1}/${widget.totalPages}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                SizedBox(
                  height: height,
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: SliderTheme(
                      data: theme,
                      child: Slider(
                        min: 0,
                        max: last,
                        value: value,
                        onChanged: (v) => setState(() => _drag = v),
                        onChangeEnd: (v) {
                          widget.onJump(v.round());
                          setState(() => _drag = null);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReaderFloatingPageBadge extends StatefulWidget {
  const ReaderFloatingPageBadge({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.overlaysVisible,
  });

  final int currentPage;
  final int totalPages;
  final bool overlaysVisible;

  @override
  State<ReaderFloatingPageBadge> createState() =>
      _ReaderFloatingPageBadgeState();
}

class _ReaderFloatingPageBadgeState extends State<ReaderFloatingPageBadge> {
  bool _visible = false;
  Timer? _hideTimer;

  @override
  void didUpdateWidget(ReaderFloatingPageBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPage != oldWidget.currentPage &&
        !widget.overlaysVisible) {
      _showTemporarily();
    }
  }

  void _showTemporarily() {
    _hideTimer?.cancel();
    if (!_visible && mounted) {
      setState(() => _visible = true);
    }
    _hideTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _visible = false);
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.totalPages > 0 ? widget.totalPages : 1;
    final current = (widget.currentPage + 1).clamp(1, total);
    final shouldShow = _visible && !widget.overlaysVisible;

    return Positioned(
      bottom: 28,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedScale(
          scale: shouldShow ? 1.0 : 0.88,
          duration: shouldShow ? AppMotion.medium : AppMotion.fast,
          curve: shouldShow ? AppMotion.curveSpring : AppMotion.curveExit,
          child: AnimatedOpacity(
            opacity: shouldShow ? 1.0 : 0.0,
            duration: AppMotion.fast,
            curve: AppMotion.curveInteractive,
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: context.shapes.chip.radius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: context.shapes.chip.radius,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      '$current / $total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
