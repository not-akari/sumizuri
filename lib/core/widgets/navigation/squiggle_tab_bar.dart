import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/ambient/brush_line_painter.dart';

class SquiggleTab extends StatefulWidget {
  const SquiggleTab({
    super.key,
    required this.label,
    required this.active,
    this.compact = false,
    this.showUnderline = true,
    this.onTap,
  });

  final String label;
  final bool active;

  final bool compact;

  final bool showUnderline;
  final VoidCallback? onTap;

  @override
  State<SquiggleTab> createState() => _SquiggleTabState();
}

class _SquiggleTabState extends State<SquiggleTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = widget.label;
    final active = widget.active;
    final compact = widget.compact;
    final showUnderline = widget.showUnderline;
    final baseColor = active
        ? cs.primary
        : (compact ? cs.outline : cs.onSurfaceVariant);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: compact ? 12.5 : 13.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontStyle: active && showUnderline
                ? FontStyle.italic
                : FontStyle.normal,
            color: !active && _hovered ? cs.primary : baseColor,
          ),
        ),
        if (showUnderline) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: 26,
            height: 5,
            child: active
                ? CustomPaint(
                    painter: BrushLinePainter(
                      curvy: context.options.effects.brushStrokes,
                      color: cs.primary,
                    ),
                  )
                : null,
          ),
        ],
      ],
    );
    if (widget.onTap == null) return content;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (mounted) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _hovered = false);
      },
      child: Semantics(
        button: true,
        selected: active,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(6),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? cs.primary.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          child: Padding(
            // Fills the bar's height and pads the sides, so the whole strip is the target.
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}

class SquiggleTabBar extends StatelessWidget {
  const SquiggleTabBar({
    super.key,
    required this.labels,
    required this.activeIndex,
    this.compact = false,
    this.showUnderline = true,
    this.onSelected,
  });

  final List<String> labels;
  final int activeIndex;
  final bool compact;
  final bool showUnderline;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 44 : 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 0),
        itemBuilder: (context, i) => SquiggleTab(
          label: labels[i],
          active: i == activeIndex,
          compact: compact,
          showUnderline: showUnderline,
          onTap: onSelected == null ? null : () => onSelected!(i),
        ),
      ),
    );
  }
}
