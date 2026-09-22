import 'package:flutter/animation.dart';

class AppMotion {
  const AppMotion._();

  static const Duration micro = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration page = Duration(milliseconds: 320);
  static const Duration long = Duration(milliseconds: 400);

  static const Curve curveExit = Curves.easeInCubic;
  static const Curve curveInteractive = Curves.easeOutCubic;

  static const Curve curveSpring = Cubic(0.34, 1.35, 0.64, 1.0);

  static const Curve curveSnappy = Cubic(0.2, 0.0, 0.0, 1.0);

  static const Curve curveLiquid = Cubic(0.18, 0.9, 0.2, 1.12);
}
