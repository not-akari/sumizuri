// Wraps a child so it scales down slightly when pressed or hovered.
import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/theming/app_motion.dart';

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale,
    this.hoverScale,
    this.enableHover = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  final double? pressedScale;
  final double? hoverScale;
  final bool enableHover;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;
  bool _isHovered = false;

  void _onPointerDown(PointerDownEvent _) {
    if (!mounted) return;
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isPressed = true);
    }
  }

  void _onPointerUp(PointerUpEvent _) {
    if (!mounted) return;
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _onPointerCancel(PointerCancelEvent _) {
    if (!mounted) return;
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.options.motion;
    final hover =
        1 + ((widget.hoverScale ?? 1.02) - 1) * (motion.hoverScale - 1) / 0.02;
    final press =
        1 -
        (1 - (widget.pressedScale ?? 0.96)) * (1 - motion.pressScale) / 0.04;
    final double targetScale = _isPressed
        ? press
        : (_isHovered && widget.enableHover ? hover : 1.0);

    final curve = _isPressed ? AppMotion.curveSnappy : AppMotion.curveSpring;
    final duration = _isPressed
        ? AppMotion.micro
        : const Duration(milliseconds: 200);

    return MouseRegion(
      onEnter: (_) {
        if (!mounted) return;
        if (widget.enableHover && !_isHovered) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (!mounted) return;
        if (_isHovered) {
          setState(() => _isHovered = false);
        }
      },
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: AnimatedScale(
          scale: targetScale,
          duration: duration,
          curve: curve,
          child: AnimatedSlide(
            offset: (_isHovered && widget.enableHover && !_isPressed)
                ? const Offset(0, -0.015)
                : Offset.zero,
            duration: AppMotion.fast,
            curve: AppMotion.curveInteractive,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
