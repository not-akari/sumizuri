// The ambient background: each piece paints its slice of one window-sized picture.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/ambient_scope.dart';
import 'package:sumizuri/core/theming/theme_options.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';

part 'ambient_window_render.dart';

/// The user's gradient with its colours settled and its strength applied,
/// ready to paint across the window.
class _ResolvedGradient {
  const _ResolvedGradient(this.style, this.angle, this.colors);

  final GradientStyle style;
  final double angle;
  final List<Color> colors;

  @override
  bool operator ==(Object other) =>
      other is _ResolvedGradient &&
      other.style == style &&
      other.angle == angle &&
      _same(other.colors, colors);

  @override
  int get hashCode => Object.hash(style, angle, Object.hashAll(colors));

  static bool _same(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// A unit circle each wash gradient is defined against, then placed with canvas transforms.
final _unitCircle = Rect.fromCircle(center: Offset.zero, radius: 1);

class _Bloom {
  _Bloom({required this.align, required this.radius, required Color color})
    : paint = Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(_unitCircle);

  final Alignment align;
  final double radius;
  final Paint paint;
}

/// Tells every ambient below to repaint once settled, so each cuts its slice in place.
class AmbientEpoch extends InheritedWidget {
  const AmbientEpoch({super.key, required this.epoch, required super.child});

  final int epoch;

  static int of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AmbientEpoch>()?.epoch ?? 0;

  @override
  bool updateShouldNotify(AmbientEpoch oldWidget) => epoch != oldWidget.epoch;
}

/// Fills its space with this widget's slice of the window-wide ambient picture.
class WindowAmbient extends StatefulWidget {
  const WindowAmbient({super.key});

  @override
  State<WindowAmbient> createState() => _WindowAmbientState();
}

class _WindowAmbientState extends State<WindowAmbient> {
  // Rebuilt only when the theme's colours change, and each Paint is reused.
  List<_Bloom> _blooms = const [];
  _ResolvedGradient? _gradient;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cs = Theme.of(context).colorScheme;
    // The gradient is the theme's own; the intensity setting still dims it.
    final background = context.options.background;
    final gradientAlpha =
        background.gradientStrength *
        AmbientScope.intensityOf(context).clamp(0.0, 1.0);
    _gradient = !background.gradient
        ? null
        : _ResolvedGradient(
            background.gradientStyle,
            background.gradientAngle,
            [
              for (final c in background.resolve(
                primary: cs.primary,
                tertiary: cs.tertiary,
              ))
                c.withValues(alpha: gradientAlpha),
            ],
          );
    final strength =
        context.options.effects.bloom * AmbientScope.intensityOf(context);
    double a(double base) => (base * strength).clamp(0.0, 1.0);
    _blooms = strength <= 0
        ? const []
        : [
            _Bloom(
              align: const Alignment(-0.85, -0.95),
              radius: 0.6,
              color: cs.primary.withValues(alpha: a(0.15)),
            ),
            _Bloom(
              align: const Alignment(0.9, 0.55),
              radius: 0.52,
              color: cs.onSurface.withValues(alpha: a(0.06)),
            ),
            _Bloom(
              align: const Alignment(-0.55, 0.9),
              radius: 0.34,
              color: cs.primary.withValues(alpha: a(0.1)),
            ),
            _Bloom(
              align: const Alignment(0.35, -0.6),
              radius: 0.3,
              color: cs.tertiary.withValues(alpha: a(0.07)),
            ),
          ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: _WindowAmbientLeaf(
        base: cs.surface,
        blooms: _blooms,
        gradient: _gradient,
        window: MediaQuery.sizeOf(context),
        epoch: AmbientEpoch.of(context),
      ),
    );
  }
}

class AmbientBloomBackground extends StatelessWidget {
  const AmbientBloomBackground({super.key});

  @override
  Widget build(BuildContext context) =>
      const Positioned.fill(child: WindowAmbient());
}
