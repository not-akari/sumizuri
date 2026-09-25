import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/theme_options.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';

/// The bar that shows how far a title has been read, drawn as the theme says:
/// a line, a glowing comet, stripes or steps.
class EntryProgressBar extends StatefulWidget {
  const EntryProgressBar({
    super.key,
    required this.progress,
    this.options,
    this.onCover = false,
  });

  /// From 0 to 1.
  final double progress;

  /// The look to draw. The theme's own when not given, which is what the app
  /// uses; the editor passes the draft it is showing.
  final ThemeProgress? options;

  /// Drawn over a picture, so the empty part is dark whatever the theme is.
  final bool onCover;

  /// Whether a bar is drawn at all for [progress] under [look].
  static bool visible(double progress, ThemeProgress look) {
    if (progress <= 0) return !look.hideEmpty;
    if (progress >= 1) return !look.hideComplete;
    return true;
  }

  @override
  State<EntryProgressBar> createState() => _EntryProgressBarState();
}

class _EntryProgressBarState extends State<EntryProgressBar>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  ThemeProgress get _look => widget.options ?? context.options.progress;

  bool get _moving =>
      _look.animate &&
      _look.style == ProgressStyle.striped &&
      widget.progress > 0 &&
      !MediaQuery.disableAnimationsOf(context);

  void _syncAnimation() {
    if (_moving && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!_moving && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant EntryProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = _look;
    final cs = Theme.of(context).colorScheme;
    final progress = widget.progress.clamp(0.0, 1.0);
    final (start, end) = switch (look.colorMode) {
      ProgressColorMode.accent => (cs.primary, cs.primary),
      ProgressColorMode.gradient => (cs.primary, cs.tertiary),
      ProgressColorMode.custom => (
        Color(look.customColor),
        Color(look.customColor),
      ),
    };
    final track = widget.onCover
        ? Colors.black.withValues(alpha: 0.55 * look.trackOpacity / 0.35)
        : cs.onSurface.withValues(alpha: look.trackOpacity * 0.5);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size(double.infinity, look.thickness),
          painter: _BarPainter(
            progress: progress,
            look: look,
            start: start,
            end: end,
            track: track,
            phase: _controller.value,
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.progress,
    required this.look,
    required this.start,
    required this.end,
    required this.track,
    required this.phase,
  });

  final double progress;
  final ThemeProgress look;
  final Color start;
  final Color end;
  final Color track;
  final double phase;

  static const _steps = 10;

  RRect _round(Rect rect) => RRect.fromRectAndRadius(
    rect,
    Radius.circular(look.rounded ? rect.height / 2 : 0),
  );

  @override
  void paint(Canvas canvas, Size size) {
    switch (look.style) {
      case ProgressStyle.segments:
        _paintSegments(canvas, size);
      case ProgressStyle.glow:
        _paintGlow(canvas, size);
      case ProgressStyle.striped:
        _paintFilled(canvas, size, stripes: true);
      case ProgressStyle.line:
        _paintFilled(canvas, size, stripes: false);
    }
  }

  Rect _fillRect(Size size) {
    final width = size.width * progress;
    // A little read is still a visible mark, not a hairline that vanishes.
    return Rect.fromLTWH(
      0,
      0,
      progress <= 0 ? 0 : math.max(width, math.min(size.height, size.width)),
      size.height,
    );
  }

  void _paintFilled(Canvas canvas, Size size, {required bool stripes}) {
    canvas.drawRRect(_round(Offset.zero & size), Paint()..color = track);
    final fill = _fillRect(size);
    if (fill.width <= 0) return;
    final rrect = _round(fill);
    canvas.drawRRect(
      rrect,
      Paint()..shader = LinearGradient(colors: [start, end]).createShader(fill),
    );
    if (!stripes) return;
    canvas.save();
    canvas.clipRRect(rrect);
    final spacing = size.height * 2.2;
    final slant = size.height;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.22);
    for (
      var x = -spacing + phase * spacing;
      x < fill.width + spacing;
      x += spacing
    ) {
      canvas.drawPath(
        Path()
          ..moveTo(x + slant, 0)
          ..lineTo(x + slant + size.height * 1.1, 0)
          ..lineTo(x + size.height * 1.1, size.height)
          ..lineTo(x, size.height)
          ..close(),
        paint,
      );
    }
    canvas.restore();
  }

  void _paintGlow(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    // A dark channel with a faint rim, so the light has something to sit in.
    canvas.drawRRect(_round(full), Paint()..color = track);
    canvas.drawRRect(
      _round(full.deflate(0.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.10),
    );
    final fill = _fillRect(size);
    if (fill.width <= 0) return;
    // The line of light is thinner than the channel and fades out behind the head.
    final line = Rect.fromLTWH(
      fill.left,
      size.height * 0.28,
      fill.width,
      size.height * 0.44,
    );
    final shader = LinearGradient(
      colors: [end.withValues(alpha: 0), start.withValues(alpha: 0.85), end],
      stops: const [0, 0.55, 1],
    ).createShader(line);
    if (look.glow > 0) {
      // Twice, a wide soft bloom and a tighter one, so the head reads as light.
      for (final reach in [1.0, 0.45]) {
        canvas.drawRRect(
          _round(line),
          Paint()
            ..shader = shader
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              size.height * (0.5 + look.glow * 2.0) * reach,
            ),
        );
      }
    }
    canvas.drawRRect(_round(line), Paint()..shader = shader);
    // The head, brighter than the tail.
    final head = Rect.fromLTWH(
      math.max(0, fill.width - size.height * 0.9),
      line.top,
      math.min(size.height * 0.9, fill.width),
      line.height,
    );
    canvas.drawRRect(
      _round(head),
      Paint()..color = Color.lerp(end, Colors.white, 0.6)!,
    );
  }

  void _paintSegments(Canvas canvas, Size size) {
    final gap = math.max(2.0, size.height * 0.4);
    final width = (size.width - gap * (_steps - 1)) / _steps;
    for (var i = 0; i < _steps; i++) {
      final cell = Rect.fromLTWH(i * (width + gap), 0, width, size.height);
      canvas.drawRRect(_round(cell), Paint()..color = track);
      final share = ((progress * _steps) - i).clamp(0.0, 1.0);
      if (share <= 0) continue;
      final color = Color.lerp(start, end, i / (_steps - 1))!;
      canvas.drawRRect(
        _round(Rect.fromLTWH(cell.left, 0, width * share, size.height)),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.progress != progress ||
      old.look != look ||
      old.start != start ||
      old.end != end ||
      old.track != track ||
      old.phase != phase;
}
