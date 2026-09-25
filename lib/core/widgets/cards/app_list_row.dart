import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/ambient_scope.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/widgets/controls/pressable_scale.dart';

/// Makes the [AppListRow]s and [AppSectionLabel]s below it draw the way the
/// History list does: each row its own soft inset card, its label lined up
/// with the card edge. Outside one, rows stay flat, as they are in sheets.
class AppRowStyle extends InheritedWidget {
  const AppRowStyle({super.key, this.horizontalMargin, required super.child});

  /// The space at each side of a card, instead of the page gutter. Zero
  /// when the cards sit in a column that has its own margins.
  final double? horizontalMargin;

  static AppRowStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppRowStyle>();

  /// The side margin for a card or label here.
  static double marginOf(BuildContext context) =>
      maybeOf(context)?.horizontalMargin ?? context.layout.gutter;

  @override
  bool updateShouldNotify(AppRowStyle oldWidget) =>
      horizontalMargin != oldWidget.horizontalMargin;
}

class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.onTap,
    this.titleWidget,
    this.subtitleWidget,
    this.horizontalPadding,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;

  /// Replace the plain title and subtitle text, such as to highlight a search match.
  final Widget? titleWidget;
  final Widget? subtitleWidget;

  /// The space at each side, instead of the page gutter, for a row inside a card.
  final double? horizontalPadding;

  Widget _content(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final options = context.options;
    return Row(
      children: [
        if (options.components.listIconTiles) ...[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              border: Border.all(
                color: cs.outlineVariant,
                width: context.shapes.borderWidth,
              ),
              borderRadius: context.shapes.iconTile.radius,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 19,
              color: iconColor ?? cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget ??
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
              if (subtitleWidget != null) ...[
                const SizedBox(height: 2),
                subtitleWidget!,
              ] else if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 12, color: cs.outline),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null)
          trailing!
        else if (onTap != null && options.components.listChevron)
          Icon(Icons.chevron_right_rounded, color: cs.outline, size: 20),
      ],
    );
  }

  /// The dense form of a row: no box, no icon tile, just an icon, the text
  /// and what goes at the end, so a phone screen holds more of them.
  Widget _compactRow(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final margin = AppRowStyle.marginOf(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: margin == 0 ? 2 : margin,
            vertical: 6,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Icon(
                  icon,
                  size: 22,
                  color: iconColor ?? cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget ??
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                    if (subtitleWidget != null)
                      subtitleWidget!
                    else if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 12, color: cs.outline),
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null && context.options.components.listChevron)
                Icon(Icons.chevron_right_rounded, color: cs.outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AppRowStyle.maybeOf(context) != null) {
      if (AmbientScope.compactListsOf(context)) return _compactRow(context);
      return AppCard(
        tone: AppCardTone.inset,
        margin: EdgeInsets.symmetric(
          horizontal: AppRowStyle.marginOf(context),
          vertical: 4,
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        onTap: onTap,
        child: _content(context),
      );
    }
    final spacing = context.options.layout.spacing;
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding ?? context.layout.gutter,
            vertical: 12 * spacing,
          ),
          child: _content(context),
        ),
      ),
    );
  }
}

class AppSectionLabel extends StatelessWidget {
  const AppSectionLabel({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final side = AppRowStyle.marginOf(context);
    final compact = AmbientScope.compactListsOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        side,
        (compact ? 14 : 20) * context.options.layout.spacing,
        side,
        compact ? 4 : 8,
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: cs.outline,
        ),
      ),
    );
  }
}
