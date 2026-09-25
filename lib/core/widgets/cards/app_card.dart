import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/ambient_scope.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart' show AppRowStyle;
import 'package:sumizuri/core/widgets/controls/pressable_scale.dart';

/// How a card looks: a bordered panel, a soft row fill, or a light inset.
enum AppCardTone { solid, soft, inset }

/// The one card of the app, with an optional title, margin and tap.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.titleGap = 12,
    this.padding,
    this.margin,
    this.tone = AppCardTone.solid,
    this.color,
    this.borderColor,
    this.onTap,
    this.flattenWhenCompact = false,
  });

  final Widget child;

  /// A heading over the content.
  final String? title;

  /// Sits at the right end of the heading line.
  final Widget? trailing;
  final double titleGap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AppCardTone tone;

  /// Replaces the fill of the [tone].
  final Color? color;

  /// Replaces the border colour of the [tone].
  final Color? borderColor;
  final VoidCallback? onTap;

  /// When lists are set to compact, draws the content with no box: no fill, no
  /// border and less padding, only a hairline under it. For cards that hold
  /// content and are not a notice, so a phone screen fits more of them.
  final bool flattenWhenCompact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shapes = context.shapes;
    final flat = flattenWhenCompact && AmbientScope.compactListsOf(context);
    final solid = tone == AppCardTone.solid;
    final components = context.options.components;
    final bordered = tone != AppCardTone.soft && components.cardBorders;
    final baseFill =
        color ??
        switch (tone) {
          AppCardTone.solid => cs.surfaceContainerHighest,
          AppCardTone.soft => cs.surfaceContainerHighest.withValues(alpha: 0.5),
          AppCardTone.inset => cs.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
        };
    // The theme can make every card more see-through or more solid.
    final fill = color != null || components.cardOpacity == 1
        ? baseFill
        : baseFill.withValues(
            alpha: (baseFill.a * components.cardOpacity).clamp(0.0, 1.0),
          );

    Widget content = Padding(
      padding: flat
          ? const EdgeInsets.symmetric(horizontal: 2, vertical: 10)
          : padding ??
                (solid
                    ? EdgeInsets.all(16 * context.options.layout.spacing)
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
      child: title == null && trailing == null
          ? child
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (title != null)
                      Expanded(
                        child: Text(
                          title!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    ?trailing,
                  ],
                ),
                SizedBox(height: titleGap),
                child,
              ],
            ),
    );
    if (onTap != null) content = InkWell(onTap: onTap, child: content);

    if (flat) {
      final side = margin?.resolve(Directionality.of(context));
      return Padding(
        padding: EdgeInsets.fromLTRB(side?.left ?? 0, 0, side?.right ?? 0, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.5),
                width: shapes.borderWidth,
              ),
            ),
          ),
          child: SizedBox(width: double.infinity, child: content),
        ),
      );
    }

    Widget card = Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: (solid ? shapes.card : shapes.item).radius,
        side: bordered
            ? BorderSide(
                color: borderColor ?? cs.outlineVariant,
                width: shapes.borderWidth,
              )
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
    if (onTap != null) {
      card = PressableScale(onTap: onTap, hoverScale: 1.015, child: card);
    }
    card = SizedBox(width: double.infinity, child: card);
    return margin == null ? card : Padding(padding: margin!, child: card);
  }
}

/// A card that is one row with a picture or icon, title lines and something at the end.
class AppCardRow extends StatelessWidget {
  const AppCardRow({
    super.key,
    this.icon,
    this.avatar,
    required this.title,
    this.subtitle,
    this.details = const [],
    this.trailing,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(vertical: 4),
    this.dimmed = false,
    this.titleLines = 1,
  });

  /// An icon in a small tile, when there is no [avatar].
  final IconData? icon;

  /// A ready-made leading widget, such as a source's own picture.
  final Widget? avatar;
  final String title;
  final String? subtitle;

  /// More lines under the subtitle.
  final List<Widget> details;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  /// Faded, for something that is switched off.
  final bool dimmed;
  final int titleLines;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final leading =
        avatar ??
        (icon == null
            ? null
            : Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 19, color: cs.onSurfaceVariant),
              ));

    final compact = AmbientScope.compactListsOf(context);
    final row = Row(
      children: [
        if (leading != null) ...[
          Opacity(opacity: dimmed ? 0.4 : 1, child: leading),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: titleLines,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: cs.outline),
                ),
              ],
              for (final line in details) ...[const SizedBox(height: 2), line],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );

    // Dense form: the same row without the box around it.
    if (compact) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppRowStyle.marginOf(context),
            vertical: 6,
          ),
          child: row,
        ),
      );
    }
    return AppCard(
      tone: AppCardTone.inset,
      margin: margin,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      onTap: onTap,
      child: row,
    );
  }
}

/// A row that is a soft card, or, when lists are set to compact, the same
/// content flat with no box around it. For rows made of more than an icon and
/// two lines of text, which cannot use [AppListRow].
class AdaptiveRowCard extends StatelessWidget {
  const AdaptiveRowCard({
    super.key,
    required this.child,
    this.margin,
    this.padding = const EdgeInsets.fromLTRB(12, 8, 4, 8),
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    if (AmbientScope.compactListsOf(context)) {
      final side = AppRowStyle.marginOf(context);
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: side == 0 ? 2 : side,
            vertical: 6,
          ),
          child: child,
        ),
      );
    }
    return AppCard(
      tone: AppCardTone.inset,
      borderColor: borderColor,
      margin: margin,
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}
