import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/ambient_scope.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';

/// How a row looks while it is being dragged: lifted, with the same corners
/// as the card it is.
Widget reorderableCardProxyDecorator(
  Widget child,
  int index,
  Animation<double> animation,
) {
  return Builder(
    builder: (context) => Material(
      color: Colors.transparent,
      elevation: 6,
      shadowColor: Colors.black45,
      borderRadius: context.shapes.card.radius,
      child: child,
    ),
  );
}

/// One row of a list that can be reordered, drawn as the soft card the
/// settings rows are: an icon, a name, anything that goes at the end, and a
/// handle to drag it by.
class ReorderableCardRow extends StatelessWidget {
  const ReorderableCardRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing = const [],
    this.dragIndex,
    this.onTap,
    this.dimmed = false,
  });

  final IconData icon;
  final Widget title;
  final String? subtitle;
  final List<Widget> trailing;

  /// Where this row is in its list. Without one the row has no drag handle.
  final int? dragIndex;
  final VoidCallback? onTap;

  /// Faded, for something that is switched off.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tiles = context.options.components.listIconTiles;
    final compact = AmbientScope.compactListsOf(context);
    if (compact) {
      // Dense form: the row without a box, its icon plain.
      return Opacity(
        opacity: dimmed ? 0.55 : 1,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppRowStyle.marginOf(context) == 0
                  ? 2
                  : AppRowStyle.marginOf(context),
              vertical: 2,
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: cs.onSurfaceVariant),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(fontSize: 12, color: cs.outline),
                        ),
                    ],
                  ),
                ),
                ...trailing,
                if (dragIndex != null)
                  ReorderableDragStartListener(
                    index: dragIndex!,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.drag_handle, color: cs.outline),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return AppCard(
      tone: AppCardTone.inset,
      margin: EdgeInsets.symmetric(
        horizontal: AppRowStyle.marginOf(context),
        vertical: 4,
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      onTap: onTap,
      child: Opacity(
        opacity: dimmed ? 0.55 : 1,
        child: Row(
          children: [
            if (tiles)
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
                child: Icon(icon, size: 19, color: cs.onSurfaceVariant),
              )
            else
              Icon(icon, size: 22, color: cs.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: TextStyle(fontSize: 12, color: cs.outline),
                      ),
                    ),
                ],
              ),
            ),
            ...trailing,
            if (dragIndex != null)
              ReorderableDragStartListener(
                index: dragIndex!,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.drag_handle, color: cs.outline),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
