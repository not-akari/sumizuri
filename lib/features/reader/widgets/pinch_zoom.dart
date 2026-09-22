import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

const maxPinchScale = 4.0;

class PinchZoomState {
  const PinchZoomState({
    this.scale = 1,
    this.offset = Offset.zero,
    required this.viewport,
  });

  final double scale;
  final Offset offset;
  final Size viewport;

  bool get zoomed => scale > 1;

  PinchZoomState pinched({
    required double lastSpread,
    required double spread,
    required Offset lastFocal,
    required Offset focal,
  }) {
    if (lastSpread <= 0 || spread <= 0) return this;
    final next = (scale * spread / lastSpread).clamp(1.0, maxPinchScale);
    final anchored = focal - (lastFocal - offset) * (next / scale);
    return _settled(next, anchored);
  }

  PinchZoomState dragged(double dx) =>
      zoomed ? _settled(scale, offset.translate(dx, 0)) : this;

  PinchZoomState _settled(double newScale, Offset newOffset) {
    if (newScale < 1.01) return PinchZoomState(viewport: viewport);
    return PinchZoomState(
      scale: newScale,
      viewport: viewport,
      offset: Offset(
        newOffset.dx.clamp(viewport.width * (1 - newScale), 0.0),
        newOffset.dy.clamp(viewport.height * (1 - newScale), 0.0),
      ),
    );
  }

  PinchZoomState withViewport(Size size) =>
      size == viewport ? this : PinchZoomState(viewport: size);
}

class PinchZoom extends StatefulWidget {
  const PinchZoom({super.key, required this.builder});

  final Widget Function(BuildContext context, bool pinching) builder;

  @override
  State<PinchZoom> createState() => _PinchZoomState();
}

class _PinchZoomState extends State<PinchZoom> {
  PinchZoomState _zoom = const PinchZoomState(viewport: Size.zero);
  final _pointers = <int, Offset>{};
  double _lastSpread = 0;
  Offset _lastFocal = Offset.zero;
  double _panZoomScale = 1;

  Widget? _content;
  bool? _contentPinching;

  bool get _pinching => _pointers.length >= 2;

  @override
  void didUpdateWidget(PinchZoom oldWidget) {
    super.didUpdateWidget(oldWidget);
    _content = null;
  }

  void _restartPinch() {
    if (!_pinching) return;
    final points = _pointers.values.take(2).toList();
    _lastSpread = (points[0] - points[1]).distance;
    _lastFocal = (points[0] + points[1]) / 2;
  }

  void _down(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse) return;
    final wasPinching = _pinching;
    _pointers[event.pointer] = event.localPosition;
    _restartPinch();
    if (_pinching != wasPinching) setState(() {});
  }

  void _move(PointerMoveEvent event) {
    final previous = _pointers[event.pointer];
    if (previous == null) return;
    _pointers[event.pointer] = event.localPosition;
    if (_pinching) {
      final points = _pointers.values.take(2).toList();
      final spread = (points[0] - points[1]).distance;
      final focal = (points[0] + points[1]) / 2;
      setState(() {
        _zoom = _zoom.pinched(
          lastSpread: _lastSpread,
          spread: spread,
          lastFocal: _lastFocal,
          focal: focal,
        );
      });
      _lastSpread = spread;
      _lastFocal = focal;
    } else if (_zoom.zoomed) {
      setState(() => _zoom = _zoom.dragged(event.localDelta.dx));
    }
  }

  void _up(PointerEvent event) {
    final wasPinching = _pinching;
    if (_pointers.remove(event.pointer) == null) return;
    _restartPinch();
    if (_pinching != wasPinching) setState(() {});
  }

  void _panZoomStart(PointerPanZoomStartEvent event) => _panZoomScale = 1;

  void _panZoomUpdate(PointerPanZoomUpdateEvent event) {
    if (event.scale == _panZoomScale) return;
    setState(() {
      _zoom = _zoom.pinched(
        lastSpread: _panZoomScale,
        spread: event.scale,
        lastFocal: event.localPosition,
        focal: event.localPosition,
      );
    });
    _panZoomScale = event.scale;
  }

  Widget _contentFor(BuildContext context) {
    if (_content == null || _contentPinching != _pinching) {
      _content = widget.builder(context, _pinching);
      _contentPinching = _pinching;
    }
    return _content!;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _zoom = _zoom.withViewport(constraints.biggest);
        return Listener(
          onPointerDown: _down,
          onPointerMove: _move,
          onPointerUp: _up,
          onPointerCancel: _up,
          onPointerPanZoomStart: _panZoomStart,
          onPointerPanZoomUpdate: _panZoomUpdate,
          child: ClipRect(
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(0, 0, _zoom.scale)
                ..setEntry(1, 1, _zoom.scale)
                ..setEntry(0, 3, _zoom.offset.dx)
                ..setEntry(1, 3, _zoom.offset.dy),
              child: _contentFor(context),
            ),
          ),
        );
      },
    );
  }
}
