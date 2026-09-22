import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/app_motion.dart';
import 'package:sumizuri/core/widgets/controls/pressable_scale.dart';

const _pillRadius = 5.0;

class TogglePill extends StatelessWidget {
  const TogglePill({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      Semantics(button: true, selected: selected, child: _content(context));

  Widget _content(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.onPrimaryContainer : cs.onSurfaceVariant;
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curveInteractive,
        decoration: ShapeDecoration(
          color: selected ? cs.primaryContainer : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_pillRadius),
            side: BorderSide(
              color: selected ? cs.primary : cs.outline.withValues(alpha: 0.7),
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_pillRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: AppMotion.fast,
                    child: Icon(
                      icon,
                      key: ValueKey(selected),
                      size: 17,
                      color: fg,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration: AppMotion.fast,
                      curve: AppMotion.curveInteractive,
                      style: Theme.of(context).textTheme.labelLarge!
                          .copyWith(color: fg, fontWeight: FontWeight.w600),
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
