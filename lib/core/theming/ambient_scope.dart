import 'package:flutter/widgets.dart';

/// How strong the soft colour washes behind the app are. 1 is the theme's own amount.
class AmbientScope extends InheritedWidget {
  const AmbientScope({super.key, this.intensity = 1.0, required super.child});

  final double intensity;

  static double intensityOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AmbientScope>()?.intensity ??
      1.0;

  @override
  bool updateShouldNotify(AmbientScope oldWidget) =>
      intensity != oldWidget.intensity;
}
