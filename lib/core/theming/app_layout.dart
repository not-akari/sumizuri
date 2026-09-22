import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';

/// Sizes that follow the screen so one number fits a small phone and a tablet.
class AppLayout {
  const AppLayout._({required this.width, required this.spacing});

  factory AppLayout.of(BuildContext context) => AppLayout._(
    width: MediaQuery.sizeOf(context).width,
    spacing: context.options.layout.spacing,
  );

  final double width;
  final double spacing;

  /// A small phone, where every pixel of margin counts.
  bool get compact => width < 400;

  /// The margin at the sides of a page: 14 on a small phone, growing with the width up to 32.
  double get gutter => (width * 0.045).clamp(14.0, 32.0) * spacing;

  /// The space at the end of a scroll page so the last row can rise above the tab bar.
  double scrollBottomOf(BuildContext context, [double extra = 16]) =>
      MediaQuery.paddingOf(context).bottom + extra;

  /// Page margins with the same gutter on both sides.
  EdgeInsets padding({double top = 0, double bottom = 0}) =>
      EdgeInsets.fromLTRB(gutter, top, gutter, bottom);
}

extension AppLayoutContext on BuildContext {
  AppLayout get layout => AppLayout.of(this);
}
