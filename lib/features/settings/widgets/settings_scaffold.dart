import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';

/// The page every settings screen is built on: the ambient scaffold at a
/// readable width, with its rows drawn as the History-style cards. Using it
/// is what makes one settings page look like the next.
class SettingsScaffold extends StatelessWidget {
  const SettingsScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottom,
    this.floatingActionButton,
    this.maxContentWidth = 720,
    this.rowMargin,
  });

  final Widget title;
  final Widget body;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final double maxContentWidth;

  /// The side margin of each row card, instead of the page gutter. Zero when
  /// the page places the cards itself.
  final double? rowMargin;

  @override
  Widget build(BuildContext context) {
    return AmbientScaffold(
      maxContentWidth: maxContentWidth,
      title: title,
      actions: actions,
      bottom: bottom,
      floatingActionButton: floatingActionButton,
      body: AppRowStyle(horizontalMargin: rowMargin, child: body),
    );
  }
}
