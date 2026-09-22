// Detects a single tap and a double tap on the same area without conflicting.
import 'package:flutter/material.dart';

class TapDoubleTapArea extends StatefulWidget {
  const TapDoubleTapArea({
    super.key,
    required this.child,
    required this.onTap,
    this.onDoubleTap,
    this.customBorder,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final ShapeBorder? customBorder;
  final BorderRadius? borderRadius;

  @override
  State<TapDoubleTapArea> createState() => _TapDoubleTapAreaState();
}

class _TapDoubleTapAreaState extends State<TapDoubleTapArea> {
  DateTime? _lastTapTime;
  static const _doubleTapThreshold = Duration(milliseconds: 350);

  void _handleTap() {
    final now = DateTime.now();
    final last = _lastTapTime;
    if (widget.onDoubleTap != null &&
        last != null &&
        now.difference(last) < _doubleTapThreshold) {
      _lastTapTime = null;
      widget.onDoubleTap!();
      return;
    }
    _lastTapTime = now;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _handleTap,
      customBorder: widget.customBorder,
      borderRadius: widget.customBorder == null ? widget.borderRadius : null,
      child: widget.child,
    );
  }
}
