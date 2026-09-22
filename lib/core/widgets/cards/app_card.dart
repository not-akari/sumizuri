import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shapes = context.shapes;
    final solid = tone == AppCardTone.solid;
    final bordered = tone != AppCardTone.soft;
    final fill =
        color ??
        switch (tone) {
          AppCardTone.solid => cs.surfaceContainerHighest,
          AppCardTone.soft => cs.surfaceContainerHighest.withValues(alpha: 0.5),
          AppCardTone.inset => cs.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
        };

    Widget content = Padding(
      padding:
          padding ??
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
    this.margin = const EdgeInsets.only(bottom: 10),
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

    return AppCard(
      tone: AppCardTone.soft,
      margin: margin,
      onTap: onTap,
      child: row,
    );
  }
}
