import 'package:flutter/widgets.dart';

/// How strong the soft colour washes behind the app are. 1 is the theme's own amount.
class AmbientScope extends InheritedWidget {
  const AmbientScope({
    super.key,
    this.intensity = 1.0,
    this.compactLists = false,
    required super.child,
  });

  final double intensity;

  /// Whether list rows are drawn flat and dense, not as boxed cards.
  final bool compactLists;

  static double intensityOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AmbientScope>()?.intensity ??
      1.0;

  static bool compactListsOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AmbientScope>()
          ?.compactLists ??
      false;

  @override
  bool updateShouldNotify(AmbientScope oldWidget) =>
      intensity != oldWidget.intensity ||
      compactLists != oldWidget.compactLists;
}
