import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/ambient/brush_line_painter.dart';

class OnboardingPageShell extends StatelessWidget {
  const OnboardingPageShell({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.bodyPadding = const EdgeInsets.symmetric(horizontal: 32),
    this.leading,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  final EdgeInsetsGeometry bodyPadding;

  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    leading ??
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: context.shapes.iconTile.radius,
                          ),
                          child: Icon(
                            icon,
                            size: 34,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                    const SizedBox(height: 22),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: context.displayFont,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        color: cs.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 64,
                      height: 8,
                      child: CustomPaint(
                        painter: BrushLinePainter(
                          curvy: context.options.effects.brushStrokes,
                          color: cs.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Padding(padding: bodyPadding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}
