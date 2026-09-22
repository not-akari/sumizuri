import 'package:flutter/material.dart';

Widget reorderableCardProxyDecorator(
  Widget child,
  int index,
  Animation<double> animation,
) {
  return Material(
    color: Colors.transparent,
    elevation: 6,
    shadowColor: Colors.black45,
    borderRadius: BorderRadius.circular(14),
    child: child,
  );
}

class ReorderableCardRow extends StatelessWidget {
  const ReorderableCardRow({
    super.key,
    required this.icon,
    required this.title,
    this.trailing = const [],
    this.padding = const EdgeInsets.fromLTRB(12, 10, 8, 10),
    this.dragIndex,
  });

  final IconData icon;
  final Widget title;
  final List<Widget> trailing;
  final EdgeInsetsGeometry padding;

  final int? dragIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: cs.primaryContainer,
              child: Icon(icon, size: 18, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(child: title),
            ...trailing,
            if (dragIndex == null)
              Icon(Icons.drag_handle, color: cs.onSurfaceVariant)
            else
              ReorderableDragStartListener(
                index: dragIndex!,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.drag_handle, color: cs.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
