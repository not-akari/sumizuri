import 'package:flutter/material.dart';

class BrushLinePainter extends CustomPainter {
  BrushLinePainter({required this.color, this.curvy = true});
  final Color color;

  /// False draws a plain straight line instead of the hand-drawn curve.
  final bool curvy;

  @override
  void paint(Canvas canvas, Size size) {
    final path = curvy
        ? _squiggle(size)
        : (Path()
            ..moveTo(0, size.height * 0.5)
            ..lineTo(size.width, size.height * 0.5));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  Path _squiggle(Size size) {
    return Path()
      ..moveTo(0, size.height * 0.6)
      ..cubicTo(
        size.width * 0.2,
        size.height * 0.1,
        size.width * 0.4,
        size.height * 0.9,
        size.width * 0.6,
        size.height * 0.4,
      )
      ..cubicTo(
        size.width * 0.75,
        size.height * 0.05,
        size.width * 0.85,
        size.height * 0.7,
        size.width,
        size.height * 0.3,
      );
  }

  @override
  bool shouldRepaint(covariant BrushLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.curvy != curvy;
}
