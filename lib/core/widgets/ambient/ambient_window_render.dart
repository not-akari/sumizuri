part of 'ambient_bloom_background.dart';

class _WindowAmbientLeaf extends LeafRenderObjectWidget {
  const _WindowAmbientLeaf({
    required this.base,
    required this.blooms,
    required this.window,
    required this.epoch,
  });

  final Color base;
  final List<_Bloom> blooms;
  final Size window;
  final int epoch;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderWindowAmbient(base, blooms, window, epoch);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderWindowAmbient renderObject,
  ) {
    renderObject
      ..base = base
      ..blooms = blooms
      ..window = window
      ..epoch = epoch;
  }
}

class _RenderWindowAmbient extends RenderBox {
  _RenderWindowAmbient(this._base, this._blooms, this._window, this._epoch)
    : _basePaint = Paint()..color = _base;

  Color _base;
  Paint _basePaint;
  List<_Bloom> _blooms;
  Size _window;
  int _epoch;

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

  set window(Size value) {
    if (value == _window) return;
    _window = value;
    markNeedsPaint();
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
