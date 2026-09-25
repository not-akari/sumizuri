import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/ambient/brush_line_painter.dart';

class LibraryHeader extends StatelessWidget {
  const LibraryHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.smartRuleActive,
    required this.onSmartRuleOrSort,
    required this.smartRuleTooltip,
    this.updateProgressLabel,
    this.updateProgressValue,
    this.onCancelUpdate,
    required this.onRefresh,
    required this.refreshTooltip,
    required this.onRandom,
    required this.randomTooltip,
    this.onDisplay,
    this.displayTooltip,
  });

  final String title;
  final String subtitle;
  final bool smartRuleActive;
  final VoidCallback onSmartRuleOrSort;
  final String smartRuleTooltip;

  /// Non-null while a library update is running, shown instead of the refresh button.
  final String? updateProgressLabel;

  /// 0..1 while a library update is running, or null for an indeterminate spinner.
  final double? updateProgressValue;
  final VoidCallback? onCancelUpdate;
  final VoidCallback onRefresh;
  final String refreshTooltip;

  final VoidCallback onRandom;
  final String randomTooltip;

  /// Opens the choice of grid or list.
  final VoidCallback? onDisplay;
  final String? displayTooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final display = Theme.of(context).textTheme.headlineSmall;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.layout.gutter,
        16,
        context.layout.gutter,
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: display?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (updateProgressLabel != null) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: updateProgressValue,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  updateProgressLabel!,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                if (onCancelUpdate != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: onCancelUpdate,
                  )
                else
                  const SizedBox(width: 8),
              ] else ...[
                if (onDisplay != null)
                  IconButton(
                    icon: const Icon(Icons.view_module_outlined),
                    tooltip: displayTooltip,
                    onPressed: onDisplay,
                  ),
                IconButton(
                  icon: const Icon(Icons.shuffle_rounded),
                  tooltip: randomTooltip,
                  onPressed: onRandom,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: refreshTooltip,
                  onPressed: onRefresh,
                ),
              ],
              _HeaderIconBox(
                icon: smartRuleActive ? Icons.tune : Icons.tune_outlined,
                active: smartRuleActive,
                tooltip: smartRuleTooltip,
                onTap: onSmartRuleOrSort,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          CustomPaint(
            size: const Size(double.infinity, 8),
            painter: BrushLinePainter(
              curvy: context.options.effects.brushStrokes,
              color: cs.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconBox extends StatelessWidget {
  const _HeaderIconBox({
    required this.icon,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 38,
          height: 38,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: active ? cs.primaryContainer : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: active ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
