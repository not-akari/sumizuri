import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/controls/pressable_scale.dart';

class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final options = context.options;
    final spacing = options.layout.spacing;
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.layout.gutter,
            vertical: 12 * spacing,
          ),
          child: Row(
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
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
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
          ),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.layout.gutter,
        20 * context.options.layout.spacing,
        context.layout.gutter,
        8,
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
