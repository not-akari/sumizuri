part of 'ambient_bloom_background.dart';

class _WindowAmbientLeaf extends LeafRenderObjectWidget {
  const _WindowAmbientLeaf({
    required this.base,
    required this.blooms,
    required this.gradient,
    required this.window,
    required this.epoch,
  });

  final Color base;
  final List<_Bloom> blooms;
  final _ResolvedGradient? gradient;
  final Size window;
  final int epoch;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderWindowAmbient(base, blooms, gradient, window, epoch);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderWindowAmbient renderObject,
  ) {
    renderObject
      ..base = base
      ..blooms = blooms
      ..gradient = gradient
      ..window = window
      ..epoch = epoch;
  }
}

class _RenderWindowAmbient extends RenderBox {
  _RenderWindowAmbient(
    this._base,
    this._blooms,
    this._gradient,
    this._window,
    this._epoch,
  ) : _basePaint = Paint()..color = _base;

  Color _base;
  Paint _basePaint;
  List<_Bloom> _blooms;
  _ResolvedGradient? _gradient;
  Size _window;
  int _epoch;

  // The gradient's paint is rebuilt only when it or the window changes.
  Paint? _gradientPaint;
  Size? _gradientPaintWindow;

  set epoch(int value) {
    if (value == _epoch) return;
    _epoch = value;
    markNeedsPaint();
  }

  set base(Color value) {
    if (value == _base) return;
    _base = value;
    _basePaint = Paint()..color = value;
    markNeedsPaint();
  }

  set blooms(List<_Bloom> value) {
    if (identical(value, _blooms)) return;
    _blooms = value;
    markNeedsPaint();
  }

  set gradient(_ResolvedGradient? value) {
    if (value == _gradient) return;
    _gradient = value;
    _gradientPaint = null;
    markNeedsPaint();
  }

  set window(Size value) {
    if (value == _window) return;
    _window = value;
    markNeedsPaint();
  }

  Paint _paintFor(_ResolvedGradient gradient) {
    final cached = _gradientPaint;
    if (cached != null && _gradientPaintWindow == _window) return cached;
    final rect = Offset.zero & _window;
    final radians = gradient.angle * math.pi / 180;
    final dx = math.cos(radians);
    final dy = math.sin(radians);
    final shader = switch (gradient.style) {
      GradientStyle.linear => LinearGradient(
        begin: Alignment(-dx, -dy),
        end: Alignment(dx, dy),
        colors: gradient.colors,
      ).createShader(rect),
      GradientStyle.radial => RadialGradient(
        center: Alignment(dx * 0.7, dy * 0.7),
        radius: 1.0,
        colors: gradient.colors,
      ).createShader(rect),
    };
    _gradientPaintWindow = _window;
    return _gradientPaint = Paint()..shader = shader;
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    // Where the window's top-left corner is, in this box's paint space.
    final origin = offset - localToGlobal(Offset.zero);
    canvas
      ..save()
      ..clipRect(offset & size)
      ..drawRect(offset & size, _basePaint)
      ..translate(origin.dx, origin.dy);
    final gradient = _gradient;
    if (gradient != null) {
      canvas.drawRect(Offset.zero & _window, _paintFor(gradient));
    }
    for (final bloom in _blooms) {
      final cx = (bloom.align.x * 0.5 + 0.5) * _window.width;
      final cy = (bloom.align.y * 0.5 + 0.5) * _window.height;
      final scale = bloom.radius * _window.shortestSide;
      canvas
        ..save()
        ..translate(cx, cy)
        ..scale(scale)
        ..drawCircle(Offset.zero, 1, bloom.paint)
        ..restore();
    }
    canvas.restore();
  }
}
